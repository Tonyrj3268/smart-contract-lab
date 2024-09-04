// scripts/deploy.js
async function main() {
  // We get the contract to deploy
  const TimeCapsule = await ethers.getContractFactory("TimeCapsule");
  const timeCapsule = await upgrades.deployProxy(TimeCapsule, [], {
    initializer: "initialize",
  });
  await timeCapsule.waitForDeployment();
  console.log("TimeCapsule deployed to:", await timeCapsule.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
