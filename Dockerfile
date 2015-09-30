FROM ubuntu:14.04

MAINTAINER Reinaldo Calderón

# Set the locale
RUN locale-gen en_US.UTF-8  
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8 

RUN ls

RUN \
  apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y vim nano git wget libfreetype6 libfontconfig bzip2 supervisor zip unzip openssh-server && \
  mkdir -p /srv/var /var/log/supervisor /opt

ENV TOMCAT_VERSION 8.0.21
ENV TOMCAT_PORT 8080
ENV TOMCAT_PATH /opt/tomcat
ENV ACTIVEMQ_VERSION 5.9.1
ENV ACTIVEMQ_PATH /opt/activemq

# ----------- Install java 8 -------------
RUN apt-get -y install software-properties-common
RUN add-apt-repository ppa:webupd8team/java
RUN apt-get -y update
RUN echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 boolean true" | debconf-set-selections
RUN apt-get -y install oracle-java8-installer
RUN apt-get install oracle-java8-set-default

# ----------- Install tomcat -------------

RUN \
    wget -O /tmp/tomcat.tar.gz http://archive.apache.org/dist/tomcat/tomcat-8/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz && \
  #mkdir $TOMCAT_PATH && \
  cd /tmp && \
  tar zxf /tmp/tomcat.tar.gz && \
  ls /tmp && \
  mv /tmp/apache-tomcat* $TOMCAT_PATH && \
  rm -rf $TOMCAT_PATH/webapps/*.* && \
  rm -rf $TOMCAT_PATH/webapps/* && \
  rm /tmp/tomcat.tar.gz

EXPOSE $TOMCAT_PORT
EXPOSE 22

RUN sed -i 's/<\/Host>/<Valve className="org.apache.catalina.valves.RemoteIpValve" remoteIpHeader="X-Forwarded-For" protocolHeader="X-Forwarded-Proto"\/><\/Host>/' /$TOMCAT_PATH/conf/server.xml

# ----------- Install PhantomJS -------------

RUN sudo apt-get  -y install build-essential chrpath libssl-dev libxft-dev  libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev

RUN \
  cd ~ && \
  export PHANTOM_JS="phantomjs-1.9.8-linux-x86_64"  && \
  wget https://bitbucket.org/ariya/phantomjs/downloads/$PHANTOM_JS.tar.bz2  && \
  tar xvjf $PHANTOM_JS.tar.bz2  && \
  mv $PHANTOM_JS /usr/local/share  && \
  ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/bin

RUN phantomjs --version

# ----------- Install ActiveMQ -------------#
RUN \
  wget -O /tmp/activemq.tar.gz http://archive.apache.org/dist/activemq/$ACTIVEMQ_VERSION/apache-activemq-$ACTIVEMQ_VERSION-bin.tar.gz && \
  cd /tmp && \
  tar zxf /tmp/activemq.tar.gz && \
  ls /tmp && \
  mv /tmp/apache-activemq* $ACTIVEMQ_PATH && \
  rm /tmp/activemq.tar.gz

  WORKDIR $ACTIVEMQ_PATH
  EXPOSE 61616 8161
  #EXPOSE 61612 61613 61616 8161

# ----------- Configure SSH -------------

#RUN echo deb http://archive.ubuntu.com/ubuntu trusty main universe > /etc/apt/sources.list.d/trusty.list

# Clean
ADD es_docker_key.pub es_docker_key.pub

RUN \
  mkdir ~/.ssh && \
  touch ~/.ssh/authorized_keys && \
  cat es_docker_key.pub >> ~/.ssh/authorized_keys && \
  rm es_docker_key.pub && \
  /etc/init.d/ssh restart

# Files
ADD tomcat_supervisord_wrapper.sh $TOMCAT_PATH/bin/tomcat_supervisord_wrapper.sh
RUN chmod 755 $TOMCAT_PATH/bin/tomcat_supervisord_wrapper.sh

# Start
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]

