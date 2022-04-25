const { Contract } = require("ethers");
const { ethers, artifacts } = require("hardhat");
const { expect } = require("chai");

const stakeToken = "0xaD6D458402F60fD3Bd25163575031ACDce07538D";
const rewardToken = "0xaD6D458402F60fD3Bd25163575031ACDce07538D";

let owner;
let tkn_test;

describe ("TKN_test deployment", function() {
    beforeEach ( async function () {
        owner = await ethers.getSigners();
        tkn_test = await ethers.getContractFactory("TKN_test");
        tkn_test = await tkn_test.deploy(stakeToken, rewardToken);
    });
    
    it ("has a name", async () => {
        const name = await tkn_test.name();
        console.log("TKN_test name: ", name);
    });
});

describe ("Get Max and Min Stakeable Token", function() {
    it ("max stakeable token", async () => {
        const max = await tkn_test.maxStakeableToken();
        console.log("Max Stakeable Token: ", max);
    });

    it ("min stakeable token", async () => {
        const max = await tkn_test.minStakeableToken();
        console.log("Min Stakeable Token: ", min);
    });
});

describe ("Get Dureation Time", function() {
    it ("duration time", async() => {
        const duration = await tkn_test.duration();
        console.log("Duration Time: ", duration);
    });
});