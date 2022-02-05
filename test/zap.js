var chai = require("chai");
const BN = require('bn.js');
var assert = chai.assert;
var expect = chai.expect;
var chaiAsPromised = require('chai-as-promised');
const { expectRevert, expectEvent } = require("@openzeppelin/test-helpers");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
chai.use(chaiAsPromised).should();
chai.use(require('chai-bn')(BN));

const IWETH = artifacts.require("IWETH");
const IERC20 = artifacts.require("IERC20");
const IPLUTUSMINCHEFVAULT = artifacts.require("../interfaces/IPlutusMinChefVault.sol");
const IUNIPAIR = artifacts.require("../interfaces/IUniPair.sol");

// constant parameters ---- these parameters are not to be changed when testing new zap/vaults
const WNATIVEADDRESS = "0xcF664087a5bB0237a0BAd6742852ec6c8d69A27a";
const ROUTERADDRESS = "0x1b02da8cb0d097eb8d57a175b88c7d8b47997506"; // sushiswap router address
const PLUTUSADDRESS = "0xd32858211fcefd0be0dd3fd6d069c3e821e0aef3";

// variable param ---- Change these to test new cases.
const VAULTCHEF = "0x5F9B115EC050807F5880bE1f68dB5caA559d8456";// address of vault 
const EXPECTEDVAULTNAME = "Plutus Sushi FRAX-ETH";// vault accounting token name
const LPTOKENADDR = "0xa46BBA980512E328E344Ce12BB969563f3429F05";// lp token wanted by the vault

const FancyToken = artifacts.require("FancyToken");
const ZapContract = artifacts.require("Zap");

function toWei(v) {
  return web3.utils.toWei(v).toString();
}
const AMOUNTIN = toWei('10');
const FANCYAMOUNT = toWei('5');

