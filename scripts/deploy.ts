import { ethers } from "hardhat";

async function main() {
  console.log("Deploying contracts...");

  // Deploy Config
  const Config = await ethers.getContractFactory("Config");
  const mcr = ethers.parseUnits("1.5", 6); // 150% MCR
  const liquidationRate = ethers.parseUnits("1.1", 6); // 110% liquidation rate
  const config = await Config.deploy(mcr, liquidationRate);
  await config.waitForDeployment();
  console.log("Config deployed to:", await config.getAddress());

  // Deploy PriceFeed
  const PriceFeed = await ethers.getContractFactory("PriceFeed");
  const priceFeed = await PriceFeed.deploy();
  await priceFeed.waitForDeployment();
  console.log("PriceFeed deployed to:", await priceFeed.getAddress());

  // Deploy Chain
  const Chain = await ethers.getContractFactory("Chain");
  const chain = await Chain.deploy(await config.getAddress());
  await chain.waitForDeployment();
  console.log("Chain deployed to:", await chain.getAddress());

  // Deploy Pool
  const Pool = await ethers.getContractFactory("Pool");
  const pool = await Pool.deploy(await config.getAddress(), ethers.ZeroAddress); // Temporarily use ZeroAddress for USD
  await pool.waitForDeployment();
  console.log("Pool deployed to:", await pool.getAddress());

  // Deploy USD
  const Usd = await ethers.getContractFactory("Usd");
  const usd = await Usd.deploy(await pool.getAddress());
  await usd.waitForDeployment();
  console.log("USD deployed to:", await usd.getAddress());

  // Update Pool with correct USD address
  await pool.setLendContract(ethers.ZeroAddress); // Temporarily set to ZeroAddress
  
  // Deploy Reward
  const Reward = await ethers.getContractFactory("Reward");
  const reward = await Reward.deploy(
    await config.getAddress(),
    ethers.ZeroAddress, // Replace with actual reward token address
    await chain.getAddress()
  );
  await reward.waitForDeployment();
  console.log("Reward deployed to:", await reward.getAddress());

  // Deploy Lend
  const Lend = await ethers.getContractFactory("Lend");
  const lend = await Lend.deploy(
    await chain.getAddress(),
    await pool.getAddress(),
    await config.getAddress(),
    await reward.getAddress(),
    await priceFeed.getAddress(),
    await usd.getAddress()
  );
  await lend.waitForDeployment();
  console.log("Lend deployed to:", await lend.getAddress());

  // Set Lend contract address in other contracts
  await pool.setLendContract(await lend.getAddress());
  await chain.setLendContract(await lend.getAddress());
  await reward.setLendAddress(await lend.getAddress());

  console.log("All contracts deployed and configured successfully!");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
