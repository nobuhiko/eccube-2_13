<?php
$url = parse_url(getenv('DATABASE_URL'));

exec("heroku pg:reset DATABASE --confirm ".getenv('HEROKU_APP_NAME'));
exec("heroku config:set DB=pgsql");
exec("heroku config:set DBSERVER=".$url['host']);
exec("heroku config:set DBNAME=".substr($url['path'], 1));
exec("heroku config:set USER=".$url['user']);
exec("heroku config:set DBPASS=".$url['pass']);
exec("heroku config:set HTTP_URL=http://".getenv('HEROKU_APP_NAME').".herokuapp.com");
exec("heroku config:set HTTPS_URL=https://".getenv('HEROKU_APP_NAME').".herokuapp.com");

exec("cp ./tests/config.php ./data/config/config.php");
exec("sh ./eccube_install.sh heroku");

