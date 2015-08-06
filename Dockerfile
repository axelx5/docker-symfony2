#Symfony2 development environment
FROM debian:7.5

MAINTAINER Leonel Franchelli <arroyo.axelsl@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup
RUN echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache
RUN echo "America/Argentina/Buenos_Aires" > /etc/timezone; dpkg-reconfigure tzdata


RUN apt-get update
RUN apt-get install -y python-software-properties wget

#Add PHP Repository
RUN add-apt-repository 'deb http://packages.dotdeb.org wheezy-php55 all'
RUN echo 'deb-src http://packages.dotdeb.org wheezy-php55 all' >> '/etc/apt/sources.list'

RUN wget http://www.dotdeb.org/dotdeb.gpg
RUN apt-key add dotdeb.gpg

#Add MariaDB Repository
RUN apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
RUN add-apt-repository 'deb http://mirrors.fe.up.pt/pub/mariadb/repo/10.0/debian wheezy main'


RUN apt-get update

RUN apt-get install -y \
    daemontools git curl nginx\
    php5-cli php5-json php5-fpm php5-intl php5-mcrypt php5-mysql mariadb-server mariadb-client php5-sqlite php5-curl


#Add Composer 
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

#Phpmyadmin
RUN apt-get install -y phpmyadmin
RUN apt-get install -y pwgen
RUN apt-get install -y inotify-tools

#ssh
RUN apt-get install -y openssh-server

# Limpiamos la basura
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN echo "daemonize=no" > /etc/php5/fpm/pool.d/daemonize.conf
RUN echo "\ndaemon off;" >> /etc/nginx/nginx.conf

#Add config files 
ADD config/vhost.conf /etc/nginx/sites-enabled/default
ADD config/php.ini /etc/php5/fpm/php.ini
ADD config/php.ini /etc/php5/cli/php.ini
ADD config/my.cnf /etc/mysql/my.cnf

#Script folders
ADD scripts /scripts

#Setup DB at first run
RUN touch /firstrun

VOLUME ["/var/log/nginx/"]

ADD config/entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 80
EXPOSE 22
EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]