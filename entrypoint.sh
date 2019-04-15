#!/bin/bash
#set -e

if [[ "$@" = *bash* ]]; then
  exec "$@"
  exit 0
fi

[[ -f /pre-entrypoint.sh ]] && . /pre-entrypoint.sh

chown -R www-data:www-data /var/www/html/{config,tao/views/locales,data}

for (( i=1; i<=${TIMEOUT:-10}; i++ )); do nc -zw1 ${DB_HOST?} ${DB_PORT:-3306} && break || sleep 1; done

LOCAL_NAMESPACE=${LOCAL_NAMESPACE:-http://namespace/local.rdf}

gosu www-data php tao/scripts/taoInstall.php \
--db_driver pdo_mysql \
--db_host ${DB_HOST?} \
--db_name ${DB_NAME?} \
--db_user ${DB_USER?} \
--db_pass ${DB_PASS} \
--module_namespace ${LOCAL_NAMESPACE?} \
--module_url ${ROOT_URL?} \
--user_login ${BOOSTRAP_ADMIN_USERNAME:-admin} \
--user_pass ${BOOSTRAP_ADMIN_PASSWORD:-someTaoP4sss} \
-e taoCe -v

escapeRegex() {
  sed 's/[][/\\*.$^{}&|+]/\\&/g' <<<"$1" | sed "s/'/\\\\\\\'/g"
}

sed -i "s/define('LOCAL_NAMESPACE','[^']*');/define('LOCAL_NAMESPACE','$(escapeRegex ${LOCAL_NAMESPACE?})');/" /var/www/html/config/generis.conf.php
sed -i "s/define('ROOT_URL','[^']*');/define('ROOT_URL','$(escapeRegex ${ROOT_URL?})');/" /var/www/html/config/generis.conf.php
sed -i "s/define('GENERIS_INSTANCE_NAME','[^']*');/define('GENERIS_INSTANCE_NAME','$(escapeRegex ${INSTANCE_NAME:-tao})');/" /var/www/html/config/generis.conf.php
sed -i "s/define('GENERIS_SESSION_NAME','[^']*');/define('GENERIS_SESSION_NAME','$(escapeRegex ${SESSION_NAME:-tao})');/" /var/www/html/config/generis.conf.php
sed -i "s/define('DEFAULT_LANG','[^']*');/define('DEFAULT_LANG','$(escapeRegex ${DEFAULT_LANG:-en-US})');/" /var/www/html/config/generis.conf.php
sed -i "s/define('DEFAULT_ANONYMOUS_INTERFACE_LANG','[^']*');/define('DEFAULT_ANONYMOUS_INTERFACE_LANG','$(escapeRegex ${DEFAULT_ANONYMOUS_INTERFACE_LANG:-en-US})');/" /var/www/html/config/generis.conf.php
sed -i "s/define('DEBUG_MODE', [a-z]*);/define('DEBUG_MODE', ${DEBUG_MODE:-false});/" /var/www/html/config/generis.conf.php
sed -i "s/define('TIME_ZONE','[^']*');/define('TIME_ZONE','$(escapeRegex ${TIME_ZONE:-UTC})');/" /var/www/html/config/generis.conf.php

sed -i "s/^ *'host' => '[^']*'/'host' => '$(escapeRegex ${DB_HOST?})'/" /var/www/html/config/generis/persistences.conf.php
sed -i "s/^ *'dbname' => '[^']*'/'dbname' => '$(escapeRegex ${DB_NAME?})'/" /var/www/html/config/generis/persistences.conf.php
sed -i "s/^ *'user' => '[^']*'/'user' => '$(escapeRegex ${DB_USER?})'/" /var/www/html/config/generis/persistences.conf.php
sed -i "s/^ *'password' => '[^']*'/'password' => '$(escapeRegex ${DB_PASS?})'/" /var/www/html/config/generis/persistences.conf.php

SERVERNAME=${ROOT_URL#*//}
SERVERNAME=${SERVERNAME%%/*}
echo "ServerName $SERVERNAME" > /etc/apache2/sites-enabled/fqdn.conf

[[ -f /post-entrypoint.sh ]] && . /post-entrypoint.sh

exec "$@"
