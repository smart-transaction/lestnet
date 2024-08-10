# Lestnet

## Build and Deploy on Google Cloud Machine (recommended)

All following commands are to be run from the `lestnetserver` SSH terminal.

1.  ssh to the google cloud VM `lestnetserver`
1.  Make sure that the necessary software installed, check at https://docs.optimism.io/builders/chain-operators/tutorials/create-l2-rollup#software-dependencies, install missing software
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
1.  Run the build script
    ```
    ./build.sh tutorials/chain
    ```
1.  Run the deploy script
    ```
    ./deploy.sh
    ```

## Build and Deploy on Local Workstation

### Build

[!IMPORTANT] Currently the build is to be done on Linux machines only due to geth build process restrictions. It doesn't support cross platform build.

1.  Install gcloud CLI on your workstation, https://cloud.google.com/sdk/docs/install
1.  Log into gcloud, https://cloud.google.com/sdk/gcloud/reference/auth/login
1.  Install Docker on your workstation, https://docs.docker.com/engine/install/
1.  Make sure that the necessary software installed, check at https://docs.optimism.io/builders/chain-operators/tutorials/create-l2-rollup#software-dependencies
1.  Clone this repository
    ```
    git clone https://github.com/smart-transaction/lestnet.git
    ```
1.  Run the build script
    ```
    ./build.sh tutorials/chain
    ```

### Deploy

All following commands are to be run from the `lestnetserver` SSH terminal.

1.  ssh into the google cloud VM `lestnetserver`
1.  Copy scripts install_docker.sh and deploy.sh on the gcloud vm "lestnetserver", into the home directory (there are different ways to copy files to gcloud VM, not described here)
1.  Run ./install_docker.sh (only first time, no need to rerun at each deployment)
2.  Run ./deploy.sh

## Configure https and wss proxy

The proxy configuration with certificates is located on the `lestnetserver` machine in the directory `/etc/nginx/conf.d`.

## Connect with Metamask

There is a connection data:

```
Name: Lestnet
Address: https://lestnet.org
Chain ID: 42069
```

Chain ID is to be replaced with 21363.

# Blockscout

There is no need to build Blockscout, it's deployed from original Docker images. We only need to customize some config parameters.

## Deploy Blockscout on Google Cloud Machine

1.  ssh to the google cloud VM `lestnetserver`
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

# L1 Deployment
1. Check out contracts deployment documentation, https://docs.optimism.io/builders/chain-operators/deploy/smart-contracts

1.  Check software dependencies, https://docs.optimism.io/builders/chain-operators/deploy/overview#software-dependencies

1.  Set and export env variables
    ```
    # Copied from build.sh
    GS_ADMIN_ADDRESS=0x07FcC5862EB168711fb0A8fD259b4318E5b94B1b
    GS_BATCHER_ADDRESS=0x44864Bdda3C02845787e0E10C8455556Cd0b6ff5
    GS_PROPOSER_ADDRESS=0x8AB2032dF58ba3eC04a173fc1B76e930D8291fA7
    GS_SEQUENCER_ADDRESS=0xc78Af82ECD90d8A08Fef3bec2C920f4719B40742
    L1_BLOCK_TIME=12
    L1_CHAIN_ID=11155111
    L1_RPC_KIND=alchemy
    L1_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/ICXxRS_FHofIsVaTe_LxtU9Uaqfxw8Rc
    L2_BLOCK_TIME=2
    L2_CHAIN_ID=21363
    ```

1.  Generate IMPL_SALT
    ```
    export IMPL_SALT=$(openssl rand -hex 32)
    ```

1.  Make sure the following accounts have enough Sepolia ETH for deployment:
    | Account | Value |
    | ------- | ----- |
    | GS_ADMIN_ADDRESS | 0.5 Sepolia ETH |
    | GS_PROPOSER_ADDRESS | 0.2 Sepolia ETH |
    | GS_BATCHER_ADDRESS | 0.1 Sepolia ETH |

1.  Clone optimism repository
    ```
    git clone https://github.com/ethereum-optimism/optimism.git
    cd optimism
    ```

1.  Generate deployment configuration
    ```
    cd packages/contracts-bedrock
    ./scripts/getting-started/config.sh
    ```
    It will save the configuration into the `deploy-config/getting-started.json`

1.  Checkout the latest verified contracts branch. Not it's `op-contracts/v1.5.0`
    ```
    git checkout op-contracts/v1.5.0
    ```

1.  Run contracts deployment
    ```
    pnpm deploy
    ```