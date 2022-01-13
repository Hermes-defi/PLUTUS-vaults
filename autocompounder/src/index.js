"use strict";
process.on('uncaughtException', function (err) {
    red(err.toString());
    process.exit(0);
});
process.setMaxListeners(0);
require('events').EventEmitter.defaultMaxListeners = 0;
require('dotenv').config({path: '../config.txt'});

const fs = require("fs")
const Web3 = require("web3")
const abi_strategy = JSON.parse(fs.readFileSync("./abi-strategy.js", "utf8"));
const abi_vault = JSON.parse(fs.readFileSync("./abi-vault.js", "utf8"));
const abi_compounder = JSON.parse(fs.readFileSync("./abi-compounder.js", "utf8"));
const rpcAddress = "https://harmony-0-rpc.gateway.pokt.network"

const wallet = process.env.WALLET;
const pkey = process.env.PRIVATE_KEY

if( ! wallet ){
    red('WALLET NOT FOUND IN config.txt');
    process.exit(0);
}
if( ! pkey ){
    red('PRIVATE_KEY NOT FOUND IN config.txt');
    process.exit(0);
}

const chalk = require('chalk');
let yellowBright = function () {
    console.log(chalk.yellowBright(...arguments));
}
let magenta = function () {
    console.log(chalk.magenta(...arguments));
}
let cyan = function () {
    console.log(chalk.cyan(...arguments));
}
let yellow = function () {
    console.log(chalk.yellow(...arguments));
}
let red = function () {
    console.log(chalk.red(...arguments));
}
let blue = function () {
    console.log(chalk.blue(...arguments));
}
let green = function () {
    console.log(chalk.green(...arguments));
}

const web3 = new Web3(new Web3.providers.HttpProvider(rpcAddress))
const gasPrice = process.env.GAS_PRICE ? process.env.GAS_PRICE : "4000000000" // 4 gwei

const main = async () => {

    const compounder = new web3.eth.Contract(abi_compounder, process.env.COMPOUNDER);
    const poolLength = parseInt( (await compounder.methods.poolLength().call()).toString() );

    cyan('---------------------------------------------------------------------- ', poolLength);
    try {
        const timeStart = new Date().getTime() / 1000;
        const balance = await web3.eth.getBalance(wallet);
        if (balance < 0.03) {
            red('STOP! BALANCE OF ' + wallet + ' IS INSUFFICIENT: ' + balance);
            return;
        }
        yellowBright('wallet: ' + wallet + ' balance=' + new Number(balance / 1e18).toFixed(3));
        for (let i = 0; i < poolLength; i++) {
            const poolInfo = await compounder.methods.poolInfo(i).call();
            if( ! poolInfo.active ) continue;
            const errors = poolInfo.errors;
            const error = poolInfo.error;
            let ts = '-';
            if( poolInfo.lastTimeHarvest > 0 )
                ts = new Date().setTime( poolInfo.lastTimeHarvest );

            const strategy = poolInfo.strat;
            const contract = new web3.eth.Contract(abi_strategy, strategy);
            const vaultAddress = await contract.methods.vault().call();
            const vault = new web3.eth.Contract(abi_vault, vaultAddress);
            const totalSupply = await vault.methods.totalSupply().call();
            const symbol = await vault.methods.symbol().call();

            cyan(i,') ', vaultAddress, symbol, '>');
            cyan('\t', ts.toString(), 'errors('+errors+')', error);
            if (totalSupply > 0) {
                const supply = new Number(totalSupply / 1e18).toFixed(12);
                yellow('\tsupply='+supply);
                await exec(i, strategy);
            } else {
                yellow('\t', vaultAddress, symbol, '(is empty)');
            }

        }
        const balanceAfter = await web3.eth.getBalance(wallet);
        const cost = balance - balanceAfter;
        const times = balanceAfter / cost;
        const timeEnd = new Date().getTime() / 1000;
        const totalTime = timeEnd - timeStart;
        cyan('----------------------------------------------------------------------');
        yellowBright('- wallet: ' + wallet + ' balance=' + new Number(balanceAfter / 1e18).toFixed((3)));
        yellowBright('- cost of execution=' + cost);
        yellowBright('- you can run this script more ' + times + ' times');
        yellowBright('- execution time ' + parseFloat(totalTime).toFixed('0') + ' seconds.');
    } catch (e) {
        red(e.toString());
    }


}

const exec = async (i, strategy) => {
    try {
        const contract = new web3.eth.Contract(abi_strategy, strategy)
        const transaction = await contract.methods.harvest()
        const signed = await web3.eth.accounts.signTransaction(
            {
                to: strategy,
                data: transaction.encodeABI(),
                gas: process.env.GAS,
                gasPrice: gasPrice,
            },
            pkey
        )
        web3.eth
            .sendSignedTransaction(signed.rawTransaction)
            .on("transactionHash", (payload) => {
                green(`\ttx: ${payload}`)
            })
            .then((receipt) => {
                // magenta(i, ' ', strategy, symbol, supply);
            })
            .catch((e) => {
                red(e);
            })
    } catch (e) {
        red(`\t${e.toString()}`)
    }
}

const EXECUTE_INTERVAL = process.env.EXECUTE_INTERVAL ? parseInt(process.env.EXECUTE_INTERVAL)*1000 : 300000;
yellow('Execute every: '+EXECUTE_INTERVAL+' seconds.');
setInterval(main, EXECUTE_INTERVAL )
main();
