FROM --platform=linux/amd64 ubuntu:22.04
RUN echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker
RUN echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker
RUN DEBIAN_FRONTEND=noninteractive \
   apt-get update \
   && rm -rf /var/lib/apt/lists/*
 
USER root

COPY ./geth .
COPY ./datadir ./datadir
COPY ./jwt.txt .

EXPOSE 8545/tcp
EXPOSE 8546/tcp
EXPOSE 8551/tcp
CMD "./geth" "--datadir=./datadir" "--http" "--http.corsdomain=*" "--http.vhosts=*" "--http.addr=0.0.0.0" "--http.api=web3,debug,eth,txpool,net,engine" "--ws" "--ws.addr=0.0.0.0" "--ws.port=8546" "--ws.origins=*" "--ws.api=debug,eth,txpool,net,engine" "--syncmode=full" "--gcmode=archive" "--nodiscover" "--maxpeers=0" "--networkid=21363" "--authrpc.vhosts=*" "--authrpc.addr=0.0.0.0" "--authrpc.port=8551" "--authrpc.jwtsecret=./jwt.txt" "--rollup.disabletxpoolgossip=true" "--state.scheme=hash"