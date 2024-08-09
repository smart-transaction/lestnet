function echo_stage() {
  echo ""
  echo "=================="
  echo "$1"
  echo "=================="
  echo ""
}

function build_docker() {
  CLOUD_REGION=$1
  PROJECT_NAME=$2
  IMAGE_NAME=$3
  BUILD_VERSION=$4

  DOCKER_IMAGE="lestnet-docker-repo/$IMAGE_NAME"
  DOCKER_TAG="${CLOUD_REGION}-docker.pkg.dev/${PROJECT_NAME}/${DOCKER_IMAGE}"

  echo ${DOCKER_TAG}

  gcloud builds submit \
    --region=${CLOUD_REGION} \
    --tag ${DOCKER_TAG}:${BUILD_VERSION}
}

# Params check
if [[ "" == "$1" ]]; then
  echo "Usage: $0 <optimism_verified_branch>"
  echo "Use the tutorial branch tutorials/chain or the latest branch like op-contracts/vX.X.X"
  exit 1
fi

# Optimism branch
OPTIMISM_BRANCH=$1

# L1 RPC URL
export L1_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/ICXxRS_FHofIsVaTe_LxtU9Uaqfxw8Rc"
export L1_RPC_KIND="alchemy"

# Addresses
export GS_ADMIN_ADDRESS=0x07FcC5862EB168711fb0A8fD259b4318E5b94B1b
export GS_BATCHER_ADDRESS=0x44864Bdda3C02845787e0E10C8455556Cd0b6ff5
export GS_PROPOSER_ADDRESS=0x8AB2032dF58ba3eC04a173fc1B76e930D8291fA7
export GS_SEQUENCER_ADDRESS=0xc78Af82ECD90d8A08Fef3bec2C920f4719B40742

# L1 chain information
export L1_CHAIN_ID=11155111
export L1_BLOCK_TIME=12

# L2 chain information
export L2_CHAIN_ID=42069
export L2_BLOCK_TIME=2

# Geth release URL
GETH_RELEASE="https://github.com/ethereum/go-ethereum/archive/refs/tags/v1.14.6.tar.gz"
GETH_EXTRACT_DIR="go-ethereum-1.14.6"

# Clone optimism repository
echo_stage "Clone Optimism repository"
mkdir -p optimism_clones
pushd optimism_clones

git clone https://github.com/ethereum-optimism/optimism.git
pushd optimism
git checkout ${OPTIMISM_BRANCH}
popd
popd

# Extract geth release
echo_stage "Extract Geth release"
pushd optimism_clones
wget -O geth_release.tar.gz ${GETH_RELEASE}
tar xvf geth_release.tar.gz
popd

set -e

# Build optimism binaries
echo_stage "Build optimism binaries"
pushd optimism_clones/optimism
pnpm install
make op-node op-batcher op-proposer
pnpm build
popd

# Build op-geth binary
echo_stage "Build op-geth binary"
pushd optimism_clones/${GETH_EXTRACT_DIR}
make geth
popd

# Apply patches
echo_stage "Apply patches"
DEPLOYMENTS_DIR="optimism_clones/optimism/packages/contracts-bedrock/deployments/getting-started"
SCRIPTS_DIR="optimism_clones/optimism/packages/contracts-bedrock/scripts/getting-started"
rm -rf ${DEPLOYMENTS_DIR}
cp -a getting-started-patch/deployments ${DEPLOYMENTS_DIR}
cp getting-started-patch/getting-started-config.sh ${SCRIPTS_DIR}/config.sh

# Generate config file
echo_stage "Generate config file"
pushd optimism_clones/optimism/packages/contracts-bedrock
./scripts/getting-started/config.sh
popd

# Generate genesis files
pushd optimism_clones/optimism/op-node
echo_stage "Generate genesis file"
go run cmd/main.go genesis l2 \
  --deploy-config ../packages/contracts-bedrock/deploy-config/getting-started.json \
  --l1-deployments ../packages/contracts-bedrock/deployments/getting-started/.deploy \
  --outfile.l2 genesis.json \
  --outfile.rollup rollup.json \
  --l1-rpc ${L1_RPC_URL}
openssl rand -hex 32 > jwt.txt
cp genesis.json ../../${GETH_EXTRACT_DIR}
cp jwt.txt ../../${GETH_EXTRACT_DIR}
popd

# Initialize op-geth
echo_stage "Initialize op-geth"
pushd optimism_clones/${GETH_EXTRACT_DIR}
mkdir -p datadir
build/bin/geth init --datadir=datadir genesis.json
popd

# Build Docker images
CLOUD_REGION="us-central1"
PROJECT_NAME="delta-exchange-427816-f1"  # Lestnet project
LESTNET_VERSION="0.1"

echo_stage "Build op-geth docker image"
pushd docker/${GETH_EXTRACT_DIR}
cp ../../optimism_clones/${GETH_EXTRACT_DIR}/build/bin/geth .
cp -r ../../optimism_clones/${GETH_EXTRACT_DIR}/datadir ./datadir
cp ../../optimism_clones/${GETH_EXTRACT_DIR}/jwt.txt .
build_docker ${CLOUD_REGION} ${PROJECT_NAME} "op-geth" ${LESTNET_VERSION}
rm -rf ./geth ./datadir ./jwt.txt
popd

echo_stage "Build op-node docker image"
pushd docker/op-node
cp ../../optimism_clones/optimism/op-node/bin/op-node .
cp ../../optimism_clones/optimism/op-node/jwt.txt .
cp ../../optimism_clones/optimism/op-node/rollup.json .
cp -r ../../certificates ./
build_docker ${CLOUD_REGION} ${PROJECT_NAME} "op-node" ${LESTNET_VERSION}
rm -rf ./op-node ./jwt.txt ./rollup.json ./certificates
popd

echo_stage "Build op-batcher docker image"
pushd docker/op-batcher
cp ../../optimism_clones/optimism/op-batcher/bin/op-batcher .
cp -r ../../certificates ./
build_docker ${CLOUD_REGION} ${PROJECT_NAME} "op-batcher" ${LESTNET_VERSION}
rm -rf ./op-batcher ./certificates
popd

echo_stage "Build op-proposer docker image"
pushd docker/op-proposer
cp ../../optimism_clones/optimism/op-proposer/bin/op-proposer .
cp -r ../../certificates ./
build_docker ${CLOUD_REGION} ${PROJECT_NAME} "op-proposer" ${LESTNET_VERSION}
rm -rf ./op-proposer ./certificates
popd

# Echoing contract addresses
echo "******************************************"
echo "*      Docker images build is done!      *"
echo "******************************************"
echo "* Check out the contract addresses below *"
echo "******************************************"
echo ""
echo "Address of the L1StandardBridgeProxy contract: $(cat optimism_clones/optimism/packages/contracts-bedrock/deployments/getting-started/L1StandardBridgeProxy.json | jq -r .address)"
echo "Use it for sending ETH to Lestnet"
echo ""
echo "Address of the L2OutputOracleProxy: $(cat optimism_clones/optimism/packages/contracts-bedrock/deployments/getting-started/L2OutputOracleProxy.json | jq -r .address)"
echo "Put this address into the deploy.sh script, assign it to the variable L2_OUTPUT_ORACLE_ADDRESS"

# Remove optimism repos copies
rm -rf optimism_clones
