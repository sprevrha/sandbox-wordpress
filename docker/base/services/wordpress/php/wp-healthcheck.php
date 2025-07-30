<?php
// This file is part of the WordPress Docker setup.
// It is used to check the health of the WordPress installation.
// If the database is not accessible, it will exit with a non-zero status.
// Get the WordPress installation directory from the APP_DIR environment variable
$appDir = getenv('APP_DIR') ?: '/var/www/html';

require_once($appDir . '/wp-load.php');

if (function_exists('wp_db_check')) {
    $db_check = wp_db_check();
    if (is_wp_error($db_check)) {
        exit(1);
    }
}

exit(0);
?>
