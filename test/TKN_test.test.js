const { expect } = require("chai");
const { ethers } = require("hardhat");

let tkn_test;
let owner;

const stakeToken = "0xaD6D458402F60fD3Bd25163575031ACDce07538D";
const rewardToken = "0xaD6D458402F60fD3Bd25163575031ACDce07538D";

describe ("TKN_test contract", function() {
    beforeEach ( async function () {
        owner = await ethers.getSigners();
        tkn_test = await ethers.getContractFactory("TKN_test");
        tkn_test = await tkn_test.deploy(stakeToken, rewardToken);
    });

    it ("get block timestamp", async function() {
        const timestamp = await tkn_test.getTimeStamp();
        console.log("Block Timestamp: ", timestamp);
    });
});