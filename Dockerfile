FROM php:5.6-apache

MAINTAINER Viet Pham <viet@webonyx.com>

ENV COMPOSER_VERSION 1.2.1

# install the PHP extensions we need
RUN apt-get update && apt-get install -y libapache2-mod-xsendfile git \
    libpng12-dev libjpeg-dev libmcrypt-dev libmemcached-dev libgearman-dev uuid-dev libtidy-dev libmagickwand-dev \
    zlib1g-dev libicu-dev --no-install-recommends \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-configure intl \
	&& docker-php-ext-configure zip \
	&& docker-php-ext-configure tidy \
	&& docker-php-ext-install gd zip intl tidy pdo_mysql opcache iconv mcrypt

RUN pecl install memcache memcached gearman uuid imagick \
    && docker-php-ext-enable memcache memcached gearman uuid imagick

RUN apt-get purge -y --auto-remove uuid-dev libpng12-dev libjpeg-dev libgearman-dev libmemcached-dev libtidy-dev libmcrypt-dev libmagickwand-dev \
    && apt-get install -y libicu52 libjpeg62-turbo libgearman7 libmemcached11 libmemcachedutil2 libmcrypt4 libtidy-0.99-0 libmagickwand-6.q16-2\
    --no-install-recommends \
    && apt-get clean && apt-get autoremove -q \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc /usr/share/man /tmp/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN a2enmod ssl rewrite expires headers
COPY php.ini /usr/local/etc/php/php.ini

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');" && \
    php -r "copy('https://composer.github.io/installer.sig', '/tmp/composer-setup.sig');" && \
    php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" && \
    php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer  --version=$COMPOSER_VERSION && \
    php -r "unlink('/tmp/composer-setup.php');" && \
    rm -rf /tmp/*  && \
    composer global require "hirak/prestissimo:^0.3" --update-no-dev
