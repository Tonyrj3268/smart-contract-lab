// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract TimeCapsule is Initializable, ContextUpgradeable, AccessControlUpgradeable, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    struct Capsule {
        address owner;
        string contentHash;
        uint256 unlockTime;
        bool isRevealed;
    }

    mapping(uint256 => Capsule) private capsules;
    uint256 private _capsuleIds;

    event CapsuleCreated(uint256 indexed id, address indexed owner, uint256 unlockTime);
    event CapsuleRevealed(uint256 indexed id, address indexed owner);
    event CapsuleDeleted(uint256 indexed id, address indexed owner);
    event CapsuleTransferred(uint256 indexed id, address indexed oldOwner, address indexed newOwner);
    
    function initialize() initializer public {
        __Context_init();
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

    }

    function createCapsule(string memory contentHash, uint256 unlockTime) external whenNotPaused{
        require(unlockTime > block.timestamp, "Unlock time must be in the future");

        _capsuleIds += 1;
        uint256 newCapsuleId = _capsuleIds;

        capsules[newCapsuleId] = Capsule({
            owner: msg.sender,
            contentHash: contentHash,
            unlockTime: unlockTime,
            isRevealed: false
        });

        emit CapsuleCreated(newCapsuleId, msg.sender, unlockTime);
    }

    function revealCapsule(uint256 capsuleId) external whenNotPaused{
        Capsule storage capsule = capsules[capsuleId];
        require(capsule.owner == msg.sender, "Only the owner can reveal the capsule");
        require(block.timestamp >= capsule.unlockTime, "Capsule is not yet unlocked");
        require(!capsule.isRevealed, "Capsule has already been revealed");

        capsule.isRevealed = true;
        emit CapsuleRevealed(capsuleId, msg.sender);
    }

    function getCapsuleContent(uint256 capsuleId) external view returns (string memory) {
        Capsule storage capsule = capsules[capsuleId];
        require(capsule.owner == msg.sender, "Only the owner can view the content");
        require(capsule.isRevealed, "Capsule has not been revealed yet");

        return capsule.contentHash;
    }

    function deleteCapsule(uint256 capsuleId) external whenNotPaused{
        Capsule storage capsule = capsules[capsuleId];
        require(capsule.owner == msg.sender, "Only the owner can delete the capsule");
        require(block.timestamp < capsule.unlockTime, "Cannot delete an unlocked capsule");

        delete capsules[capsuleId];
        emit CapsuleDeleted(capsuleId, msg.sender);
    }

    function transferCapsule(uint256 capsuleId, address newOwner) external whenNotPaused{
        Capsule storage capsule = capsules[capsuleId];
        require(capsule.owner == msg.sender, "Only the owner can transfer the capsule");
        require(newOwner != address(0), "Cannot transfer to the zero address");

        address oldOwner = capsule.owner;
        capsule.owner = newOwner;

        emit CapsuleTransferred(capsuleId, oldOwner, newOwner);
    }
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}