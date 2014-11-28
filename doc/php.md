PHP
===

**IMPORTANT**: This implementation is experimental, use with caution.

This is a way to build the components logic in PHP scripts. The configuration is as you can see in the configuration page. And the code you can write is about the reception of the information.

An echo bot example:

```erlang
% Configuration is
{message_processor, {php, "echo.php"}}
```

The file should be in the `priv` directory for your application.

```php
<?php

lager('info', "received message: " . $_MESSAGE['children']['body']['cdata']);

$from = $_MESSAGE['attrs']['from'];
$to = $_MESSAGE['attrs']['to'];

$_MESSAGE['attrs']['from'] = $to;
$_MESSAGE['attrs']['to'] = $from;

ecomponent_send_message($_MESSAGE);

```
