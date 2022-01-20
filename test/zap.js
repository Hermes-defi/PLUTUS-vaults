var chai = require("chai");
const BN = require('bn.js');
var assert = chai.assert;
var expect = chai.expect;
var chaiAsPromised = require('chai-as-promised');
const { BigNumber, ethers } = require("ethers");
chai.use(chaiAsPromised).should();
chai.use(require('chai-bn')(BN));

const IWETH = artifacts.require("IWETH");
const IERC20 = artifacts.require("IERC20");
const IPLUTUSMINCHEFVAULT = artifacts.require("../interfaces/IPlutusMinChefVault.sol");
const IUNIPAIR = artifacts.require("../interfaces/IUniPair.sol");

const WNATIVEADDRESS = "0xcF664087a5bB0237a0BAd6742852ec6c8d69A27a";
const VAULTCHEF = "0xdc01ac238a0f841a7750f456bfcf1ede486ce7a1";

const LPTOKENADDR = "0xbf255d8c30dbab84ea42110ea7dc870f01c0013a";
const RouterADDRESS = "0x1b02da8cb0d097eb8d57a175b88c7d8b47997506";


const ZapContract = artifacts.require("Zap");

contract("Zap", ([deployer, alice, bob, feeCollector, devTeam]) => {
  let nativeCoin;
  let plutusVaultToken;
  let lpToken;

  beforeEach("deploy contracts", async () => {
    nativeCoin = await IWETH.at(WNATIVEADDRESS);
    plutusVaultToken = await IPLUTUSMINCHEFVAULT.at(VAULTCHEF);
    lpToken = await IUNIPAIR.at(LPTOKENADDR);
    this.zap = await ZapContract.new(WNATIVEADDRESS, VAULTCHEF, feeCollector, { from: deployer });

    // get lpTokenX contract
    lpToken0 = await IERC20.at(await lpToken.token0());
    lpToken1 = await IERC20.at(await lpToken.token1());
    assert.equal((await this.zap.WNATIVE()).toString(), WNATIVEADDRESS);

  });

  describe("check proper deployment", async () => {
    it("WNative should be wrapped one", async () => {
      assert.equal((await this.zap.WNATIVE()).toString(), WNATIVEADDRESS);
      assert.equal(await nativeCoin.name(), "Wrapped ONE");
    });
    it("Plutus vault chef should be deployed", async () => {
      const name = await plutusVaultToken.name();
      assert.equal(name, "Plutus Sushi USDC-ONE");
    });
  });

  describe("ZapIn()", async () => {

    it("alice lp token balance should increase after zapIn swap", async () => {


      const aliceBalPrev = await lpToken.balanceOf(alice);
      // ZapIn()
      await this.zap.zapIn(LPTOKENADDR, RouterADDRESS, alice, [WNATIVEADDRESS, lpToken0.address], [WNATIVEADDRESS, lpToken1.address], { from: alice, value: "500000000000000000" });


      // get alice lpToken balance after zapIn()
      const aliceBal = await lpToken.balanceOf(alice);
      // test expectations
      expect(aliceBal).to.be.a.bignumber.that.is.greaterThan(aliceBalPrev.toString())

    });
  });
  describe("ZapInAndStake()", async () => {
    let aliceBalPrev;
    let zapBalPrev;
    let aliceTok0BalPrev;
    let zapTok0BalPrev;
    let aliceTok1BalPrev;
    let zapTok1BalPrev;

    before("complete transaction", async () => {
      aliceBalPrev = await plutusVaultToken.balanceOf(alice);
      zapBalPrev = await plutusVaultToken.balanceOf(this.zap.address);

      // get lpToken0 balance before zapInAndStake()
      aliceTok0BalPrev = await lpToken0.balanceOf(alice);
      zapTok0BalPrev = await lpToken0.balanceOf(this.zap.address);

      // get lpToken1 balance before zapInAndStake()
      aliceTok1BalPrev = await lpToken1.balanceOf(alice);
      zapTok1BalPrev = await lpToken1.balanceOf(this.zap.address);

      // ZapInAndStake()
      await this.zap.zapInAndStake(LPTOKENADDR, RouterADDRESS, [WNATIVEADDRESS, lpToken0.address], [WNATIVEADDRESS, lpToken1.address], { from: alice, value: "500000000000000000" });

    });


    it("should send Plutus Sushi USDC-ONE to alice", async () => {
      // get plutus balance after zapIn()
      const aliceBal = await plutusVaultToken.balanceOf(alice);
      const zapBal = await plutusVaultToken.balanceOf(this.zap.address);

      // test expectations
      // expect alice balance to have increased, 
      expect(aliceBal).to.be.a.bignumber.that.is.greaterThan(aliceBalPrev.toString());

      // expect zap contract balance to stay the same.
      expect(zapBal).to.be.a.bignumber.that.is.equal(zapBalPrev.toString());
    });

    it("should return all dust token from swap to alice", async () => {

      // get lpToken0 balance after zapInAndStake()
      const aliceTok0Bal = await lpToken0.balanceOf(alice);
      const zapTok0Bal = await lpToken0.balanceOf(this.zap.address);

      // get lpToken1 balance after zapInAndStake()
      const aliceTok1Bal = await lpToken1.balanceOf(alice);
      const zapTok1Bal = await lpToken1.balanceOf(this.zap.address);

      // test expectations
      // expect dust token0 to be returned to alice
      expect(aliceTok0Bal).to.be.a.bignumber.that.is.gte(aliceTok0BalPrev)

      // expect dust token1 to be returned to alice
      expect(aliceTok1Bal).to.be.a.bignumber.that.is.gte(aliceTok1BalPrev)

      // expect zapcontract to have no dust token
      expect(zapTok0Bal).to.be.a.bignumber.that.is.gte(zapTok0BalPrev)
      expect(zapTok1Bal).to.be.a.bignumber.that.is.gte(zapTok1BalPrev)

    });
  });
});

