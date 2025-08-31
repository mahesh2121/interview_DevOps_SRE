The images you've provided illustrate how labels are used in Prometheus to identify and track time-series data. Here's a breakdown of the key concepts:

Default Labels:

    Prometheus assigns two default labels to every metric:
        instance: Represents the address of the target being scraped (e.g., 192.168.1.168:9100).
        job: Identifies the group or role of the target (e.g., node).

Example:

    node_boot_time_seconds{instance="192.168.1.168:9100", job="node"}
        This metric tracks the boot time of a node.
        The instance label specifies the address of the node being monitored.
        The job label indicates that this is a metric collected from a node.

Configuration:

    The configuration section (shown in the image) defines how Prometheus scrapes data from targets.
        job_name: Specifies the job label for the target.
        scheme: Defines the protocol used for scraping (e.g., https).
        targets: Lists the addresses of the targets to scrape.

Benefits of Labels:

    Granular Monitoring: Labels allow you to track data for specific instances, jobs, or other dimensions, enabling fine-grained monitoring.
    Flexible Querying: Prometheus's query language (PromQL) allows you to filter and aggregate data based on label values.
    Data Organization: Labels help organize and categorize metrics, making it easier to understand and manage your monitoring data.

In Summary:

Labels are a fundamental concept in Prometheus. They provide a structured way to identify and track time-series data, enabling powerful monitoring and alerting capabilities. By understanding how labels are used and configured, you can effectively monitor and manage your systems using Prometheus.