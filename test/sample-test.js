const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Factory", function () {
  it("Should return the NFT contract address", async function () {
    const Factory = await ethers.getContractFactory("Factory");
    const factory = await Factory.deploy("0xdD2FD4581271e230360230F9337D5c0430Bf44C0", "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199");
    await factory.deployed();

    const onboardBrandTx = await factory.onboardBrand("1", "Nike", "0xbDA5747bFD65F08deb54cb465eB87D40e51B197E", "0xbDA5747bFD65F08deb54cb465eB87D40e51B197E");

    // wait until the transaction is mined
    await onboardBrandTx.wait();
  });
});
