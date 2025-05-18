FROM haproxy:2.9

# generate a self-signed certificate for TLS termination
RUN openssl req -x509 -newkey rsa:2048 -sha256 -days 365 -nodes \
    -subj "/CN=haproxy" \
    -keyout /usr/local/etc/haproxy/server.key \
    -out /usr/local/etc/haproxy/server.crt && \
    cat /usr/local/etc/haproxy/server.crt /usr/local/etc/haproxy/server.key > /usr/local/etc/haproxy/server.pem

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
EXPOSE 5432 9999
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg", "-db"]
