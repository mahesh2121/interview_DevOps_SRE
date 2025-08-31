# Node.js – newrelic.js Configuration

For Node.js applications, New Relic uses a newrelic.js configuration file.
Installation

npm install newrelic --save

Basic Configuration (newrelic.js)

Create a newrelic.js file in your project root:

exports.config = {
  app_name: ['My Node.js App'],
  license_key: 'YOUR_NEW_RELIC_LICENSE_KEY',
  logging: {
    level: 'info',
    filepath: 'stdout'  // Use 'stdout' for console logging
  },
  distributed_tracing: {
    enabled: true
  },
  transaction_tracer: {
    enabled: true,
    transaction_threshold: 'apdex_f'
  },
  error_collector: {
    enabled: true
  },
  slow_sql: {
    enabled: true
  }
};

Start Application with New Relic

NEW_RELIC_APP_NAME="My Node.js App" NEW_RELIC_LICENSE_KEY="YOUR_NEW_RELIC_LICENSE_KEY" node -r newrelic app.js

# PHP – newrelic.ini Configuration

For PHP applications, New Relic is installed as a PHP extension.
Installation

wget -O - https://download.newrelic.com/php_agent/release/newrelic-install.sh | bash
sudo newrelic-install install

Configuration (newrelic.ini)

Modify the /etc/php.d/newrelic.ini file:

[newrelic]
license_key = "YOUR_NEW_RELIC_LICENSE_KEY"
app_name = "My PHP App"
log_level = "info"
daemon.logfile = "/var/log/newrelic/newrelic-daemon.log"
newrelic.transaction_tracer.enabled = true
newrelic.error_collector.enabled = true
newrelic.slow_sql.enabled = true

Restart Web Server

sudo systemctl restart apache2  # For Apache
sudo systemctl restart php-fpm  # For PHP-FPM

# Laravel (PHP Framework) – newrelic.ini Configuration

Laravel (built on PHP) follows the same setup as PHP.
Installation

    Install the New Relic PHP agent:

wget -O - https://download.newrelic.com/php_agent/release/newrelic-install.sh | bash
sudo newrelic-install install

Add the New Relic PHP extension in newrelic.ini:

[newrelic]
license_key = "YOUR_NEW_RELIC_LICENSE_KEY"
app_name = "My Laravel App"
log_level = "info"
newrelic.transaction_tracer.enabled = true
newrelic.error_collector.enabled = true
newrelic.slow_sql.enabled = true

Restart Apache or PHP-FPM:

sudo systemctl restart apache2
sudo systemctl restart php-fpm

Optional: Manually monitor Laravel transactions in AppServiceProvider.php:

    use Illuminate\Support\Facades\Log;

    public function boot() {
        if (extension_loaded('newrelic')) {
            newrelic_name_transaction(request()->path());
        }
    }

# Summary Table
Language/Framework	Config File	Key Setup Steps
Node.js	newrelic.js	Install newrelic package, set env vars, require in app
PHP	newrelic.ini	Install New Relic PHP agent, update newrelic.ini, restart server
Laravel	newrelic.ini	Same as PHP, optionally track transactions in AppServiceProvider.php

Would you like help with a specific framework or troubleshooting setup? 🚀