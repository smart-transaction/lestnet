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

## Deploy Create2Deployer

`Create2Deployer` is required by Foundry. We have to deploy this contract to Lestnet before we can use Foundry for contracts deployment.

It's actually needed to deploy it once, after running Lestnet from scratch. No need to deploy it on existing instance of Lestnet.

The simplest way is to use the contract and a Hardhat configuration from its github repository.

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
