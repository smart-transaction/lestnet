# Lestnet

## Build and Deploy

To build Docker images:
1.  Install Docker on your workstation, https://docs.docker.com/engine/install/
2.  Run the script ./build_images.sh

To deploy:
1.  Install gcloud CLI on your workstation, https://cloud.google.com/sdk/docs/install
1.  Log into gcloud, https://cloud.google.com/sdk/gcloud/reference/auth/login
1.  Copy scripts install_docker.sh and deploy.sh on the gcloud vm "lestnetserver", into the home directory (there are different ways, not described here)
1.  ssh into the gcloud vm "lestnetserver"
1.  Run ./install_docker.sh (only first time, no need to rerun at each deployment)
2.  Run ./deploy.sh