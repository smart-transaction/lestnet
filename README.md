# Lestnet

## Setup the chain

All following commands are to be run from the `lestnetserver` SSH terminal.

1.  ssh to the google cloud VM `lestnetserver`
1.  Make sure the following software is installed:
    -   Git
        ```
        sudo apt-get install git
        ```
    -   Docker
        See docker installlation below
    -   Kurtosis
        https://docs.kurtosis.com/install#ii-install-the-cli
1.  Log into gcloud from the `lestnetserver` SSH terminal, https://cloud.google.com/sdk/gcloud/reference/auth/login
1.  Clone this repository
    ```
    git clone https://github.com/smart-transaction/lestnet.git
    cd lestnet
    ```
1.  Install docker, you need it just once 
    ```
    ./install_docker.sh
    ```
1.  Run the deploy script
    ```
    ./deploy_geth_kurtosis.sh
    ```

## Pre-funded Accounts Data

Pre-funded accounts are stored on the Google Cloud secret manager.

-   `LESTNET_PREFUNDED_ACCOUNTS` - a list of pre-funded accounts and their private keys, formatted as a star script.
-   `LESTNET_PREFUNDED_ACCOUNTS_PASSPHRASE` - the mnemonic phrase used for generating accounts.

Ask smart transactions cloud admin for getting access.

## Configure https and wss proxy

The proxy configuration with certificates is located on the `lestnetserver` machine in the directory `/etc/nginx/conf.d`. It's updated during the lestnet chain running. Kurtosis assigns ports dynamically, so we need proxy update after each kurtosis services restart.

## Connect with Metamask

There is a connection data:

```
Name: Lestnet
Address: https://service.lestnet.org
Chain ID: 21363
Currency: LETH
```

## Deploy Create2Deployer proxy
`Create2Deployer proxy` is required by Foundry. We have to deploy this contract to Lestnet before we can use Foundry for contracts deployment.

First of all, attach to Lestnet
```
geth attach https://explore.lestnet.org
```

All next steps are to be done in the js console
1.  Create an account.
    ```
    > personal.newAccount();
    ```
    Enter and repeat a passphrase (can be empty)
    You'll get an account address. Keep it.
1.  Unlock the account
    ```
    > personal.unlockAccount("<account>");
    ```
    Should return true
1.  Then run following magic commands:
    ```
    > eth.sendTransaction({"from":"created account","to":"0x3fAB184622Dc19b6109349B94811493BF2a45362","value":"10000000000000000"});
    ```
    Expected return: Tx Hash

    ```
    > eth.sendRawTransaction("0xf8a58085174876e800830186a08080b853604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf31ba02222222222222222222222222222222222222222222222222222222222222222a02222222222222222222222222222222222222222222222222222222222222222");
    ```
    Expected return: Tx Hash
    ```
    > eth.call({"from":"created account","to":"0x4e59b44847b379578588920ca78fbf26c0b4956c", "data":"0x00000000000000000000000000000000000000000000000000000000000000006080604052348015600f57600080fd5b5060848061001e6000396000f3fe6080604052348015600f57600080fd5b506004361060285760003560e01c8063c3cafc6f14602d575b600080fd5b6033604f565b604051808260ff1660ff16815260200191505060405180910390f35b6000602a90509056fea165627a7a72305820ab7651cb86b8c1487590004c2444f26ae30077a6b96c6bc62dda37f1328539250029"}, "latest")
    ```
    Expected return: An account number, example: "0x115bcf08a650d194d410f1ca43a17ca41c8d88bc"
    ```
    > eth.sendTransaction({"from":"created account","to":"0x4e59b44847b379578588920ca78fbf26c0b4956c", "gas":"0xf4240", "data":"0x00000000000000000000000000000000000000000000000000000000000000006080604052348015600f57600080fd5b5060848061001e6000396000f3fe6080604052348015600f57600080fd5b506004361060285760003560e01c8063c3cafc6f14602d575b600080fd5b6033604f565b604051808260ff1660ff16815260200191505060405180910390f35b6000602a90509056fea165627a7a72305820ab7651cb86b8c1487590004c2444f26ae30077a6b96c6bc62dda37f1328539250029"});
    ```
    Expected return: Tx Hash
    ```
    > eth.call({"to":"Account returned by previous eth.call", "data":"0xc3cafc6f"}, "latest");
    ```
    Expected return: "0x000000000000000000000000000000000000000000000000000000000000002a"

If all steps are successful, you can consider Create2 proxy deployed successfully.

Alternatively, you can take a look at this example: https://github.com/Zoltu/deterministic-deployment-proxy

## Deploy Create2Deployer

`Create2Deployer` is required by Foundry. We have to deploy this contract to Lestnet before we can use Foundry for contracts deployment.

It's actually needed to deploy it once, after running Lestnet from scratch. No need to deploy it on existing instance of Lestnet.

The simplest way is to use the contract and a Hardhat configuration from its github repository.

1.  Make sure you have node.js installed.
1.  Clone the Create2Deployer repository.
    ```
    git clone https://github.com/pcaversaccio/create2deployer.git
    ```
1.  Retrieve the GS admin private key and export it.
    ```
    export PRIVATE_KEY=$(gcloud secrets versions access 1 --secret="GS_ADMIN_PRIVATE_KEY")
    ```
    If you have issues with secret access ask the STXN Google cloud admin for permissions. 
1.  Modify the `hardhat.config.ts` in the repository root.
    -  Modify the "networks" section, remove all chains and add the Lestnet config:
        ```
        networks: {
            lestnet: {
                chainId: 21363,
                url: "https://service.lestnet.org",
                accounts: [process.env.PRIVATE_KEY],
            },
        },
        ```
    -   Disable sourcify:
        ```
        sourcify: {
            enabled: false,
        },
        ```
    -   Modify the "etherscan" section, remove all the content and add Lestnet blockscout config:
        ```
        etherscan: {
            apiKey: {
                lestnet: "dummy",
            },
            customChains: [
                {
                    network: "lestnet",
                    chainId: 21363,
                    urls: {
                        apiURL: "https://explore.lestnet.org/api",
                        browserURL: "https://explore.lestnet.org",
                    },
                },
            ],
        },
        ```
1.  Run the contract deployment:
    ```
    npx hardhat run scripts/deploy.ts --network lestnet
    ```
    You have to expect an output like this:
    ```
    Create2Deployer deployed to: 0x28dFb617Cbe33A22a4d10160442C6d7035a090db

    Waiting 30 seconds before beginning the contract verification to allow the block explorer to index the contract...

    Successfully submitted source code for contract
    contracts/Create2Deployer.sol:Create2Deployer at 0x28dFb617Cbe33A22a4d10160442C6d7035a090db
    for verification on the block explorer. Waiting for verification result...

    Successfully verified contract Create2Deployer on the block explorer.
    https://explore.lestnet.org/address/0x28dFb617Cbe33A22a4d10160442C6d7035a090db#code
    ```

# Blockscout

There is no need to build Blockscout, it's deployed from original Docker images. We only need to customize some config parameters.

## Deploy Blockscout on Google Cloud Machine

1.  ssh to the google cloud VM `blockscout`
1.  Clone this repository
    ```
    git clone https://github.com/smart-transaction/lestnet.git
    cd lestnet
    ```
1.  Install docker, you need it just once 
    ```
    ./install_docker.sh
    ```
1.  Make sure docker.sock provides "all" read/write access
    ```
    sudo chmod a+rw /var/run/docker.sock
    ```
1.  Run the deploy_blockscout.ch script.
    ```
    ./deploy_blockscout.sh
    ```
