import { ethers } from "hardhat";
import * as fs from 'fs';

async function deployContract(name: string, factory: any, ...args: any[]) {
  console.log(`Deploying ${name}...`);
  const contract = await factory.deploy(...args);
  await contract.waitForDeployment();
  const address = await contract.getAddress();
  console.log(`${name} deployed to:`, address);
  return { name, address, contract };
}

async function main() {
  console.log("Deploying contracts...");

  const deployedContracts: { [key: string]: string } = {};

  // Deploy Config
  const Config = await ethers.getContractFactory("Config");
  const mcr = ethers.parseUnits("1.5", 6); // 150% MCR
  const liquidationRate = ethers.parseUnits("1.1", 6); // 110% liquidation rate
  const { address: configAddress } = await deployContract("Config", Config, mcr, liquidationRate);
  deployedContracts["Config"] = configAddress;

  // Deploy PriceFeed
  const PriceFeed = await ethers.getContractFactory("PriceFeed");
  const { address: priceFeedAddress } = await deployContract("PriceFeed", PriceFeed);
  deployedContracts["PriceFeed"] = priceFeedAddress;

  // Deploy Chain
  const Chain = await ethers.getContractFactory("Chain");
  const { address: chainAddress, contract: chain } = await deployContract("Chain", Chain, configAddress);
  deployedContracts["Chain"] = chainAddress;

  // Deploy Pool
  const Pool = await ethers.getContractFactory("Pool");
  const { address: poolAddress, contract: pool } = await deployContract("Pool", Pool, configAddress);
  deployedContracts["Pool"] = poolAddress;

  // Deploy USD
  const Usd = await ethers.getContractFactory("Usd");
  const { address: usdAddress } = await deployContract("USD", Usd, poolAddress);
  deployedContracts["USD"] = usdAddress;

  await pool.setUsdAddress(usdAddress);

  // Deploy Reward
  const Reward = await ethers.getContractFactory("Reward");
  const { address: rewardAddress, contract: reward } = await deployContract("Reward", Reward, configAddress, ethers.ZeroAddress, chainAddress);
  deployedContracts["Reward"] = rewardAddress;

  // Deploy Lend
  const Lend = await ethers.getContractFactory("Lend");
  const { address: lendAddress } = await deployContract("Lend", Lend, chainAddress, poolAddress, configAddress, rewardAddress, priceFeedAddress, usdAddress);
  deployedContracts["Lend"] = lendAddress;

  // Set Lend contract address in other contracts
  await pool.setLendContract(lendAddress);
  await chain.setLendContract(lendAddress);
  await reward.setLendAddress(lendAddress);

  console.log("All contracts deployed and configured successfully!");

  // Write addresses to JSON file
  fs.writeFileSync('deployed-addresses.json', JSON.stringify(deployedContracts, null, 2));
  console.log("Contract addresses written to deployed-addresses.json");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
