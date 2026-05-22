FROM mongo:latest

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        cron \
        openssh-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh /app/entrypoint
COPY ./backup.sh /app/backup-mongodb

RUN chmod +x /app/entrypoint /app/backup-mongodb

VOLUME ["/backups"]

CMD ["/app/entrypoint"]
