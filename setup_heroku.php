<?php
$url = parse_url(getenv('DATABASE_URL'));

$stdout= fopen('php://stdout', 'w');
fwrite( $stdout, print_r($url)."\n" );

$cmd = 'export DB_SERVER="'.$url['host'].'";';
$cmd .= 'export DB_USER="'.$url['user'].'";';
$cmd .= 'export DB_PASSWORD="'.$url['pass'].'";';
$cmd .= 'export DB_NAME="'.substr($url['path'], 1).'";';

$app = getenv('HEROKU_APP_NAME');
$cmd .= 'export HTTP_URL="http://'.$app.'.herokuapp.com/";';
$cmd .= 'export HTTPS_URL="https://'.$app.'.herokuapp.com/";';

$cmd = ' sh ./eccube_install.sh heroku';

$stdout= fopen('php://stdout', 'w');
fwrite( $stdout, $cmd."\n" );

echo "<pre>".shell_exec($cmd)."</pre>";
