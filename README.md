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
