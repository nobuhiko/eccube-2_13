<?php
$url = parse_url(getenv('DATABASE_URL'));

putenv("DB=pgsql");
putenv("DBSERVER=".$url['host']);
putenv("DBNAME=".substr($url['path'], 1));
putenv("USER=".$url['user']);
putenv("DBPASS=".$url['pass']);
putenv("HTTP_URL=http://".getenv('HEROKU_APP_NAME').".herokuapp.com");
putenv("HTTPS_URL=http://".getenv('HEROKU_APP_NAME').".herokuapp.com");

exec("heroku pg:reset DATABASE --confirm ".getenv('HEROKU_APP_NAME'));
exec("cp ./tests/config.php ./data/config/config.php");
exec("sh ./eccube_install.sh heroku");