contract("Zap", ([deployer, alice, bob, manager, devTeam]) => {
  let wrappedNativeCoin;
  let plutusVaultToken;
  let plutusToken;
  let lpToken;
  let lpToken0;
  let lpToken1;
  let liqToken;

  beforeEach("deploy contracts", async () => {
    // fetch deployed contracts
    wrappedNativeCoin = await IWETH.at(WNATIVEADDRESS);
    plutusVaultToken = await IPLUTUSMINCHEFVAULT.at(VAULTCHEF);
    lpToken = await IUNIPAIR.at(LPTOKENADDR);

    // deploy zap
    this.zap = await ZapContract.new(WNATIVEADDRESS, VAULTCHEF, manager, { from: deployer });

    // create fancy ERC20 token
    this.fancyToken = await FancyToken.new({ from: deployer });

    // get lpTokenX contract
    plutusToken = await IERC20.at(PLUTUSADDRESS);
    lpToken0 = await IERC20.at(await lpToken.token0());
    lpToken1 = await IERC20.at(await lpToken.token1());
    liqToken = await IERC20.at(LPTOKENADDR);

    // transfer amount to alice.
    await this.fancyToken.transfer(alice, FANCYAMOUNT, { from: deployer });

  });

  describe("Check for proper deployment", async () => {
    it("WNative should be wrapped one", async () => {
      assert.equal((await this.zap.WNATIVE()).toString(), WNATIVEADDRESS);
      assert.equal(await wrappedNativeCoin.name(), "Wrapped ONE");
    });
    it("Plutus vault chef should be deployed", async () => {
      const name = await plutusVaultToken.name();
      assert.equal(name, EXPECTEDVAULTNAME);
    });
    it("Plutus vault chef should be deployed", async () => {
      const vaultWant = await this.zap.getWantForVault();
      assert.equal(vaultWant.toString().toLowerCase(), LPTOKENADDR.toLowerCase());
    });
    it("alice should have a fancy token balance.", async () => {
      const balance = await this.fancyToken.balanceOf(alice);
      expect(balance).to.be.a.bignumber.that.is.equal(FANCYAMOUNT);
    });
  });

  describe("Ownership", async () => {
    it("Manager should be onwer", async () => {
      const currentOwner = await this.zap.owner();
      assert.equal(currentOwner, manager)
    });
    it("Should not transfer ownership", async () => {
      await expectRevert(this.zap.transferOwnership(devTeam, { from: deployer }), "Ownable: caller is not the owner");
    });
    it("Should transfer ownership", async () => {
      await this.zap.transferOwnership(devTeam, { from: manager });
      const newOnwer = await this.zap.owner();
      assert.equal(newOnwer, devTeam);
    });

  });

  describe("ZapIn()", async () => {

    it("alice lp token balance should increase after zapIn swap", async () => {
      const aliceBalPrev = await lpToken.balanceOf(alice);

      // ZapIn()
      await this.zap.zapIn(LPTOKENADDR, ROUTERADDRESS, alice, [WNATIVEADDRESS, lpToken0.address], [WNATIVEADDRESS, lpToken1.address], { from: alice, value: "500000000000000000" });

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
      await this.zap.zapInAndStake(LPTOKENADDR, ROUTERADDRESS, [WNATIVEADDRESS, lpToken0.address], [WNATIVEADDRESS, lpToken1.address], { from: alice, value: "500000000000000000" });

    });

    it("should send Plutus Sushi USDC-ONE to alice", async () => {
      // get plutus balance after zapIn()
      const aliceBal = await plutusVaultToken.balanceOf(alice);
      const zapBal = await plutusVaultToken.balanceOf(this.zap.address);

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

  describe("ZapInToken()", async () => {

    before("Complete transaction", async () => {
      // alice get WONE
      await wrappedNativeCoin.deposit({ from: alice, value: AMOUNTIN });

      // get lpToken0 balance before ZapInTokenAndStake()
      aliceWONEBalPrev = await wrappedNativeCoin.balanceOf(alice);
      aliceLPBalPrev = await lpToken.balanceOf(alice);
    });

    it("alice should have a greater lp token balance.", async () => {
      // approve zap to use WONE from alice
      await wrappedNativeCoin.approve(this.zap.address, AMOUNTIN, { from: alice });

      // zapInToken()
      await this.zap.zapInToken(wrappedNativeCoin.address, AMOUNTIN, LPTOKENADDR, ROUTERADDRESS, alice, [WNATIVEADDRESS, lpToken0.address], [WNATIVEADDRESS, lpToken1.address], { from: alice });

      // expect alice to have increased lpToken balance.
      const aliceLPBal = await lpToken.balanceOf(alice);
      expect(aliceLPBal).to.be.a.bignumber.that.is.gt(aliceLPBalPrev);
    });
  });

  describe("ZapInTokenAndStake()", async () => {

    before("Complete transaction", async () => {
      await wrappedNativeCoin.deposit({ from: alice, value: AMOUNTIN });

      aliceWONEBalPrev = await wrappedNativeCoin.balanceOf(alice);
      alicePlutusVaultBalPrev = await plutusVaultToken.balanceOf(alice);
      zapPlutusVaultBalPrev = await plutusVaultToken.balanceOf(this.zap.address);

    });

    it("TX should revert because no permission was given to contract", async () => {
      //expect to revert because no approval was given to zap contract.
      await expectRevert(
        this.zap.zapInTokenAndStake(this.fancyToken.address, FANCYAMOUNT, LPTOKENADDR, ROUTERADDRESS, [this.fancyToken.address, lpToken0.address], [this.fancyToken.address, lpToken1.address], { from: alice }),
        'ERC20: transfer amount exceeds allowance',
      );
    });

    it("TX should revert due to no liquidity", async () => {
      await this.fancyToken.approve(this.zap.address, FANCYAMOUNT, { from: alice });
      // expect Tx to revert because lp has no liquidity
      await expectRevert(
        this.zap.zapInTokenAndStake(this.fancyToken.address, FANCYAMOUNT, LPTOKENADDR, ROUTERADDRESS, [this.fancyToken.address, lpToken0.address], [this.fancyToken.address, lpToken1.address], { from: alice }),
        'revert',
      );
    });

    it("Alice should have plutus vault token balance.", async () => {
      // approve zap spending of WONE.
      await wrappedNativeCoin.approve(this.zap.address, AMOUNTIN, { from: alice });

      // zapInTokenAndStake()
      await this.zap.zapInTokenAndStake(WNATIVEADDRESS, AMOUNTIN, LPTOKENADDR, ROUTERADDRESS, [WNATIVEADDRESS, lpToken0.address], [WNATIVEADDRESS, lpToken1.address], { from: alice });

      // get balances after zap & stake
      alicePlutusVaultBal = await plutusVaultToken.balanceOf(alice);
      zapPlutusVaultBal = await plutusVaultToken.balanceOf(this.zap.address);

      // expect zap balance to 0
      expect(zapPlutusVaultBal).to.be.a.bignumber.that.is.equal('0');

      // expect alice balance to be greater than before
      expect(alicePlutusVaultBal).to.be.a.bignumber.that.is.gt(alicePlutusVaultBalPrev)

    });

  });

  describe("ZapOut()", async () => {

    let alice1afterZapIn;
    let aliceLPBalancePrev;

    before("Complete transaction", async () => {
      // use zap in to get lp token.
      await this.zap.zapIn(LPTOKENADDR, ROUTERADDRESS, alice, [WNATIVEADDRESS, lpToken0.address], [WNATIVEADDRESS, lpToken1.address], { from: alice, value: AMOUNTIN });

      // get ETH balance
      alice1afterZapIn = await web3.eth.getBalance(alice);

      // get LP token balance
      aliceLPBalancePrev = await lpToken.balanceOf(alice);
      zapLPBalancePrev = await lpToken.balanceOf(this.zap.address);

    });

    it("Should zap out back to ONE", async () => {
      // Approve zap to use lpToken
      await liqToken.approve(this.zap.address, aliceLPBalancePrev.toString(), { from: alice });

      // get given to zap contract.
      allowed = await liqToken.allowance(alice, this.zap.address);

      // execute zapout function
      await this.zap.zapOut(LPTOKENADDR, aliceLPBalancePrev.toString(), ROUTERADDRESS, alice, [lpToken0.address, WNATIVEADDRESS], [lpToken1.address, WNATIVEADDRESS], { from: alice });

      // expect eth balance to increase after zapout
      const afterBalance = await web3.eth.getBalance(alice);
      expect(afterBalance).to.be.a.bignumber.that.is.gt(alice1afterZapIn);

    });
    it("all zap balances should be zero.", async () => {
      const zapLpBalance = await liqToken.balanceOf(this.zap.address);
      expect(zapLpBalance).to.be.a.bignumber.that.is.equal('0');
      const zaplpToken0Balance = await lpToken0.balanceOf(this.zap.address);
      expect(zaplpToken0Balance).to.be.a.bignumber.that.is.equal('0');
      const zaplpToken1Balance = await lpToken1.balanceOf(this.zap.address);
      expect(zaplpToken1Balance).to.be.a.bignumber.that.is.equal('0');
      const zapONEBalance = await web3.eth.getBalance(this.zap.address);
      expect(zapONEBalance).to.be.a.bignumber.that.is.equal('0');
    });

  });

  describe("ZapOutToken()", async () => {

    let aliceWONEafterZapIn;
    let aliceLPBalancePrev;
    let zapLPBalancePrev;
    let nativeBalancePrev;

    beforeEach("Complete transaction", async () => {
      // use zap in to get lp token.
      await this.zap.zapIn(LPTOKENADDR, ROUTERADDRESS, alice, [WNATIVEADDRESS, lpToken0.address], [WNATIVEADDRESS, lpToken1.address], { from: alice, value: AMOUNTIN });

      //get alice ONE balance after zapIn()
      nativeBalancePrev = await web3.eth.getBalance(alice)

      // get alice WONE balance
      aliceWONEafterZapIn = await wrappedNativeCoin.balanceOf(alice);

      // get other token balance after zapIn()
      aliceLPBalancePrev = await lpToken.balanceOf(alice);
      zapLPBalancePrev = await lpToken.balanceOf(this.zap.address);
      aliceUsdcBalancePrev = await lpToken0.balanceOf(alice);

    });

    it("Should zap out LPtoken back ONE", async () => {

      // Approve zap to use lpToken
      await liqToken.approve(this.zap.address, aliceLPBalancePrev.toString(), { from: alice });

      // execute zapout function
      await this.zap.zapOutToken(LPTOKENADDR, aliceLPBalancePrev.toString(), WNATIVEADDRESS, ROUTERADDRESS, [lpToken0.address, WNATIVEADDRESS], [lpToken1.address, WNATIVEADDRESS], { from: alice });

      // get alice balance after zapout token to WONE.
      const nativeBalance = await web3.eth.getBalance(alice);
      const WONEBalance = await wrappedNativeCoin.balanceOf(alice);

      //expect WONE balance to be the same
      expect(WONEBalance).to.be.a.bignumber.that.is.equal(aliceWONEafterZapIn);

      // expect ONE balance to increase after zapout
      expect(nativeBalance).to.be.a.bignumber.that.is.gt(nativeBalancePrev);

    });

    it("Should zap out LPtoken to get back lpToken0", async () => {

      // Approve zap to use lpToken
      await liqToken.approve(this.zap.address, aliceLPBalancePrev.toString(), { from: alice });

      // execute zapOutToken function to USDC
      await this.zap.zapOutToken(LPTOKENADDR, aliceLPBalancePrev.toString(), lpToken0.address, ROUTERADDRESS, [lpToken0.address, lpToken0.address], [lpToken1.address, lpToken0.address], { from: alice });

      // get alice usdc balance after zapOutToken to USDC.
      const lpToken0Balance = await lpToken0.balanceOf(alice);

      // expect USDC balance to increase after zapout
      expect(lpToken0Balance).to.be.a.bignumber.that.is.gt(aliceUsdcBalancePrev);

    });

  });



});

