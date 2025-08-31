Basic newrelic.ini Configuration

Here is a minimal example of a newrelic.ini file:

[newrelic]
# New Relic License Key (Required)
license_key = YOUR_NEW_RELIC_LICENSE_KEY

# Application Name (Shown in New Relic Dashboard)
app_name = My Python Application

# Logging Level (INFO, DEBUG, WARNING, ERROR)
log_level = info

# Enable High-Security Mode (Optional)
high_security = false

# Enable Distributed Tracing (For Tracing Requests Across Services)
distributed_tracing.enabled = true

# Enable Logging to a File (Optional)
log_file = newrelic-agent.log
log_file_path = /var/log/newrelic/

# Transaction Tracing (Control Performance Overhead)
transaction_tracer.enabled = true
transaction_tracer.transaction_threshold = apdex_f
transaction_tracer.record_sql = obfuscated
transaction_tracer.stack_trace_threshold = 0.5

# Error Collection (Capture Errors in New Relic)
error_collector.enabled = true

# Capture Detailed Database Query Traces
slow_sql.enabled = true
slow_sql.explain_enabled = true
slow_sql.explain_threshold = 0.5

# Distributed Tracing for Cross-Service Requests
distributed_tracing.enabled = true

# Enable Custom Metrics
custom_insights_events.enabled = true

Key Configuration Options
Setting	Description
license_key	Required. Your New Relic license key.
app_name	The application name that appears in the New Relic dashboard.
log_level	Logging level (debug, info, error).
log_file	Name of the log file.
log_file_path	Path where logs are stored.
distributed_tracing.enabled	Enables tracing across microservices.
transaction_tracer.enabled	Captures slow transactions for debugging.
transaction_tracer.transaction_threshold	Defines slow transaction threshold (apdex_f for auto threshold).
error_collector.enabled	Captures unhandled errors.
slow_sql.enabled	Logs slow SQL queries.
custom_insights_events.enabled	Enables custom metric reporting.
How to Use newrelic.ini in Your Application

    Install the New Relic Python Agent

pip install newrelic

Run the Application with New Relic

    NEW_RELIC_CONFIG_FILE=newrelic.ini newrelic-admin run-program python app.py

Advanced Features

✅ Custom Instrumentation → Manually track performance in code.
✅ Distributed Tracing → See requests flowing across services.
✅ APM Dashboards → Monitor transactions, errors, and response times.