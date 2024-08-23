set -e

# Cloning the geth kurtosis configuration
mkdir -p geth_kurtosis_clone
pushd geth_kurtosis_clone
git clone https://github.com/ethpandaops/ethereum-package.git
popd

# Patching the geth kurtosis configuration
pushd geth_kurtosis_clone/ethereum-package
patch -p 1 < ../../geth_kurtosis/geth_launcher.star.patch
popd

# Patching pre-defined accounts
cat > ./geth_kurtosis_clone/ethereum-package/src/prelaunch_data_generator/genesis_constants/genesis_constants.star << PRE_FUNDED
$(gcloud secrets versions access 1 --secret="LESTNET_PREFUNDED_ACCOUNTS")
PRE_FUNDED

# Running lestnet on curtosis
kurtosis run ./geth_kurtosis_clone/ethereum-package \
  --args-file ./geth_kurtosis/network_params.yaml \
  --image-download always \
  --enclave lestnet

# Getting internal hosts and ports
RPC_HOST_PORT=$(kurtosis port print lestnet el-1-geth-lighthouse rpc)
WS_HOST_PORT=$(kurtosis port print lestnet el-1-geth-lighthouse ws)

# Reconfiguring nginx proxy
cat >lestnet.conf << RPC
log_format postdata escape=json '\$remote_addr - \$remote_user [\$time_local] '
                '"\$request" \$status $bytes_sent '
                '"\$http_referer" "\$http_user_agent" "\$request_body"';

server {

        listen 443 ssl;
        server_name service.lestnet.org www.service.lestnet.org;

        ssl_certificate /etc/nginx/conf.d/STAR_lestnet_org_chain.crt;
        ssl_certificate_key /etc/nginx/conf.d/STAR_lestnet_org.key;
        ssl_session_cache shared:SSL:10m;

        location / {
                access_log  /var/log/nginx/geth_postdata.log  postdata;
                proxy_pass http://${RPC_HOST_PORT};
                proxy_set_header Host \$host;

                # re-write redirects to http as to https, example: /home
                proxy_redirect http:// https://;
        }
}
RPC

cat >lestnet_ws.conf << WS
server {
        listen 8888 ssl;
        server_name service.lestnet.org www.service.lestnet.org;
        ssl_certificate /etc/nginx/conf.d/STAR_lestnet_org_chain.crt;
        ssl_certificate_key /etc/nginx/conf.d/STAR_lestnet_org.key;
        location / {
                proxy_pass http://${WS_HOST_PORT};
                proxy_http_version 1.1;
                proxy_set_header Upgrade \$http_upgrade;
                proxy_set_header Connection "upgrade";
                proxy_read_timeout 86400;
        }
}
WS

sudo cp lestnet.conf /etc/nginx/conf.d/
sudo cp lestnet_ws.conf /etc/nginx/conf.d/

# Reloading updated nginx configurations
sudo /usr/sbin/nginx -s reload

# Deleting the geth kurtosis repository clone.
rm -rf geth_kurtosis_clone
