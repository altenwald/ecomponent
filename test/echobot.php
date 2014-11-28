<?php

$xmlel = $_MESSAGE['xmlel'];

$from = $xmlel['attrs']['from'];
$to = $xmlel['attrs']['to'];

$xmlel['attrs']['from'] = $to;
$xmlel['attrs']['to'] = $from;

ecomponent_send_message($xmlel);
