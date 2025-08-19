# Tag Filtering in Jaeger SPM

This directory contains configuration examples for Jaeger Service Performance Monitoring (SPM), 
including support for tag filtering in metrics.

## Configuration Files

- `config-spm.yaml`: Standard configuration without tag filtering
- `config-spm-with-tag-filtering.yaml`: Configuration that supports tag filtering in metrics

## Tag Filtering Support

The `config-spm-with-tag-filtering.yaml` file demonstrates how to enable tag filtering in metrics
with the OpenTelemetry Collector. This allows users to filter metrics by tags in the Jaeger UI
and API, just like they can filter traces.

### How It Works

1. **Define Tag Dimensions**: The spanmetrics connector is configured to include tag dimensions
   in the generated metrics.

2. **Propagate Tag Values**: The attributes processor is used to copy tag values from
   resource attributes to span attributes, which are then included in the metrics.

3. **Query with Tags**: Once configured, you can filter metrics with tags using the Jaeger UI
   or API endpoints like: `api/metrics/calls?tag=tag1:value1`

### Configuration Details

```yaml
# Define tag dimensions in the spanmetrics connector
connectors:
  spanmetrics:
    dimensions:
      - name: operation
        default: unknown-operation
      # Add tag dimensions for filtering
      - name: env
        default: ""

# Use the attributes processor to propagate tags
processors:
  attributes:
    actions:
      # Copy resource attributes to span attributes for metrics filtering
      - key: env
        action: insert
        from_attribute: env
```

## Example Usage

To test tag filtering:

1. Start Jaeger with this configuration
2. Send traces with tags as resource attributes
3. Query metrics with tag filters using the Jaeger UI or API

Example API query:
```
http://localhost:16686/api/metrics/calls?service=my-service&tag=tag1:value1
```

## Testing with Docker Compose

To test tag filtering in the Docker Compose environment:
1. Start the docker compose file for tag filtering [docker-compose-tag-filtering.yml](./docker-compose-tag-filtering.yml)
2. This will start jaeger, prometheus, and two trace generator which generate traces from staging and production envs.
3. **Query metrics with tag filters**: Use the metrics API with tag filter parameters
   ```bash
   curl "http://localhost:16686/api/metrics/errors?service=redis&endTs=1755599476047&lookback=300000&quantile=0.95&ratePer=600000&spanKind=server&step=60000&tag=env:staging" | jq
   ```

## Debugging Tips

If tag filtering isn't working as expected:

1. Metrics might take some time to appear, ~1min
2. **Check Prometheus metrics**: Verify that metrics include the tag labels
   ```bash
   curl "http://localhost:9090/api/v1/query?query=traces_span_metrics_calls_total{tag1='value1'}"
   ```
