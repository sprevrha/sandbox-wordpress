<?php
/**
 * The base configuration for WordPress
 */
// a helper function to lookup "env_FILE", "env", then fallback
if (!function_exists('getenv_docker')) {
    // https://github.com/docker-library/wordpress/issues/588 (WP-CLI will load this file 2x)
    function getenv_docker($env, $default) {
        if ($fileEnv = getenv($env . '_FILE')) {
            return rtrim(file_get_contents($fileEnv), "\r\n");
        }
        else if (($val = getenv($env)) !== false) {
            return $val;
        }
        else {
            return $default;
        }
    }
}
ini_set('WP_DEBUG', getenv_docker('WP_DEBUG', true));
ini_set('WP_DEBUG_LOG', getenv_docker('WP_DEBUG_LOG', true));
// ** Database settings from environment variables ** //
// The official image passes these from env vars to the generated wp-config.php
// But we can define them directly here as well, using our env vars.
if (!defined('DB_NAME')) {
    define('DB_NAME', getenv('WORDPRESS_DB_NAME'));
}
if (!defined('DB_USER')) {
    define('DB_USER', file_get_contents(getenv('WORDPRESS_DB_USER_FILE')));
}
if (!defined('DB_PASSWORD')) {
    define('DB_PASSWORD', file_get_contents(getenv('WORDPRESS_DB_PASSWORD_FILE')));
}
if (!defined('DB_HOST')) {
    define('DB_HOST', getenv('WORDPRESS_DB_HOST'));
}
if (!defined('DB_CHARSET')) {
    define('DB_CHARSET', getenv('WORDPRESS_DB_CHARSET') ?: 'utf8mb4');
}
if (!defined('DB_COLLATE')) {
    define('DB_COLLATE', getenv('WORDPRESS_DB_COLLATE') ?: 'utf8mb4_unicode_ci');
}
$table_prefix = getenv('WORDPRESS_TABLE_PREFIX' ?: 'wp_');
// REDIS Configuration
if (!defined('WP_REDIS_HOST')) {
    define('WP_REDIS_HOST', getenv('WP_REDIS_HOST') ?: 'redis');
}
if (!defined('WP_REDIS_PORT')) {
    define('WP_REDIS_PORT', getenv('WP_REDIS_PORT') ?: 6379);
}
if (!defined('WP_REDIS_PASSWORD')) {
    define('WP_REDIS_PASSWORD', file_get_contents(getenv('WP_REDIS_PASSWORD_FILE')));
}
// ** Salts, keys, and other secrets ** //
// https://api.wordpress.org/secret-key/1.1/salt/
// Generate by wp-cli with the following command:   wp-cli core generate-secret-key
define('AUTH_KEY',       'P+@HyMk|b)1?lMe}>]0Yit-CSoJFTkZN^`M~nD0<(qTu(+%w}n5_|7MN<0ts:7sK');
define('SECURE_AUTH_KEY',  '&D>rmjV+?meh@n%:SP2B)bX&`OJ&*Ay7PY6pz/!sJ|23Z6Eow%$/9VEtN|x8_fU=');
define('LOGGED_IN_KEY',    '[4oXIC{-]3dd<#g;U36!Rp81HFu-)`CSLLGnlpc+pAhh|D4a-ju^w|R[p6jaOA%Q');
define('NONCE_KEY',        ')GxrUxLjJdF#a<Th(Bp9|qiD:|RLuO.XiDOC~KM8Y=can?S^,glEhFlE*-nN7Iv=');
define('AUTH_SALT',        '%^:EG7*!N Oe5M@i[+4J-_wKsoRKzu75s%YT@n0$r|4hQhExE$=kLv;.lNR(u-_:');
define('SECURE_AUTH_SALT', '{CLf,@-XnKVO6nP8g +gLn|D1u~)4&Hj0j@e;p-h5di-C+MfBxYwo`RR%D@WpAeK');
define('LOGGED_IN_SALT',   '/`>Lyw?X/lm/i;j+/LY@>VdDCy,~Z)31Sl.JBvF`xu]5ovw-DOph>h$q=/W8==6%');
define('NONCE_SALT',       '!s/gU 0/frQvWCSO5T-5Da 31N@W)h=pS+c~hK-t6BNV2]b4Ty;=(I5VxKB$=P|K');

