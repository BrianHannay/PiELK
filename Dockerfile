FROM arm32v7/centos:latest
RUN yum -y install deltarpm
RUN yum -y upgrade
RUN yum -y install java-11-openjdk make gcc gcc-c++ gmp-devel mpfr-devel libmpc-devel vim libatomic zip unzip ipa-gothic-fonts xorg-x11-fonts-100dpi xorg-x11-fonts-75dpi xorg-x11-utils xorg-x11-fonts-cyrillic xorg-x11-fonts-Type1 xorg-x11-fonts-misc fontconfig freetype

RUN curl https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.8.0-no-jdk-linux-x86_64.tar.gz -o elasticsearch-7.8.0.tar.gz
RUN tar -xzvf elasticsearch-7.8.0.tar.gz
RUN mkdir -p elasticsearch-7.8.0/jdk/bin
RUN ln -s /usr/bin/java elasticsearch-7.8.0/jdk/bin/

#RUN yum -y install java-1.8.0-openjdk

RUN curl https://artifacts.elastic.co/downloads/logstash/logstash-7.8.0.tar.gz -o logstash-7.8.0.tar.gz
RUN tar -xzvf logstash-7.8.0.tar.gz

RUN cd /logstash-7.8.0/logstash-core/lib/jars \
    && unzip -d jruby-complete-9.2.11.1 jruby-complete-9.2.11.1.jar \
    && cd jruby-complete-9.2.11.1/META-INF/jruby.home/lib/ruby/stdlib/ffi/platform/arm-linux \
    && cp -n types.conf platform.conf

RUN cd /logstash-7.8.0/logstash-core/lib/jars/jruby-complete-9.2.11.1 \
    && zip -r jruby-complete-9.2.11.1.jar * \
    && mv -f jruby-complete-9.2.11.1.jar .. \
    && cd .. \
    && rm -rf jruby-complete-9.2.11.1

RUN curl https://artifacts.elastic.co/downloads/kibana/kibana-7.8.0-linux-x86_64.tar.gz -o kibana-7.8.0.tar.gz
RUN tar xzvf kibana-7.8.0.tar.gz
RUN curl https://nodejs.org/dist/v10.21.0/node-v10.21.0-linux-armv7l.tar.xz -o ./node.tar.xz
RUN tar xJvf node.tar.xz
RUN rm -rf /kibana-7.8.0-linux-x86_64/node
RUN ln -s /node-v10.21.0-linux-armv7l /kibana-7.8.0-linux-x86_64/node

RUN curl ftp://ftp.gnu.org/gnu/gcc/gcc-4.9.1/gcc-4.9.1.tar.gz -O
RUN tar xzvf gcc-4.9.1.tar.gz
RUN cd gcc-4.9.1 && ./configure --enable-languages=c,c++ --disable-multilib --with-float=hard
RUN cd gcc-4.9.1 && make
RUN cd gcc-4.9.1 && make install

ENV LS_JAVA_OPTS -Xms512m -Xmx512m
ENV ES_JAVA_OPTS -Xms512m -Xmx512m

COPY kibana.yml /kibana-7.8.0-linux-x86_64/config/
COPY elasticsearch.yml /elasticsearch-7.8.0/config/
COPY logstash.yml /logstash-7.8.0/config/

COPY start_services.sh /start_services.sh
RUN chmod +x /start_services.sh

ENTRYPOINT source /start_services.sh
