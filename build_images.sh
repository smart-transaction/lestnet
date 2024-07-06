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
  echo "Usage: ./build_image.sh <optimism_verified_branch>"
  echo "Use the latest branch like op-contracts/vX.X.X"
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

# Go build environment, building for Linux
export TARGETOS="linux"
export TARGETARCH="amd64"

# Clone repositories
echo_stage "Clone repositories"
mkdir -p optimism_clones
pushd optimism_clones

git clone https://github.com/ethereum-optimism/optimism.git
pushd optimism
git checkout ${OPTIMISM_BRANCH}
popd

git clone https://github.com/ethereum-optimism/op-geth.git 

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
pushd optimism_clones/op-geth
make geth
popd

# Generate config file
echo_stage "Generate config file"
pushd optimism_clones/optimism/packages/contracts-bedrock
./scripts/getting-started/config.sh
popd

# Patch with proxies
echo_stage "Generate config file"
DEPLOYMENTS_DIR="optimism_clones/optimism/packages/contracts-bedrock/deployments/getting-started"
rm -rf ${DEPLOYMENTS_DIR}
cp -a getting-started-patch ${DEPLOYMENTS_DIR}

# Generate genesis files
pushd optimism_clones/optimism/op-node
go run cmd/main.go genesis l2 \
  --deploy-config ../packages/contracts-bedrock/deploy-config/getting-started.json \
  --l1-deployments ../packages/contracts-bedrock/deployments/getting-started/.deploy \
  --outfile.l2 genesis.json \
  --outfile.rollup rollup.json \
  --l1-rpc ${L1_RPC_URL}
openssl rand -hex 32 > jwt.txt
cp genesis.json ../../op-geth
cp jwt.txt ../../op-geth
popd

# Initialize op-geth
echo_stage "Initialize op-geth"
pushd optimism_clones/op-geth
mkdir -p datadir
build/bin/geth init --datadir=datadir genesis.json
popd

# Build Docker images
CLOUD_REGION="us-central1"
PROJECT_NAME="delta-exchange-427816-f1"  # Lestnet project
LESTNET_VERSION="0.1"

# Build docker images
echo_stage "Build op-geth docker image"
# Requires go-geth rebuild for Linux.
# A hack with hardcoded versions. Requires a consistent approach, maybe build insode Docker image.
pushd optimism_clones/op-geth
export GOOS=${TARGETOS}
export GOARCH=${TARGETARCH}
go build -ldflags "-X github.com/ethereum/go-ethereum/internal/version.gitCommit=5e9cb8176cf953e09208ffca77c6c6ea7ee07015 -X github.com/ethereum/go-ethereum/internal/version.gitDate=20240614 -X github.com/ethereum/go-ethereum/params.gitTag=v1.101315.3-rc.1 -s" -tags urfave_cli_no_docs,ckzg -trimpath -v -o ./build/bin/geth ./cmd/geth
export GOOS=
export GOARCH=
popd
pushd docker/op-geth
cp ../../optimism_clones/op-geth/build/bin/geth .
cp -r ../../optimism_clones/op-geth/datadir ./datadir
cp ../../optimism_clones/op-geth/jwt.txt .
build_docker ${CLOUD_REGION} ${PROJECT_NAME} "op-geth" ${LESTNET_VERSION}
rm -rf ./geth ./datadir ./jwt.txt
popd

echo_stage "Build op-node docker image"
pushd docker/op-node
cp ../../optimism_clones/optimism/op-node/bin/op-node .
cp ../../optimism_clones/optimism/op-node/jwt.txt .
cp ../../optimism_clones/optimism/op-node/rollup.json .
build_docker ${CLOUD_REGION} ${PROJECT_NAME} "op-node" ${LESTNET_VERSION}
rm -rf ./op-node ./jwt.txt ./rollup.json
popd

echo_stage "Build op-batcher docker image"
pushd docker/op-batcher
cp ../../optimism_clones/optimism/op-batcher/bin/op-batcher .
build_docker ${CLOUD_REGION} ${PROJECT_NAME} "op-batcher" ${LESTNET_VERSION}
rm -rf ./op-batcher
popd

echo_stage "Build op-proposer docker image"
pushd docker/op-proposer
cp ../../optimism_clones/optimism/op-proposer/bin/op-proposer .
build_docker ${CLOUD_REGION} ${PROJECT_NAME} "op-proposer" ${LESTNET_VERSION}
rm -rf ./op-proposer
popd

# Echoing contract addresses
echo "******************************************"
echo "*      Docker images build is done!      *"
echo "******************************************"
echo "* Check out the contract addresses below *"
echo "******************************************"
echo ""
echo "Address of the L1StandardBridgeProxy contract: $(cat optimism_clones/optimism/packages/contracts-bedrock/deployments/getting-started/L1StandardBridgeProxy.json | jq -r .address)"
echo ""
echo "Address of the L2OutputOracleProxy: $(cat optimism_clones/optimism/packages/contracts-bedrock/deployments/getting-started/L2OutputOracleProxy.json | jq -r .address)"
echo "Put this address into the depoly.sh script, assign it to the variable L2_OUTPUT_ORACLE_ADDRESS"

# Remove optimism repos copies
rm -rf optimism_clones
