<?php
// Zabbix GUI configuration file
global $DB;

$DB['TYPE']     = 'MYSQL';
$DB['SERVER']   = 'localhost';
$DB['PORT']     = '0';
$DB['DATABASE'] = 'zabbix';
$DB['USER']     = 'zabbix';
$DB['PASSWORD'] = 'zabbix_pass';

// SCHEMA is relevant only for IBM_DB2 database
$DB['SCHEMA'] = '';

$ZBX_SERVER      = '172.16.100.81';
$ZBX_SERVER_PORT = '10051';
$ZBX_SERVER_NAME = 'zabbix.mall.com';

$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
?>
