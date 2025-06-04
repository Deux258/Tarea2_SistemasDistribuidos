FROM bde2020/hadoop-base:2.0.0-hadoop3.2.1-java8

WORKDIR /app

COPY procesar_eventos.pig .
COPY entrypoint.sh .

RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"] 