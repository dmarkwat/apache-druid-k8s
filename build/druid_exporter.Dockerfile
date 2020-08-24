FROM debian:buster-slim

RUN apt-get update && apt-get install -y python3 python3-setuptools python3-pip curl unzip

ARG TAG=upstream/0.10

WORKDIR /usr/local/lib/

RUN curl -Lo source.zip https://github.com/wikimedia/operations-software-druid_exporter/archive/${TAG}.zip \
      && unzip source.zip \
      && rm source.zip \
      && cd operations-software-druid_exporter-* \
      && python3 setup.py install

RUN apt-get remove -y python3-pip curl unzip

ENTRYPOINT ["druid_exporter"]
