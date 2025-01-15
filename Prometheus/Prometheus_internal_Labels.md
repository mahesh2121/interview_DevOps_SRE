Prometheus Internal Labels

This image illustrates the concept of internal labels in Prometheus.

Key Points:

    Metric Name as a Label: In Prometheus, the metric name itself is treated as a label. This allows for consistent handling and querying of metrics.

    Internal Label Representation: Labels surrounded by curly braces {} are considered internal to Prometheus. This means they are part of the metric's definition and are used for internal processing.

Example:

    node_cpu_seconds_total{cpu="0"}

    In this example, node_cpu_seconds_total is the metric name, and it is treated as a label with the value node_cpu_seconds_total. The cpu label is used to distinguish between different CPU cores.

Benefits:

    Consistent Handling: Treating the metric name as a label ensures consistent handling and querying across all metrics.
    Internal Processing: Internal labels are used by Prometheus for various internal operations, such as filtering, aggregation, and storage.

In Summary:

Internal labels in Prometheus provide a consistent and structured way to represent and manage metrics. By understanding how internal labels work, you can write more effective PromQL queries and leverage the full power of Prometheus for monitoring and alerting.