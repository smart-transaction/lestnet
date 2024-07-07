FROM --platform=linux/amd64 ubuntu:22.04
RUN echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker
RUN echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker
RUN DEBIAN_FRONTEND=noninteractive \
   apt-get update \
   && rm -rf /var/lib/apt/lists/*
 
USER root

COPY ./op-batcher .

EXPOSE 8548/tcp
CMD "./op-batcher" "--l2-eth-rpc=http://${GETH_HOST}:8545" "--rollup-rpc=http://${NODE_HOST}:8547" "--poll-interval=1s" "--sub-safety-margin=6" "--num-confirmations=1" "--safe-abort-nonce-too-low-count=3" "--resubmission-timeout=30s" "--rpc.addr=0.0.0.0" "--rpc.port=8548" "--rpc.enable-admin" "--max-channel-duration=1" "--l1-eth-rpc=${L1_RPC_URL}" "--private-key=${GS_BATCHER_PRIVATE_KEY}"
