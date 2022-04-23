const hre = require("hardhat");  

async function main() {
    const TKN_test = await hre.ethers.getContractFactory("TKN_test");

    const stakeToken = "0xaD6D458402F60fD3Bd25163575031ACDce07538D";
    const rewardToken = "0xaD6D458402F60fD3Bd25163575031ACDce07538D";

    const tkn_test = await TKN_test.deploy(stakeToken, rewardToken);
    await tkn_test.deployed();
  
    console.log("TKN_test address:", tkn_test.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });