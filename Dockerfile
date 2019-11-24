FROM        php:7.3-apache

LABEL       maintainer="nontakan.doae@gmail.com"

ARG         DEBIAN_FRONTEND=noninteractive

COPY        index.php /var/www/html/index.php

# Change System TimeZone to Asia/Bangkok
RUN         ln -sf /usr/share/zoneinfo/Asia/Bangkok /etc/localtime

RUN         a2enmod rewrite && a2enmod ssl

# Update Repositories
RUN         apt-get update --fix-missing \
            && apt-get upgrade -fy \
            && apt-get dist-upgrade -fy \
            && apt-get install --no-install-recommends -fy \
                autoconf \
                pkg-config \
                apt-utils \
                apt-transport-https \
                git \
                wget \
                rsync \
            && apt-get autoremove -fy \
            && apt-get clean \
            && apt-get autoclean -y \
            && docker-php-source delete \
            && rm -rf /var/lib/apt/lists/*

# BZ2
RUN         apt-get update --fix-missing \
            && apt-get install --no-install-recommends -fy \
                bzip2 \
                bzip2-doc \
                libbz2-dev \
            && docker-php-ext-install bz2 \
            && apt-get autoremove -fy \
            && apt-get clean \
            && apt-get autoclean -y \
            && docker-php-source delete \
            && rm -rf /var/lib/apt/lists/* \
            && echo "Sucess # BZ2" && sleep 1

# GD
RUN         apt-get update --fix-missing \
            && apt-get install --no-install-recommends -fy \
                libfreetype6-dev \
                libjpeg-dev \
                libjpeg62-turbo-dev \
                libpng-dev \
                libpng-dev \
            && docker-php-ext-configure gd \
                --enable-gd-native-ttf \
                --with-freetype-dir=/usr/include/freetype2 \
                --with-png-dir=/usr/include \
                --with-jpeg-dir=/usr/include \
            && docker-php-ext-install gd \
            && docker-php-ext-enable gd  \
            && apt-get autoremove -fy \
            && apt-get clean \
            && apt-get autoclean -y \
            && docker-php-source delete \
            && rm -rf /var/lib/apt/lists/* \
            && echo "Sucess # GD" && sleep 1

# GetText
RUN         docker-php-ext-install gettext \
            && docker-php-source delete \
            && rm -rf /var/lib/apt/lists/* \
            && echo "Sucess # GetText" && sleep 1

# MCrypt
RUN         apt-get update --fix-missing \
            && apt-get install --no-install-recommends -fy \
                libmcrypt-dev \
            && pecl install mcrypt-1.0.3 \
            && docker-php-ext-enable mcrypt \
            && apt-get autoremove -fy \
            && apt-get clean \
            && apt-get autoclean -y \
            && docker-php-source delete \
            && rm -rf /var/lib/apt/lists/* \
            && echo "Sucess # MCrypt" && sleep 1

# Memcached
RUN         apt-get update --fix-missing \
            && apt-get install --no-install-recommends -fy \
                libmemcached-dev \
                zlib1g-dev \
            && doNotUninstall=" \
                libmemcached11 \
                libmemcachedutil2 \
            " \
            && rm -r /var/lib/apt/lists/* \
            && docker-php-source extract \
            && git clone https://github.com/php-memcached-dev/php-memcached /usr/src/php/ext/memcached/ \
            && docker-php-ext-install memcached \
            && apt-mark manual $doNotUninstall \
            && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps \
            && apt-get autoremove -fy \
            && apt-get clean \
            && apt-get autoclean -y \
            && docker-php-source delete \
            && rm -rf /var/lib/apt/lists/* \
            && echo "Sucess # Memcached" && sleep 1

# MySQL
RUN         docker-php-ext-install mysqli \
                pdo pdo_mysql \
            && docker-php-source delete \
            && rm -rf /var/lib/apt/lists/* \
            && echo "Sucess # MySQL" && sleep 1

# PostgreSQL
RUN         apt-get update --fix-missing \
            && apt-get install -y libpq-dev \
            && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
            && docker-php-ext-install pdo pdo_pgsql pgsql \
            && apt-get autoremove -fy \
            && apt-get clean \
            && apt-get autoclean -y \
            && docker-php-source delete \
            && rm -rf /var/lib/apt/lists/* \
            && echo "Sucess # PostgreSQL" && sleep 1


# Redis
COPY        sources.list /etc/apt/sources.list
RUN         apt-get update --fix-missing \
            && apt-get install -y libhiredis-dev \
            # && pecl channel-update pecl.php.net \
            && echo "INSTALL redis ............................... \n" \
            && pecl channel-update pecl.php.net \
            && pecl install redis \
            && docker-php-ext-enable redis \
            && git clone https://github.com/nrk/phpiredis.git \
            && ( \
                cd phpiredis \
                && git checkout v1.0.0 \
                && phpize \
                && ./configure --enable-phpiredis \
                && make install \
            ) \
            && docker-php-ext-enable phpiredis \
            && rm -rf $(pwd)/phpiredis \
            && apt-get autoremove -fy \
            && apt-get clean \
            && apt-get autoclean -y \
            && docker-php-source delete \
            && rm -rf /var/lib/apt/lists/* \
            && echo "Sucess # Redis" && sleep 1

# SQL Server
ENV         ACCEPT_EULA=Y
RUN         apt-get update --fix-missing \
            && apt-get install --no-install-recommends -fy \
                gnupg \
            && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
            && curl https://packages.microsoft.com/config/debian/9/prod.list > /etc/apt/sources.list.d/mssql.list \
            && apt-get update --fix-missing \
            && apt-get install --no-install-recommends -y \
                unixodbc \
                odbcinst1debian2 \
                unixodbc-dev \
                locales \
                msodbcsql17 \
                mssql-tools \
            && printf "th_TH.UTF-8 UTF-8\nen_US UTF-8\nen_US.UTF-8 UTF-8\n" > /etc/locale.gen \
            && locale-gen \
            && pecl channel-update pecl.php.net \
            && echo "INSTALL sqlsrv pdo_sqlsrv ............................... \n" \
            && pecl install sqlsrv pdo_sqlsrv \
            && docker-php-ext-enable \
                sqlsrv.so \
                pdo_sqlsrv.so \
            && echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile \
            && echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc \
            && apt-get autoremove -fy \
            && apt-get clean \
            && apt-get autoclean -y \
            && docker-php-source delete \
            && rm -rf /var/lib/apt/lists/* \
            && echo "Sucess # SQL Server EXT" && sleep 1

#Zip
RUN         apt-get update --fix-missing \
            && apt-get install --no-install-recommends -fy \
                libzip-dev \
                zip \
                unzip \
            && echo "INSTALL zip ............................... \n" \
            && docker-php-ext-install zip \
            && apt-get autoremove -fy \
            && apt-get clean \
            && apt-get autoclean -y \
            && docker-php-source delete \
            && rm -rf /var/lib/apt/lists/* \
            && echo "Sucess # Zip" && sleep 1

# PDF
RUN         apt-get update --fix-missing \
            && echo "INSTALL wkhtmltopdf ............................... \n" \
            && apt-get install --no-install-recommends -fy \
                libthai0 \
                xfonts-thai \
#                pdftk \
                libxrender1 \
                libfontconfig1 \
                libxtst6 \
                libx11-dev \
                libjpeg62 \
            && wget https://github.com/h4cc/wkhtmltopdf-amd64/blob/master/bin/wkhtmltopdf-amd64?raw=true --no-verbose -O /usr/local/bin/wkhtmltopdf \
            && chmod +x /usr/local/bin/wkhtmltopdf \
            && rm -rf /var/lib/apt/lists/* \
            && apt-get autoremove -fy \
            && apt-get clean \
            && apt-get autoclean -y \
            && echo "Sucess # PDF wkhtmltopdf" && sleep 1

# IMAP
RUN         apt-get update --fix-missing \
            && apt-get install --no-install-recommends -fy \
                libc-client-dev \
                libkrb5-dev \
            && echo "INSTALL IMAP ............................... \n" \    
            && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
            && docker-php-ext-install imap \
            && apt-get autoremove -fy \
            && apt-get clean \
            && apt-get autoclean -y \
            && docker-php-source delete \
            && rm -rf /var/lib/apt/lists/* \
            && echo "Sucess # IMAP" && sleep 1

# BCMATH
RUN         apt-get update --fix-missing \
            && echo "INSTALL bcmath ............................... \n" \ 
            && docker-php-ext-configure bcmath \
            && docker-php-ext-install bcmath \
            && apt-get autoremove -fy \
            && apt-get clean \
            && apt-get autoclean -y \
            && docker-php-source delete \
            && rm -rf /var/lib/apt/lists/* \
            && echo "Sucess # BCMATH" && sleep 1

# ActiveDirectory / LDAP
RUN         apt-get update --fix-missing \
            && apt-get install libldap2-dev -y \
            && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
            && docker-php-ext-install ldap \
            && apt-get autoremove -fy \
            && apt-get clean \
            && apt-get autoclean -y \
            && docker-php-source delete \
            && rm -rf /var/lib/apt/lists/* \
            && echo "Sucess # ActiveDirectory / LDAP" && sleep 1

# Graphviz
RUN         apt-get update --fix-missing \
            && apt-get install --no-install-recommends -fy \
                graphviz \
            && apt-get autoremove -fy \
            && apt-get clean \
            && apt-get autoclean -y \
            && rm -rf /var/lib/apt/lists/* \
            && echo "Sucess # Graphviz" && sleep 1

# Calendar
RUN         docker-php-ext-install calendar \
            && docker-php-source delete \
            && rm -rf /var/lib/apt/lists/* \
            && echo "Sucess # Calendar" && sleep 1

# SSH
RUN         apt-get update --fix-missing \
            && apt-get install --no-install-recommends -fy \
                openssh-client \
            && apt-get autoremove -fy \
            && apt-get clean \
            && apt-get autoclean -y \
            && rm -rf /var/lib/apt/lists/* \
            && echo "Sucess # SSH" && sleep 1

# Composer
RUN         wget https://getcomposer.org/installer -O - -q | php -- --no-ansi --install-dir=/usr/bin --filename=composer \
            && composer config --global repo.packagist composer https://packagist.org \
            && composer global require hirak/prestissimo \
            && composer global require laravel/installer \
            && composer global require phpunit/phpunit \
            && composer global require squizlabs/php_codesniffer \
            && composer global require beyondcode/laravel-self-diagnosis \
            && composer global require beyondcode/laravel-er-diagram-generator \
            && export PATH="~/.composer/vendor/bin:$PATH" \
            && mkdir -p /root/.ssh \
            && echo "StrictHostKeyChecking no" > /root/.ssh/config \
            && echo "Sucess # Composer" && sleep 1

# XDEBUG
RUN         pecl install xdebug \
            && docker-php-ext-enable xdebug \
            && docker-php-source delete \
            && rm -rf /var/lib/apt/lists/* \
            && echo "Sucess # XDEBUG" && sleep 1


# Install Oracle Client
RUN         mkdir /opt/oracle
RUN         chmod -R +x /opt/oracle
RUN         chmod -R 755 /opt/oracle

RUN         apt-get update && apt-get -y install wget bsdtar libaio1 && \
            wget -qO- https://raw.githubusercontent.com/caffeinalab/php-fpm-oci8/master/oracle/instantclient-basic-linux.x64-12.2.0.1.0.zip | bsdtar -xvf- -C /opt/oracle && \
            wget -qO- https://raw.githubusercontent.com/caffeinalab/php-fpm-oci8/master/oracle/instantclient-sdk-linux.x64-12.2.0.1.0.zip | bsdtar -xvf-  -C /opt/oracle

RUN         ln -s /opt/oracle/instantclient_12_2/libclntsh.so.12.1 /opt/oracle/instantclient_12_2/libclntsh.so \
             && ln -s /opt/oracle/instantclient_12_2/libclntshcore.so.12.1 /opt/oracle/instantclient_12_2/libclntshcore.so \
             && ln -s /opt/oracle/instantclient_12_2/libocci.so.12.1 /opt/oracle/instantclient_12_2/libocci.so

ENV         LD_LIBRARY_PATH  /opt/oracle/instantclient_12_2:${LD_LIBRARY_PATH}
RUN         echo 'instantclient,/opt/oracle/instantclient_12_2/' | pecl install oci8 \
            && docker-php-ext-enable oci8 \ 
            && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/oracle/instantclient_12_2,12.1 \
            && docker-php-ext-install pdo_oci \
            && docker-php-source delete \
            && apt-get autoremove -fy \
            && apt-get clean \
            && apt-get autoclean -y \
            && rm -rf /var/lib/apt/lists/* \
            && rm -f /opt/oracle/instantclient-basic-linux.x64-12.2.0.1.0.zip \
            && rm -f /opt/oracle/instantclient-sdk-linux.x64-12.2.0.1.0.zip \
            && echo "Sucess # Install Oracle Client" && sleep 1

EXPOSE 80 443