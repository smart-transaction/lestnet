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
sudo cp blockscout-patch/common-blockscout.env.patch blockscout_clone/blockscout/docker-compose/envs/common-blockscout.env
sudo cp blockscout-patch/docker-compose.yml.patch blockscout_clone/blockscout/docker-compose/docker-compose.yml
sudo cp blockscout-patch/user-ops-indexer.yml.patch blockscout_clone/blockscout/docker-compose/services/user-ops-indexer.yml

# Deploy docker images
echo_stage "Deploy Blockscout Docker Images"
pushd blockscout_clone/blockscout/docker-compose
docker-compose up -d
popd

# TODO: Implement remove cloned blockscout repo after db location is re-configured.
echo "Don't remove the blockscout_clone directory, as it contains the blockscout database and uses it."
