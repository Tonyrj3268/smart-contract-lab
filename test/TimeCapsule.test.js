import { expect } from "chai";
import hre from "hardhat";

const { ethers, upgrades } = hre;
describe("TimeCapsule", function () {
  let TimeCapsule;
  let timeCapsule;
  let owner;
  let addr1;
  let currentTime;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    TimeCapsule = await ethers.getContractFactory("TimeCapsule");
    timeCapsule = await upgrades.deployProxy(TimeCapsule, [], {
      initializer: "initialize",
    });
    await timeCapsule.waitForDeployment();
    currentTime = (await ethers.provider.getBlock("latest")).timestamp;
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await timeCapsule.owner()).to.equal(owner.address);
    });
  });

  describe("Capsule Operations", function () {
    describe("Create Capsule", function () {
      it("Should create a new capsule", async function () {
        const unlockTime = currentTime + 3600;
        const tx = await timeCapsule.createCapsule("testHash", unlockTime);

        const receipt = await tx.wait();
        function findEventArgs(logs, eventName) {
          let _event = null;

          for (const event of logs) {
            if (event.fragment && event.fragment.name === eventName) {
              _event = event.args;
            }
          }
          return _event;
        }

        const event = findEventArgs(receipt.logs, "CapsuleCreated");
        expect(event).to.not.be.null;
        expect(Number(event.id)).to.equal(1);
        expect(event.owner).to.equal(owner.address);
        expect(Number(event.unlockTime)).to.equal(unlockTime);
      });

      it("Should fail if unlock time is in the past", async function () {
        const pastTime = currentTime - 3600;
        await expect(
          timeCapsule.createCapsule("testHash", pastTime)
        ).to.be.revertedWith("Unlock time must be in the future");
      });
    });

    describe("Reveal Capsule", function () {
      beforeEach(async function () {
        const unlockTime = currentTime + 3600;
        await timeCapsule.createCapsule("testHash", unlockTime);
      });

      it("Should not reveal capsule before unlock time", async function () {
        await expect(timeCapsule.revealCapsule(1)).to.be.revertedWith(
          "Capsule is not yet unlocked"
        );
      });

      it("Should not allow non-owner to reveal", async function () {
        await expect(
          timeCapsule.connect(addr1).revealCapsule(1)
        ).to.be.revertedWith("Only the owner can reveal the capsule");
      });

      it("Should reveal capsule after unlock time", async function () {
        await ethers.provider.send("evm_increaseTime", [3600]);
        await ethers.provider.send("evm_mine", []);
        await timeCapsule.revealCapsule(1);
        const content_hash = await timeCapsule.getCapsuleContent(1);
        expect(content_hash).to.equal("testHash");
      });
    });

    describe("Get Capsule Content", function () {
      beforeEach(async function () {
        const unlockTime = currentTime + 3600;
        await timeCapsule.createCapsule("testHash", unlockTime);
      });

      it("Should return content for revealed capsule", async function () {
        await ethers.provider.send("evm_increaseTime", [3600]);
        await ethers.provider.send("evm_mine", []);
        await timeCapsule.revealCapsule(1);
        expect(await timeCapsule.getCapsuleContent(1)).to.equal("testHash");
      });

      it("Should not return content for unrevealed capsule", async function () {
        await expect(timeCapsule.getCapsuleContent(1)).to.be.revertedWith(
          "Capsule has not been revealed yet"
        );
      });
    });
  });
});
