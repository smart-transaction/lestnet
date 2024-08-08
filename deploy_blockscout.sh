function echo_stage() {
  MSG=$1
  echo ""
  echo "=========="
  echo ${MSG}
  echo "=========="
  echo ""
}

set -e

# Clone blockscout repository
echo_stage "Clone Blockscout Repository"
mkdir -p blockscout_clone
pushd blockscout_clone
git clone https://github.com/blockscout/blockscout
popd

# Copy docker data to a separate directory
echo_stage "Copy docker data to a separate directory"
test -d ../lestnet_data || mkdir -p ../lestnet_data
test -d ../lestnet_data/docker || cp -r blockscout_clone/blockscout/docker ../lestnet_data
test -d ../lestnet_data/docker-compose || cp -r blockscout_clone/blockscout/docker-compose ../lestnet_data

# Apply config patches
echo_stage "Apply Config Patches"
sudo cp blockscout-patch/common-blockscout.env.patch ../lestnet_data/docker-compose/envs/common-blockscout.env
sudo cp blockscout-patch/docker-compose.yml.patch ../lestnet_data/docker-compose/docker-compose.yml
sudo cp blockscout-patch/user-ops-indexer.yml.patch ../lestnet_data/docker-compose/services/user-ops-indexer.yml

# Deploy docker images
echo_stage "Deploy Blockscout Docker Images"
pushd ../lestnet_data/docker-compose
sudo docker-compose up -d
popd

# Remove cloned blockscout repo
echo_stage "Remove cloned blockscout repo"
sudo rm -rf blockscout_clone