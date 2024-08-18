function echo_stage() {
  MSG=$1
  echo ""
  echo "=========="
  echo ${MSG}
  echo "=========="
  echo ""
}

set -e

# Cleanup previous blockscout instance
echo_stage "Cleanup previous instance"
sudo docker ps -q | xargs sudo docker stop
test -d blockscout_clone && sudo rm -rf blockscout_clone

# Clone blockscout repository
echo_stage "Clone Blockscout Repository"
mkdir -p blockscout_clone
pushd blockscout_clone
git clone https://github.com/blockscout/blockscout
popd

# Apply config patches
echo_stage "Apply Config Patches"
pushd blockscout_clone/blockscout
sudo patch -p 1 < ../../blockscout-patch/common-blockscout.env.patch
sudo patch -p 1 < ../../blockscout-patch/common-frontend.env.patch
sudo patch -p 1 < ../../blockscout-patch/docker-compose.yml.patch
sudo patch -p 1 < ../../blockscout-patch/user-ops-indexer.yml.patch
sudo patch -p 1 < ../../blockscout-patch/default.conf.template.patch
popd

# Deploy docker images
echo_stage "Deploy Blockscout Docker Images"
pushd blockscout_clone/blockscout/docker-compose
sudo docker-compose up -d
popd

# TODO: Implement remove cloned blockscout repo after db location is re-configured.
echo "Don't remove the blockscout_clone directory, as it contains the blockscout database and uses it."
