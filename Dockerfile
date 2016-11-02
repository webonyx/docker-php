FROM php:5.6-apache

MAINTAINER Viet Pham <viet@webonyx.com>

ENV COMPOSER_VERSION 1.2.1

# install the PHP extensions we need
RUN apt-get update && apt-get install -y supervisor libapache2-mod-xsendfile git \
    libpng12-dev libjpeg-dev libmcrypt-dev libfreetype6-dev libmemcached-dev libgearman-dev uuid-dev \
    zlib1g-dev libicu-dev \
    && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-configure intl \
	&& docker-php-ext-install gd intl pdo_mysql opcache iconv mcrypt \
	&& apt-get clean && apt-get autoremove -q \
	&& rm -rf /usr/share/doc /usr/share/man /tmp/*

RUN pecl install memcached gearman uuid && docker-php-ext-enable memcached gearman uuid

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

RUN a2enmod rewrite expires

COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY php.ini /usr/local/etc/php/php.ini

RUN adduser www-data sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers


RUN mkdir -p /var/www/html && \
    chown -R www-data /var/www

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');" && \
    php -r "copy('https://composer.github.io/installer.sig', '/tmp/composer-setup.sig');" && \
    php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" && \
    php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer  --version=$COMPOSER_VERSION && \
    php -r "unlink('/tmp/composer-setup.php');" && \
    composer global require "hirak/prestissimo:^0.3" --update-no-dev


EXPOSE 80 7001

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]