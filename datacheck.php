<?php
$db = new PDO('mysql:host='.$_ENV['DB_HOST'].';dbname='.$_ENV['DB_NAME'].';', $_ENV['DB_USER'], $_ENV['DB_PASS']);
$st = $db->query('show tables');
$r = $st->fetchAll(PDO::FETCH_ASSOC);
if (count($r)>0) die('Data exists. No installation.');
