FROM --platform=linux/amd64 ubuntu:22.04
RUN echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker
RUN echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker
RUN DEBIAN_FRONTEND=noninteractive \
   apt-get update \
   && rm -rf /var/lib/apt/lists/*
 
USER root

RUN apt-get update
RUN apt-get install -y ca-certificates

COPY ./op-node .
COPY ./jwt.txt .
COPY ./rollup.json .

# Copy certificates to connect to the ethereum network
COPY ./certificates/* /usr/local/share/ca-certificates/
RUN update-ca-certificates

EXPOSE 8547/tcp
CMD "./op-node" "--l2=${LESTNET_SERVER_HOST}:8551" "--l2.jwt-secret=./jwt.txt" "--sequencer.enabled" "--sequencer.l1-confs=5" "--verifier.l1-confs=4" "--rollup.config=./rollup.json" "--rpc.addr=0.0.0.0" "--rpc.port=8547" "--p2p.disable" "--rpc.enable-admin" "--p2p.sequencer.key=${GS_SEQUENCER_PRIVATE_KEY}" "--l1=${L1_RPC_URL}" "--l1.rpckind=${L1_RPC_KIND}"
