FROM --platform=linux/amd64 ubuntu:22.04
RUN echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker
RUN echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker
RUN DEBIAN_FRONTEND=noninteractive \
   apt-get update \
   && rm -rf /var/lib/apt/lists/*

USER root

COPY ./op-proposer .

EXPOSE 8560/tcp
CMD "./op-proposer" "--poll-interval=12s" "--rpc.port=8560" "--rollup-rpc=http://${NODE_HOST}:8547" "--l2oo-address=${L2_OUTPUT_ORACLE_ADDRESS}" "--private-key=${GS_PROPOSER_PRIVATE_KEY}" "--l1-eth-rpc=${L1_RPC_URL}"
