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

# Apply config patches
echo_stage "Apply Config Patches"
cp blockscout-patch/common-blockscout.env.patch blockscout_clone/blockscout/docker-compose/envs/common-blockscout.env
cp blockscout-patch/docker-compose.yml.patch blockscout_clone/blockscout/docker-compose/docker-compose.yml
cp blockscout-patch/user-ops-indexer.yml.patch blockscout_clone/blockscout/docker-compose/services/user-ops-indexer.yml

# Deploy docker images
echo_stage "Deploy Blockscout Docker Images"
pushd blockscout_clone/blockscout/docker-compose
docker-compose up
popd

# Remove blockscout directory
sudo rm -rf blockscout_clone
