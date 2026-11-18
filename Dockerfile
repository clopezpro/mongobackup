FROM mongo:latest

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        cron \
        openssh-client \
        rclone \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh /app/entrypoint
COPY ./backup.sh /app/backup-mongodb
COPY ./upload-s3.sh /app/upload-s3.sh

RUN chmod +x /app/entrypoint /app/backup-mongodb /app/upload-s3.sh

VOLUME ["/backups"]

CMD ["/app/entrypoint"]
