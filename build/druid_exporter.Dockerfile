FROM debian:buster-slim

RUN apt-get update && apt-get install -y python3 python3-setuptools python3-pip curl unzip

WORKDIR /usr/local/lib/

RUN curl -Lo source.zip https://github.com/wikimedia/operations-software-druid_exporter/archive/upstream/0.10.zip \
      && unzip source.zip \
      && rm source.zip \
      && cd operations-software-druid_exporter-master \
      && python3 setup.py install

ENTRYPOINT ["druid_exporter"]
