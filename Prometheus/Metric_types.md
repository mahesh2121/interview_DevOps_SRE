# Prometheus Metrics Types

Prometheus uses different metric types to collect and store time-series data. Each metric type serves a specific purpose for monitoring and alerting. Here are the primary metric types in Prometheus:

## 1. **Counter**

A **Counter** is a metric type that represents a value that only increases over time. It is typically used for counting occurrences of events or operations. Once a Counter increases, it cannot decrease (although it can be reset to zero, typically on service restart).

### Use Cases:
- Number of HTTP requests received.
- Number of errors that occurred.
- Number of successful login attempts.

### Example:
```prometheus
# A simple counter for HTTP requests
http_requests_total{method="GET", status="200"} 1023

In this example, http_requests_total is a Counter metric that tracks the total number of HTTP requests with the status 200 using the GET method.

## 2. **Gauge**


A Gauge is a metric that represents a single numerical value that can go up or down. It is used for values that can fluctuate, such as temperature, memory usage, or the number of active connections.
Use Cases:

    Current memory usage.
    Number of active connections.
    Temperature readings.

Example:

# A gauge for current memory usage in MB
memory_usage_bytes{instance="server1"} 2048000

# A gauge for current temperature in Celsius
temperature_celsius 21.5

In this example, memory_usage_bytes is a Gauge metric that tracks the memory usage, and temperature_celsius is a Gauge metric tracking the temperature.

## 3. **Histogram**

A Histogram samples observations (usually things like request durations or response sizes) and counts them in configurable buckets. It is useful for tracking distributions, such as latency or request sizes.

Histograms store:

    The count of observations.
    The sum of all observed values.
    The number of observations that fall into each bucket.

Use Cases:

    Request latency.
    Response size.
    Processing time.

Example:

# A histogram for HTTP request durations
http_request_duration_seconds_bucket{le="0.1", method="GET", status="200"} 23
http_request_duration_seconds_bucket{le="0.2", method="GET", status="200"} 45
http_request_duration_seconds_sum{method="GET", status="200"} 12.34
http_request_duration_seconds_count{method="GET", status="200"} 100

In this example, http_request_duration_seconds_bucket is a Histogram metric tracking the duration of HTTP requests in different latency buckets. http_request_duration_seconds_sum stores the sum of durations, and http_request_duration_seconds_count tracks the total number of requests.


## 4. **Summary**

A Summary is similar to a Histogram in that it also samples observations, but it calculates and provides quantiles (e.g., 90th percentile, 95th percentile) of observed values. It provides a more detailed view of a distribution with quantile calculations.
Use Cases:

    Latency percentiles (e.g., 95th percentile response time).
    Request processing times.
    Application performance metrics that require percentiles.

Example:

# A summary for HTTP request durations
http_request_duration_seconds{quantile="0.5", method="GET", status="200"} 0.123
http_request_duration_seconds{quantile="0.9", method="GET", status="200"} 0.150
http_request_duration_seconds_count{method="GET", status="200"} 100
http_request_duration_seconds_sum{method="GET", status="200"} 12.34

In this example, http_request_duration_seconds is a Summary metric that tracks HTTP request durations and provides quantiles (e.g., 0.5 for 50th percentile, 0.9 for 90th percentile).
Comparison of Metrics
Metric Type	Purpose	Example Use Case Can it decrease?
Counter	Represents a monotonically increasing value.	Count of HTTP requests, number of errors	No
Gauge	Represents a value that can go up or down.	Memory usage, number of active connections	Yes
Histogram	Tracks observations in defined buckets.	Request duration, response size	No
Summary	Samples observations and provides quantiles.	Latency percentiles, processing time	No
Summary of Key Differences

    Counter: Monotonically increasing, counts things like requests or errors.
    Gauge: Values that can go up and down, e.g., temperature, memory usage.
    Histogram: Tracks observations in defined buckets, useful for distributions.
    Summary: Similar to Histogram but also includes quantiles like 95th or 99th percentiles.

Each metric type in Prometheus has its use case, and choosing the correct metric type depends on the data you want to track and how you want to visualize and analyze that data.