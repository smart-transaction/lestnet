function echo_stage() {
  MSG=$1
  echo ""
  echo "=========="
  echo ${MSG}
  echo "=========="
  echo ""
}

function clone_repo() {
  echo_stage "Clone Blockscout Repository"
  mkdir -p blockscout_clone
  pushd blockscout_clone
  git clone https://github.com/blockscout/blockscout
  popd
}

function refresh_repo() {
  echo_stage "Refresh Blockscout Repository"
  pushd blockscout_clone/blockscout
  git restore .
  git pull
  popd
}

set -e

# Clone blockscout repository
test -d blockscout_clone && refresh_repo
test -d blockscout_clone || clone_repo

# Apply config patches
echo_stage "Apply Config Patches"
pushd blockscout_clone/blockscout
sudo patch -p 1 < ../../blockscout-patch/common-blockscout.env.patch
sudo patch -p 1 < ../../blockscout-patch/common-frontend.env.patch
sudo patch -p 1 < ../../blockscout-patch/docker-compose.yml.patch
sudo patch -p 1 < ../../blockscout-patch/user-ops-indexer.yml.patch
sudo patch -p 1 < ../../blockscout-patch/default.conf.template.patch
sudo patch -p 1 < ../../blockscout-patch/backend.yml.patch
popd

# Deploy docker images
echo_stage "Deploy Blockscout Docker Images"
pushd blockscout_clone/blockscout/docker-compose
sudo docker-compose up -d
popd
