FROM openjdk:8

WORKDIR /druid/

RUN curl -Lo /tmp/apache-druid.tgz http://mirrors.advancedhosters.com/apache/druid/0.17.0/apache-druid-0.17.0-bin.tar.gz \
    && tar --strip-components=1 -zxf /tmp/apache-druid.tgz \
    && rm /tmp/apache-druid.tgz

COPY supervise bin/alt-supervise

ENTRYPOINT ["/druid/bin/alt-supervise"]
