// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TimeCapsule is Initializable, UUPSUpgradeable, OwnableUpgradeable {

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

    function initialize() initializer public {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }
    function createCapsule(string memory contentHash, uint256 unlockTime) external {
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

    function revealCapsule(uint256 capsuleId) external {
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

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}