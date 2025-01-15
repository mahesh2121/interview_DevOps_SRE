PromQL: A Deep Dive into Prometheus Query Language

Prometheus is an open-source monitoring and alerting toolkit designed for reliability and scalability. One of the key features that make Prometheus powerful is its ability to query metrics using PromQL (Prometheus Query Language). PromQL allows you to access and manipulate time-series data, which can then be visualized on dashboards or used in alerting rules to notify administrators about issues in real time.

In this article, we will explore PromQL in-depth, discussing its structure, operators, functions, and practical examples to give you a comprehensive understanding of how to use PromQL in a production environment.
What is PromQL?

PromQL stands for Prometheus Query Language, and it is the primary tool for querying and interacting with the data stored in Prometheus. PromQL queries can be used to:

    Retrieve and display metrics for analysis.
    Create custom visualizations for monitoring.
    Set up alerting rules to trigger notifications based on certain conditions.

PromQL is essential to work effectively with Prometheus, whether you're building dashboards or setting up automated alerts.
Key Concepts of PromQL

Before diving into actual PromQL queries, it’s important to understand some foundational concepts and components. Below is a breakdown of the most important aspects of PromQL.


1. Expression Data Structure

In PromQL, metrics are represented as time-series data. Each time series consists of:

    A metric name: The name of the metric being collected (e.g., http_requests_total, cpu_usage_seconds_total).
    Labels: Key-value pairs that provide additional context for the metric (e.g., instance="server1", status="200").
    Timestamp: The time when the metric was collected.
    Value: The value of the metric at a specific point in time.

For example, consider the metric http_requests_total{method="GET", status="200"}. This would represent the total number of HTTP requests with the GET method and 200 status.

2. Selectors & Modifiers

In PromQL, selectors allow you to specify which time series you want to query. The most common selector is the metric name, but you can also use label filters to narrow down your query to specific subsets of data.
Example:

http_requests_total{method="GET"}

This query returns the http_requests_total metric for all instances where the method label equals GET.

You can also use modifiers to control how data is returned. For example, using the rate function to calculate the per-second rate of a counter metric:

rate(http_requests_total{method="GET"}[5m])

This returns the rate of http_requests_total over the last 5 minutes.

3. Operators & Functions

PromQL supports a variety of operators and functions for manipulating time-series data.
Common PromQL Operators:

    Arithmetic Operators: +, -, *, /

    These operators allow you to perform mathematical operations on time-series data.

http_requests_total{method="GET"} / http_requests_total{method="POST"}

This query divides the http_requests_total for the GET method by the POST method, providing a ratio of GET to POST requests.

Comparison Operators: ==, =~, !~, !=

These operators allow you to filter time-series data based on conditions.

http_requests_total{status=~"2.."}

This query selects all HTTP request metrics where the status label starts with 2 (indicating successful responses).

Boolean Operators: and, or

These operators allow you to combine multiple time series.

    http_requests_total{method="GET"} and http_requests_total{status="200"}

    This query returns the http_requests_total metric where both the method is GET and the status is 200.

Functions:

PromQL supports a wide range of functions for advanced queries, such as rate(), avg(), max(), min(), sum(), and more.

Example with avg():

avg(http_requests_total{status="200"}) by (method)

This query calculates the average number of HTTP requests with a 200 status, grouped by the method label.


4. Vector Matching

Vector matching is a key concept in PromQL when dealing with queries involving multiple metrics. Vector matching allows you to match time series based on labels.

    One-to-one matching: If you are comparing two time series that have the same labels, Prometheus will match them directly.

    Many-to-one matching: If one metric has more labels than the other, you can use the on() or group_left() modifier to match metrics based on the shared labels.

Example:

http_requests_total{method="GET"} / http_requests_total{method="POST"} on (status)

This query compares the GET and POST HTTP request counts, ensuring that only time series with the same status label are compared.
5. Aggregators

Aggregators are used to perform calculations over time series data, such as finding the sum, average, or maximum value. These are useful when you need to reduce or summarize large amounts of data.
Common Aggregators:

    sum(): Sums all the values across a group of time series.
    avg(): Returns the average of the time series.
    max(): Finds the maximum value.
    min(): Finds the minimum value.

Example:

sum(rate(http_requests_total[5m])) by (method)

This query calculates the total rate of HTTP requests over the last 5 minutes, grouped by the method label.
6. Subqueries

Subqueries allow you to perform queries on results of other queries. You can think of a subquery as a query inside another query.
Example:

avg(rate(http_requests_total[5m])) by (method) [1h:]

In this example, the avg() function calculates the average rate of HTTP requests for each method over the last 1 hour.
7. Histogram/Summary

Histograms and Summaries in Prometheus allow you to track the distribution of data over a range of values, such as request duration or response size. They are crucial for performance analysis.

PromQL provides functions for working with histograms and summaries, such as histogram_quantile(), which is used to calculate quantiles from histograms.
Example:

histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

This query calculates the 95th percentile of HTTP request duration over the last 5 minutes.
Practical Example of PromQL Queries

Let’s go over some real-world examples to solidify your understanding of PromQL.
1. Average CPU Usage Over Time

To get the average CPU usage across all instances for the last 10 minutes, use the following query:

avg(rate(cpu_usage_seconds_total[10m])) by (instance)

This query calculates the average CPU usage for each instance over the past 10 minutes.
2. Error Rate Monitoring

You may want to monitor the error rate for your application. The following query calculates the ratio of failed HTTP requests (status=5xx) to total HTTP requests:

sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))

This gives you the percentage of 5xx errors compared to the total HTTP requests in the last 5 minutes.
3. Alerting on High Latency

Suppose you want to create an alert for HTTP request latency exceeding 1 second. You can use the following query:

http_request_duration_seconds{status="200"} > 1

You can set this query in your alerting rules to notify you when the request duration exceeds 1 second.
Conclusion

PromQL is a powerful query language that provides the flexibility and functionality to monitor and alert on a wide range of metrics. By mastering PromQL, you can create sophisticated monitoring solutions that help you keep track of your infrastructure's health, performance, and efficiency.

With PromQL’s robust support for operators, functions, aggregators, and time-series data manipulation, you can gain valuable insights into your containerized or cloud-native environments. Whether you are building dashboards or setting up alerting rules, PromQL is an essential skill for Prometheus users.

To further refine your understanding, experiment with different queries, and dive deeper into Prometheus documentation to uncover more advanced use cases.