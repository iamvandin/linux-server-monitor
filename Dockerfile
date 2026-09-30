FROM ubuntu:24.04

WORKDIR /app

RUN apt-get update && \
    apt-get install -y procps && \
    rm -rf /var/lib/apt/lists/*

COPY monitor.sh .

RUN chmod +x monitor.sh

CMD ["./monitor.sh"]
