# CAS Proxy

This document demos protecting another web service with CAS. Apache is configured to proxy requests to the backend web service. Note that is special configuration using two Apaches was necessary because we wish to use both mod_auth_gssapi and mod_auth_cas and Apache cannot be configured to use both for the same URLs. Hence two Apaches are used.

The example below use nginx as the example service to make it more clear what is being proxied.

## Run an example service to be proxied

```sh
docker run -d --rm --publish 80:80 nginx
```

## Build

```sh
docker build -t cas-proxy .
```

## Run the CAS Proxy

```sh
# Get the local system's IP address
# This work on wifi connected Mac, change as needed
LOCAL_IP=$(ipconfig getifaddr en0)

docker run -d \
--name cas-proxy \
-p 8443:443 \
-e EMAIL_ADDRESS=research.computing@dartmouth.edu \
-e WEB_ADDRESS=https://localhost:8443 \
-e PROXY_ADDRESS=http://$LOCAL_IP:80 \
-e CAS_ADDRESS=https://login.dartmouth.edu \
-e SERVER_NAME=localhost:8443 \
cas-proxy
```

## Test

Browse to https://localhost:8443/ and accept the invalid certificate. You should be sent through single sign-on and then are presented with the nginx welcome page. This shows that you are using Apache's mod_auth_cas to protect and proxy the nginx web service.

## Deployment to product

```sh
ssh admin@ood-webserver

git clone https://github.com/dartmouth/ondemand-gssapi-cas.git

cd cas-proxy

sudo podman build -t cas-proxy .

sudo podman run \
-d \
--replace \
--name cas-proxy \
-p 8443:443 \
-e EMAIL_ADDRESS=research.computing@dartmouth.edu \
-e WEB_ADDRESS=https://ood.dartmouth.edu \
-e PROXY_ADDRESS=https://10.123.123.123:443 \
-e CAS_ADDRESS=https://login.dartmouth.edu \
-e SERVER_NAME=ood.dartmouth.edu:443 \
cas-proxy

cd
podman generate systemd --new --name cas-proxy -f
sudo podman rm -f cas-proxy

sudo mv container-cas-proxy.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable container-cas-proxy.service
sudo systemctl start container-cas-proxy.service
sudo systemctl status container-cas-proxy.service
```