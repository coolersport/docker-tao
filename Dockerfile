FROM php:7.1.21-apache-stretch

COPY entrypoint.sh datacheck.php /

# update and install required tools
RUN apt update && \
    apt upgrade -y && \
    apt install -y git netcat && \
# run on non-privilege ports
    sed -i 's/Listen 80$/Listen 8080/g' /etc/apache2/ports.conf && \
    sed -i 's/Listen 443$/Listen 8443/g' /etc/apache2/ports.conf && \
# install gosu
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
    curl -fsLo /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.10/gosu-$dpkgArch" && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true && \
# install composer
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer && \
# tao-specific configuration
    sed -ie "/<Directory \/var\/www\/>/,/<\/Directory>/  s/AllowOverride None/AllowOverride All/" /etc/apache2/apache2.conf && \
# install required modules
    apt install -y zlib1g-dev && \
    docker-php-ext-install zip && \
    docker-php-ext-install opcache && \
    docker-php-ext-install pdo_mysql && \
    ln -s /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/rewrite.load && \
    pecl install xdebug && \
    docker-php-ext-enable xdebug && \
# install tao
    git clone https://github.com/oat-sa/package-tao.git /var/www/html && \
    cd /var/www/html && \
    chown -R www-data:www-data . && \
    gosu www-data composer install && \
    curl -fsLo /tmp/mathjax.sh https://hub.taotesting.com/resources/taohub-articles/articles/third-party/MathJax_Install_TAO_3x.sh && \
    gosu www-data bash /tmp/mathjax.sh && \
# tweaks
    sed -i 's/^\$installDetails =/if(tao_install_utils_System::isTAOInstalled()) die();require "datacheck.php";\$installDetails =/' /var/www/html/tao/scripts/taoInstall.php && \
    mv /datacheck.php /var/www/html/tao/scripts && \
    chown www-data:www-data /var/www/html/tao/scripts/datacheck.php && \
# change MyISAM to InnoDB
    for f in `grep -lr MyISAM /var/www/html/*`; do sed -i 's/MyISAM/InnoDB/g' $f; done && \
# entrypoint
    chmod +x /entrypoint.sh && \
# cleanup
    find /var/www/html -type d -name .git -prune -exec rm -rf {} ';' && \
    apt remove -y git && \
    apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
