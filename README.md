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