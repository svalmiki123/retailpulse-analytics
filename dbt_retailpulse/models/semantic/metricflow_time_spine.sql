models:
  - name: metricflow_time_spine
    description: "Time spine required by MetricFlow for time-series metrics."
    config:
      meta:
        time_spine: true
    columns:
      - name: date_day
        description: "One row per calendar date"
        granularity: day