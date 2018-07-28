<?php
$url = parse_url(getenv('DATABASE_URL'));

print getenv('HEROKU_APP_NAME');
print $url['host'];
print $url['path'];
print $url['user'];
print $url['pass'];
