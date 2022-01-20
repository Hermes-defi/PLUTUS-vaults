
var chai = require("chai");
const BN = require('bn.js');
var assert = chai.assert;
var expect = chai.expect;
var chaiAsPromised = require('chai-as-promised');
const { BigNumber, ethers } = require("ethers");
chai.use(chaiAsPromised).should();
chai.use(require('chai-bn')(BN));

const IWETH = artifacts.require("IWETH");
const IPLUTUSMINCHEFVAULT = artifacts.require("../interfaces/IPlutusMinChefVault.sol");
const IUNIPAIR = artifacts.require("../interfaces/IUniPair.sol");

const WNATIVEADDRESS = "0xcF664087a5bB0237a0BAd6742852ec6c8d69A27a";
const VAULTCHEF = "0xdc01ac238a0f841a7750f456bfcf1ede486ce7a1";
const PID = 1;

const LPTOKENADDR = "0xbf255d8c30dbab84ea42110ea7dc870f01c0013a";
const RouterADDRESS = "0x1b02da8cb0d097eb8d57a175b88c7d8b47997506";
// const USDC = "0x985458e523db3d53125813ed68c274899e9dfab4";
// const PATH0 = [WNATIVEADDRESS, USDC];
// const PATH1 = [];

const ZapContract = artifacts.require("Zap");

contract("Zap", ([deployer, alice, bob, feeCollector, devTeam]) => {
  let token;
  let plutus;
  let lpToken;
  beforeEach("deploy contracts", async () => {
    token = await IWETH.at(WNATIVEADDRESS);
    plutus = await IPLUTUSMINCHEFVAULT.at(VAULTCHEF);
    lpToken = await IUNIPAIR.at(LPTOKENADDR);
    this.zap = await ZapContract.new(WNATIVEADDRESS, VAULTCHEF, feeCollector, { from: deployer });
    assert.equal((await this.zap.WNATIVE()).toString(), WNATIVEADDRESS);

  });

  it("WNative should be wrapped one", async () => {
    assert.equal((await this.zap.WNATIVE()).toString(), WNATIVEADDRESS);
    assert.equal(await token.name(), "Wrapped ONE");
  });
  it("Plutus vault chef should be deployed", async () => {
    // assert.equal((await this.zap.WNATIVE()).toString(), WNATIVEADDRESS);
    const name = await plutus.name();
    assert.equal(name, "Plutus Sushi USDC-ONE");
    console.log(name);
  });
  it("alice lp token balance should increase after zapIn swap", async () => {

    // get token contract address
    const tok0 = await lpToken.token0();
    const tok1 = await lpToken.token1();
    // get alice alace before zapIn
    const aliceBalPrev = await lpToken.balanceOf(alice);
    // ZapIn()
    await this.zap.zapIn(LPTOKENADDR, RouterADDRESS, alice, [WNATIVEADDRESS, tok0], [WNATIVEADDRESS, tok1], { from: alice, value: "500000000000000000" });


    // get alice lptoken balance after zapIn()
    const aliceBal = await lpToken.balanceOf(alice);
    // test expectations
    expect(aliceBal).to.be.a.bignumber.that.is.greaterThan(aliceBalPrev.toString())

  });
  it("zap in and stake", async () => {

    // get token contract address
    const tok0 = await lpToken.token0();
    const tok1 = await lpToken.token1();

    // get alice balance before zapIn
    const aliceBalPrev = await plutus.balanceOf(alice);
    const zapBalPrev = await plutus.balanceOf(this.zap.address);

    // ZapInAndStake()
    await this.zap.zapInAndStake(LPTOKENADDR, RouterADDRESS, alice, [WNATIVEADDRESS, tok0], [WNATIVEADDRESS, tok1], 0, { from: alice, value: "500000000000000000" });


    // get alice lptoken balance after zapIn()
    const aliceBal = await plutus.balanceOf(alice);
    const zapBal = await plutus.balanceOf(this.zap.address);
    console.log("alice plutus", aliceBal.toString());
    console.log("zap plutus", zapBal.toString());
    // test expectations
    expect(aliceBal).to.be.a.bignumber.that.is.greaterThan(aliceBalPrev.toString());
    expect(zapBal).to.be.a.bignumber.that.is.equal(zapBalPrev.toString());

  });




});

