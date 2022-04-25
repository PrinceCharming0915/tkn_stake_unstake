const { Contract } = require("ethers");
const { ethers, artifacts } = require("hardhat");

require('chai')
    .use(require('chai-as-promised'))
    .should()

const stakeToken = "0xaD6D458402F60fD3Bd25163575031ACDce07538D";
const rewardToken = "0xaD6D458402F60fD3Bd25163575031ACDce07538D";

const TKN_test = artifacts.require("TKN_test");

// describe ("TKN_test contract", function() {
//     beforeEach ( async function () {
//         owner = await ethers.getSigners();
//         tkn_test = await ethers.getContractFactory("TKN_test");
//         tkn_test = await tkn_test.deploy(stakeToken, rewardToken);
//     });

//     it ("get block timestamp", async function() {
//         const timestamp = await tkn_test.getTimeStamp();
//         console.log("Block Timestamp: ", timestamp);
//     });
// });

Contract("TKN_test", () => {
    let tkn_test;
    before(async () => {
        tkn_test = await TKN_test.new(stakeToken, rewardToken);
    })

    describe("TKN_test Deployment", async () => {
        it('matches names successfully', async () => {
            const name = await tkn_test.name();
            assert.equal(name, "TKN_test");
        })
    })
})