// ** WordPress Environment Constants from environment variables ** //
if (!defined('WP_HOME')) {
    define('WP_HOME', getenv('WP_HOME') ?: 'https://localhost');
}
if (!defined('WP_SITEURL')) {
    define('WP_SITEURL', getenv('WP_SITEURL') ?: 'https://localhost');
}
// Sets the main WordPress language
// 'de_DE', 'en_US', 'fr_FR', 'es_ES', etc.
if (!defined('WPLANG')) {
    define('WPLANG', getenv('WP_LANG') ?: 'en_US');
}
// ** Wordpress debugging & logging ** //
if (!defined('WP_ENVIRONMENT_TYPE')) {
    define('WP_ENVIRONMENT_TYPE', getenv('WP_ENVIRONMENT_TYPE') ?: 'production');
}
if (!defined('WP_DEBUG')) {
    define('WP_DEBUG', getenv('WP_DEBUG') ?: false);
}
if (!defined('WP_DEBUG_DISPLAY')) {
    define('WP_DEBUG_DISPLAY', getenv('WP_DEBUG_DISPLAY') ?: false);
}
if (!defined('WP_DEBUG_LOG')) {
    define('WP_DEBUG_LOG', getenv('WP_DEBUG_LOG'));
}
// General Security & Optimization
if (!defined('WP_CACHE')) {
    define('WP_CACHE', getenv('WP_CACHE') ?: false);
}
if (!defined('WP_CACHE_KEY_SALT')) {
    define('WP_CACHE_KEY_SALT', getenv('WP_CACHE_KEY_SALT'));
}
if (!defined('DISABLE_WP_CRON')) {
    define('DISABLE_WP_CRON', getenv('DISABLE_WP_CRON'));
}
if (!defined('REST_API_DISABLED')) {
    define('REST_API_DISABLED', getenv('REST_API_DISABLED'));
}
if (!defined('HEARTBEAT_DISABLED')) {
    define('HEARTBEAT_DISABLED', getenv('HEARTBEAT_DISABLED'));
}
if (!defined('AUTOMATIC_UPDATER_DISABLED')) {
    define('AUTOMATIC_UPDATER_DISABLED', getenv('AUTOMATIC_UPDATER_DISABLED'));
}
if (!defined('FORCE_SSL_LOGIN')) {
    define('FORCE_SSL_LOGIN', getenv('FORCE_SSL_LOGIN'));
}
if (!defined('DISALLOW_FILE_EDIT')) {
    define('DISALLOW_FILE_EDIT', getenv('DISALLOW_FILE_EDIT'));
}
if (!defined('WP_ALLOW_REPAIR')) {
    define('WP_ALLOW_REPAIR', getenv('WP_ALLOW_REPAIR'));
}
if (!defined('WP_POST_REVISIONS')) {
    define('WP_POST_REVISIONS', getenv('WP_POST_REVISIONS'));
}
if (!defined('AUTOSAVE_INTERVAL')) {
    define('AUTOSAVE_INTERVAL', getenv('AUTOSAVE_INTERVAL'));
}
if (!defined('WP_MEMORY_LIMIT')) {
    define('WP_MEMORY_LIMIT', getenv('WP_MEMORY_LIMIT') ?: '256M');
}
if (!defined('WP_MAX_MEMORY_LIMIT')) {
    define('WP_MAX_MEMORY_LIMIT', getenv('WP_MAX_MEMORY_LIMIT' ?: '512M'));
}
if (!defined('DISALLOW_FILE_MODS')) {
	define('DISALLOW_FILE_MODS', getenv('DISALLOW_FILE_MODS') ?: false);
}
// Reverse Proxy SSL Detection (Corrected PHP syntax)
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}
// Alternative: For Load Balancer
if (isset($_SERVER['HTTP_X_FORWARDED_SSL']) && $_SERVER['HTTP_X_FORWARDED_SSL'] === 'on') {
    $_SERVER['HTTPS'] = 'on';
}
if ($configExtra = getenv('WORDPRESS_CONFIG_EXTRA' ?: '')) {
    eval($configExtra);
}

// The client library to use (phpredis or predis). phpredis is a C extension
// that offers better performance.
if (!defined('WP_REDIS_CLIENT')) {
    define('WP_REDIS_CLIENT', getenv('WP_REDIS_CLIENT') ?: 'phpredis');
}
if (!defined('WP_REDIS_DATABASE')) {
    define('WP_REDIS_DATABASE', getenv('WP_REDIS_DATABASE') ?: 0);
}
if (!defined('WP_REDIS_TIMEOUT')) {
    define('WP_REDIS_TIMEOUT', getenv('WP_REDIS_TIMEOUT') ?: 1);
}
if (!defined('WP_REDIS_READ_TIMEOUT')) {
    define('WP_REDIS_READ_TIMEOUT', getenv('WP_REDIS_READ_TIMEOUT'));
}
if (!defined('WP_REDIS_MAXTTL')) {
    define('WP_REDIS_MAXTTL', getenv('WP_REDIS_MAXTTL') ?: 86400);
}
if (!defined('WP_REDIS_SCHEME')) {
    define('WP_REDIS_SCHEME', getenv('WP_REDIS_SCHEME') ?: 'tcp');
}
/* That's all, stop editing! Happy publishing. */
/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
