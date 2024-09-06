// scripts/upgrade.js
async function main() {
  const proxyAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

  console.log("Upgrading TimeCapsule...");

  const TimeCapsuleV2 = await ethers.getContractFactory("TimeCapsule");
  const upgraded = await upgrades.upgradeProxy(proxyAddress, TimeCapsuleV2);

  console.log("TimeCapsule upgraded at:", await upgraded.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
