#!/bin/sh
# Combined health check script for WordPress and PHP-FPM
# Check PHP-FPM - this ensures that the PHP-FPM service is running and accessible
# and works even if WordPress is not fully configured yet.
FASTCGI_PORT=${FASTCGI_PORT:-9000}

# Check PHP-FPM
nc -z localhost $FASTCGI_PORT
if [ $? -ne 0 ]; then
  echo "PHP-FPM health check failed on port $FASTCGI_PORT"
  exit 1
fi

# Check WordPress Core Files
# This checks if the WordPress core files are present and accessible.
# It ensures that the WordPress installation is complete and can serve content.
# It works even if the WordPress installation is not fully configured yet.
test -f /var/www/html/index.php
if [ $? -ne 0 ]; then
  echo "WordPress core files health check failed"
  exit 1
fi

# Run WordPress Health Check Script
# For this, WordPress must be installed and configured.
if [ -f /var/www/html/wp-config.php ]; then
  # Run WordPress Health Check Script
  php ${WP_PHP_EXTRA}/wp-healthcheck.php
  if [ $? -ne 0 ]; then
    echo "WordPress health check script failed"
    exit 1
  fi
else
  echo "WordPress configuration file not found - passing"
fi



# All checks passed
exit 0
