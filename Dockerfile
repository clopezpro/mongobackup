FROM rclone/rclone:latest AS rclone

FROM mongo:latest

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        cron \
        openssh-client \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# rclone moderno (el de la distribucion de Ubuntu es 1.60 y devuelve
# "501 Not Implemented" contra Cloudflare R2, que exige una version mas nueva)
COPY --from=rclone /usr/local/bin/rclone /usr/local/bin/rclone

COPY ./entrypoint.sh /app/entrypoint
COPY ./backup.sh /app/backup-mongodb
COPY ./upload-s3.sh /app/upload-s3.sh

RUN chmod +x /app/entrypoint /app/backup-mongodb /app/upload-s3.sh && \
    rclone version | head -1

VOLUME ["/backups"]

CMD ["/app/entrypoint"]
