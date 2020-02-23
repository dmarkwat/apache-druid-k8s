FROM debian:buster-slim

RUN apt-get update && apt-get install -y python3 python3-setuptools curl unzip

WORKDIR /usr/local/lib/

RUN curl -Lo master.zip https://github.com/wikimedia/operations-software-druid_exporter/archive/master.zip \
      && unzip master.zip \
      && rm master.zip \
      && cd operations-software-druid_exporter-master \
      && python3 setup.py install

ENTRYPOINT ["druid_exporter"]
