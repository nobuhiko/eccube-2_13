<?php
$url = parse_url(getenv('DATABASE_URL'));

define('ECCUBE_INSTALL', 'ON');
define('ROOT_URLPATH', '/');
define('DOMAIN_NAME', '');
define('DB_TYPE', 'pgsql');
define('DB_USER', $url['user']);
define('DB_PASSWORD', $url['pass']);
define('DB_SERVER', $url['host']);
define('DB_NAME', substr($url['path'], 1));
