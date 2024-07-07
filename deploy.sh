function echo_stage() {
  MSG=$1
  echo ""
  echo "=========="
  echo ${MSG}
  echo "=========="
  echo ""
}

# Env variables
LESTNET_SERVER_HOST="http://localhost"
L1_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/ICXxRS_FHofIsVaTe_LxtU9Uaqfxw8Rc"
L1_RPC_KIND="alchemy"
L2_OUTPUT_ORACLE_ADDRESS="0xc5F40E6F694DC18A4b6006b55f586b306F63a5bd"

# Create up and down scripts.
cat >up.sh << UP
# Turn up Lestnet services.

set -e

# Secrets
cat >.env << ENV
GS_BATCHER_PRIVATE_KEY=\$(gcloud secrets versions access 1 --secret="GS_BATCHER_PRIVATE_KEY")
GS_SEQUENCER_PRIVATE_KEY=\$(gcloud secrets versions access 1 --secret="GS_SEQUENCER_PRIVATE_KEY")
GS_PROPOSER_PRIVATE_KEY=\$(gcloud secrets versions access 1 --secret="GS_PROPOSER_PRIVATE_KEY")

ENV

sudo docker-compose up -d --remove-orphans

rm -f .env

UP

sudo chmod a+x up.sh

cat >down.sh << DOWN
# Turn down CleanApp service.
sudo docker-compose down
DOWN
sudo chmod a+x down.sh

# Docker images
CLOUD_REGION="us-central1"
PROJECT_NAME="delta-exchange-427816-f1"  # Lestnet project
LESTNET_VERSION="0.1"
DOCKER_IMAGE="lestnet-docker-repo"

DOCKER_PREFIX="${CLOUD_REGION}-docker.pkg.dev/${PROJECT_NAME}/${DOCKER_IMAGE}"
GETH_DOCKER_IMAGE="${DOCKER_PREFIX}/op-geth:${LESTNET_VERSION}"
NODE_DOCKER_IMAGE="${DOCKER_PREFIX}/op-node:${LESTNET_VERSION}"
BATCHER_DOCKER_IMAGE="${DOCKER_PREFIX}/op-batcher:${LESTNET_VERSION}"
PROPOSER_DOCKER_IMAGE="${DOCKER_PREFIX}/op-proposer:${LESTNET_VERSION}"

OP_GETH_CONTAINER="op_geth"
OP_NODE_CONTAINER="op_node"
OP_BATCHER_CONTAINER="op_batcher"
OP_PROPOSER_CONTAINER="op_container"

# Create docker-compose.yml file.
cat >docker-compose.yml << COMPOSE
version: '3'

services:
  ${OP_GETH_CONTAINER}:
    container_name: op_geth
    image: ${GETH_DOCKER_IMAGE}
    ports:
      - 8545:8545
      - 8551:8551

  ${OP_NODE_CONTAINER}:
    container_name: op_node
    image: ${NODE_DOCKER_IMAGE}
    depends_on:
      - ${OP_GETH_CONTAINER}
    environment:
      - GETH_HOST=${OP_GETH_CONTAINER}
      - GS_SEQUENCER_PRIVATE_KEY=\${GS_SEQUENCER_PRIVATE_KEY}
      - L1_RPC_URL=${L1_RPC_URL}
      - L1_RPC_KIND=${L1_RPC_KIND}
    ports:
      - 8547:8547

  ${OP_BATCHER_CONTAINER}:
    container_name: op_batcher
    image: ${BATCHER_DOCKER_IMAGE}
    depends_on:
      - ${OP_GETH_CONTAINER}
      - ${OP_NODE_CONTAINER}
    environment:
      - GETH_HOST=${OP_GETH_CONTAINER}
      - NODE_HOST=${OP_NODE_CONTAINER}
      - GS_BATCHER_PRIVATE_KEY=\${GS_BATCHER_PRIVATE_KEY}
      - L1_RPC_URL=${L1_RPC_URL}
    ports:
      - 8548:8548

  ${OP_PROPOSER_CONTAINER}:
    container_name: op_proposer
    image: ${PROPOSER_DOCKER_IMAGE}
    depends_on:
      - ${OP_NODE_CONTAINER}
    environment:
      - NODE_HOST=${OP_NODE_CONTAINER}
      - GS_BATCHER_PRIVATE_KEY=\${GS_BATCHER_PRIVATE_KEY}
      - L1_RPC_URL=${L1_RPC_URL}
      - L2_OUTPUT_ORACLE_ADDRESS=${L2_OUTPUT_ORACLE_ADDRESS}
    ports:
      - 8560:8560

COMPOSE

# Pull images:
echo_stage "Pulling ${GETH_DOCKER_IMAGE}"
docker pull ${GETH_DOCKER_IMAGE}
echo_stage "Pulling ${NODE_DOCKER_IMAGE}"
docker pull ${NODE_DOCKER_IMAGE}
echo_stage "Pulling ${BATCHER_DOCKER_IMAGE}"
docker pull ${BATCHER_DOCKER_IMAGE}
echo_stage "Pulling ${PROPOSER_DOCKER_IMAGE}"
docker pull ${PROPOSER_DOCKER_IMAGE}

# Start our docker images.
echo_stage "Running up.sh script"
./up.sh
