FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y openjdk-8-jdk wget curl gnupg && \
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add - && \
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list && \
    apt-get update && \
    apt-get install -y mongodb-database-tools && \
    wget https://downloads.apache.org/pig/pig-0.17.0/pig-0.17.0.tar.gz && \
    tar -xzvf pig-0.17.0.tar.gz -C /opt && \
    ln -s /opt/pig-0.17.0/bin/pig /usr/local/bin/pig && \
    rm pig-0.17.0.tar.gz

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PIG_HOME /opt/pig-0.17.0
ENV PATH $PATH:$PIG_HOME/bin

COPY filtrar_eventos.pig /scripts/filtrar_eventos.pig
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /data

CMD ["/entrypoint.sh"]