FROM alpine:latest

# Instalar OpenSSL
RUN apk add --no-cache openssl

# Crear directorio de trabajo
WORKDIR /certs

# Copiar scripts
COPY generate-certs.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/generate-certs.sh

# Crear directorio de salida con permisos adecuados
RUN mkdir -p /output && chmod 777 /output

CMD ["/usr/local/bin/generate-certs.sh"]