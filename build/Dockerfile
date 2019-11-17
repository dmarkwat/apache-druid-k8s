FROM openjdk:8

WORKDIR /druid/

RUN curl -Lo /tmp/apache-druid.tgz http://mirror.cogentco.com/pub/apache/incubator/druid/0.16.0-incubating/apache-druid-0.16.0-incubating-bin.tar.gz \
    && tar --strip-components=1 -zxf /tmp/apache-druid.tgz \
    && rm /tmp/apache-druid.tgz

COPY supervise bin/alt-supervise

ENTRYPOINT ["/druid/bin/alt-supervise"]
