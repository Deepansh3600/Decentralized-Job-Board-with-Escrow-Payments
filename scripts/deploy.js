const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying DecentralizedJobBoard contract with account:", deployer.address);

  const DecentralizedJobBoard = await hre.ethers.getContractFactory("DecentralizedJobBoard");
  const jobBoard = await DecentralizedJobBoard.deploy();

  await jobBoard.deployed();

  console.log("DecentralizedJobBoard deployed to:", jobBoard.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
