function echo_stage() {
  MSG=$1
  echo ""
  echo "=========="
  echo ${MSG}
  echo "=========="
  echo ""
}

set -e

# Cleanup previous installation
echo_stage "Stop existing docker containers"
RUNNING_CONTAINERS=$(docker ps -q)
if [[ "" != ${RUNNING_CONTAINERS} ]]; then
  docker kill ${RUNNING_CONTAINERS}
fi

# Remove blockscout directory
echo_stage "Deleting existing blockscout copy"
test -d blockscout_clone && sudo rm -rf blockscout_clone

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
sudo docker-compose up -d
popd
