FROM docker.io/library/httpd:2.4

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install -y procps vim curl libapache2-mod-auth-cas && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN sed -i \
  -e 's/^#\(Include .*httpd-ssl.conf\)/\1/' \
  -e 's/^#\(LoadModule .*mod_ssl.so\)/\1/' \
  -e 's/^#\(LoadModule .*mod_socache_shmcb.so\)/\1/' \
  -e 's/#LoadModule proxy_module/LoadModule proxy_module/' \
  -e 's/#LoadModule proxy_http_module/LoadModule proxy_http_module/' \
  /usr/local/apache2/conf/httpd.conf \
  && echo "Include conf/custom.conf" >> /usr/local/apache2/conf/httpd.conf

RUN sed -i \
  '/DocumentRoot "\/usr\/local\/apache2\/htdocs"/a\
SSLProxyEngine on\n\
SSLProxyVerify none\n\
SSLProxyCheckPeerName off\n\
SSLProxyCheckPeerExpire off\n\
ProxyErrorOverride off\n\
ProxyPreserveHost on\n\
ProxyPassMatch ^/rnode/(.*)$ wss:\/\/proxy.example.com:443/rnode/\$1\n\
ProxyPass \/ https:\/\/proxy.example.com:443\/\n\
ProxyPassReverse \/ https:\/\/proxy.example.com:443\/\n\
ProxyTimeout 300' \
  /usr/local/apache2/conf/extra/httpd-ssl.conf

RUN cat <<EOF > /usr/local/apache2/conf/server.cnf
[req]
prompt = no
default_bits = 2048
distinguished_name = req_distinguished_name
[req_distinguished_name]
CN = localhost
EOF

RUN openssl req -newkey rsa:2048 -x509 -days 3650 -nodes \
-config /usr/local/apache2/conf/server.cnf \
-keyout /usr/local/apache2/conf/server.key \
-out /usr/local/apache2/conf/server.crt

RUN cat <<EOF > /usr/local/apache2/conf/custom.conf
<Location />
  AuthType CAS
  Require valid-user
</Location>
LoadModule          auth_cas_module /usr/lib/apache2/modules/mod_auth_cas.so
CASRootProxiedAs    https://example.com:443
CASCookiePath       /var/cache/apache2/mod_auth_cas/
CASLoginURL         https://cas.example.com/cas/login
CASValidateURL      https://cas.example.com/cas/serviceValidate
CASProxyValidateURL https://cas.example.com/cas/proxyValidate
CASCertificatePath  /etc/ssl/certs
CASIdleTimeout      14400
CASTimeout          14400
EOF

RUN cat <<EOF > /docker-entrypoint.sh
sed -i \
-e "s/you@example.com/\${EMAIL_ADDRESS}/" \
/usr/local/apache2/conf/httpd.conf
sed -i \
-e "s/you@example.com/\${EMAIL_ADDRESS}/" \
-e "s@ServerName www.example.com:443@ServerName \${SERVER_NAME}@" \
-e "s@https://www.example.com:443@\${WEB_ADDRESS}@" \
-e "s@https://proxy.example.com:443@\${PROXY_ADDRESS}@" \
/usr/local/apache2/conf/extra/httpd-ssl.conf
sed -i \
-e "s@https://example.com:443@\${WEB_ADDRESS}@" \
-e "s@https://cas.example.com@\${CAS_ADDRESS}@" \
/usr/local/apache2/conf/custom.conf
httpd-foreground
EOF

RUN chmod +x /docker-entrypoint.sh

CMD /docker-entrypoint.sh
