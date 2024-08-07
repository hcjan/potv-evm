import { ethers } from "hardhat";

async function main() {
  console.log("Deploying USD contract...");

  const [signer] = await ethers.getSigners();
  console.log("Deploying with signer:", signer.address);
  const Usd = await ethers.deployContract("Usd", [], {
    signer,
  });
   await Usd.waitForDeployment();

   console.log("USD deployed to:", await Usd.getAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
