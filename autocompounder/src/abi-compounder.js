[
    {
        "name": "AddPool",
        "type": "event",
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "address",
                "type": "address",
                "name": "strat"
            }
        ]
    },
    {
        "name": "OwnershipTransferred",
        "type": "event",
        "inputs": [
            {
                "internalType": "address",
                "indexed": true,
                "name": "previousOwner",
                "type": "address"
            },
            {
                "internalType": "address",
                "indexed": true,
                "name": "newOwner",
                "type": "address"
            }
        ],
        "anonymous": false
    },
    {
        "type": "function",
        "stateMutability": "view",
        "inputs": [],
        "outputs": [
            {
                "type": "address",
                "internalType": "address",
                "name": ""
            }
        ],
        "name": "owner",
        "constant": true,
        "signature": "0x8da5cb5b"
    },
    {
        "inputs": [
            {
                "name": "",
                "internalType": "uint256",
                "type": "uint256"
            }
        ],
        "name": "poolInfo",
        "outputs": [
            {
                "type": "address",
                "internalType": "address",
                "name": "strat"
            },
            {
                "name": "lastTimeHarvest",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "active",
                "type": "bool",
                "internalType": "bool"
            },
            {
                "name": "last5MinProfit",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "totalProfit",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "error",
                "type": "string",
                "internalType": "string"
            },
            {
                "name": "errors",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "type": "function",
        "stateMutability": "view",
        "constant": true,
        "signature": "0x1526fe27"
    },
    {
        "outputs": [],
        "stateMutability": "nonpayable",
        "name": "renounceOwnership",
        "type": "function",
        "inputs": []
    },
    {
        "type": "function",
        "stateMutability": "nonpayable",
        "inputs": [
            {
                "internalType": "address",
                "type": "address",
                "name": "newOwner"
            }
        ],
        "name": "transferOwnership",
        "outputs": []
    },
    {
        "type": "function",
        "stateMutability": "view",
        "inputs": [],
        "name": "poolLength",
        "outputs": [
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "constant": true,
        "signature": "0x081e3eda"
    },
    {
        "stateMutability": "nonpayable",
        "type": "function",
        "inputs": [
            {
                "internalType": "address",
                "name": "_address",
                "type": "address"
            }
        ],
        "name": "addAddress",
        "outputs": [],
        "signature": "0x38eada1c"
    },
    {
        "inputs": [
            {
                "type": "uint256",
                "name": "_pid",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function",
        "name": "harvestAllx2",
        "outputs": []
    },
    {
        "type": "function",
        "stateMutability": "nonpayable",
        "name": "removeAddress",
        "inputs": [
            {
                "type": "uint256",
                "internalType": "uint256",
                "name": "_pid"
            }
        ],
        "outputs": []
    },
    {
        "outputs": [
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "type": "uint256",
                "name": ""
            },
            {
                "name": "",
                "type": "bool",
                "internalType": "bool"
            },
            {
                "type": "string",
                "name": "",
                "internalType": "string"
            },
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "inputs": [
            {
                "internalType": "uint256",
                "name": "_pid",
                "type": "uint256"
            }
        ],
        "name": "getInformation",
        "stateMutability": "view",
        "type": "function",
        "constant": true,
        "signature": "0xeaa42568"
    }
]
