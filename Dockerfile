FROM php:7.4-apache

# change UID
RUN usermod -u 1000 www-data &&\
    chown -R www-data /var/www

# add php-gd extension
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

# add php-intl extension
RUN apt-get install -y libicu-dev &&\
    docker-php-ext-configure intl &&\
    docker-php-ext-install intl

# add php-pdo_mysql and install mysql client for the install process
RUN apt-get install -y default-mysql-client &&\
    docker-php-ext-install pdo_mysql

# add php-zip
RUN apt-get install -y libzip-dev zip &&\
    docker-php-ext-install zip

# add xdebug
RUN yes | pecl install xdebug \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.discover_client_host=1" >> /usr/local/etc/php/conf.d/xdebug.ini

# PHP CONFIG
RUN echo "memory_limit = 1024M" >> /usr/local/etc/php/conf.d/custom.ini

# change document root
ENV APACHE_DOCUMENT_ROOT /var/www/html/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# enable mod_rewrite
RUN a2enmod rewrite

# install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" &&\
    php -r "if (hash_file('sha384', 'composer-setup.php') === '756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" &&\
    php composer-setup.php --install-dir=/bin --filename=composer &&\
    php -r "unlink('composer-setup.php');"

# install latest node/npm
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && apt-get install -y nodejs
