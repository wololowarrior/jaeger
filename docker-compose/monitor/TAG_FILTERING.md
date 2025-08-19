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
      # Regular dimensions
      - name: operation
        default: unknown-operation
      # Tag dimensions
      - name: tag1
        default: ""
      - name: tag2
        default: ""

# Use the attributes processor to propagate tags
processors:
  attributes:
    actions:
      - key: tag1
        action: insert
        value: "value1"  # In production, use dynamic values if supported
```

### Version Compatibility

The configuration may need adjustments based on your OpenTelemetry Collector version:

- **Older versions**: Use the approach shown here with the attributes processor
- **Newer versions (0.83.0+)**: May support direct resource attribute propagation with options like
  `resource_metrics_strategy` and `resource_attributes`

Note: Even though your go.mod file may show a newer version of the collector, the Docker image used might
have an older version of the spanmetrics connector that doesn't support these newer features.

## Implementation Hack

The current implementation uses a workaround to enable tag filtering in metrics:

1. **Fixed Tag Values**: Since older collector versions can't dynamically propagate resource attributes to span metrics dimensions, we use the attributes processor to insert fixed tag values (e.g., "value1", "value2").

2. **Manual Configuration**: For each tag you want to filter by, you need to:
   - Add it as a dimension in the spanmetrics connector
   - Create an attributes processor action to insert it as a span attribute

3. **Limited Tag Values**: This approach only works with known, pre-configured tag values. If you need to support arbitrary tag values, you'll need to upgrade to a newer collector version that supports resource attribute propagation.

4. **Testing Workflow**: When testing, send traces with the exact tag values configured in the attributes processor, as these are the only values that will work with the filtering.

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

1. **Use the provided configuration**: Ensure you're using `config-spm-with-tag-filtering.yaml`
   ```yaml
   # In docker-compose.yml
   volumes:
     - "../../cmd/jaeger/config-spm-with-tag-filtering.yaml:/etc/jaeger/config.yml"
   ```

2. **Generate test traces with matching tags**: Send traces with resource attributes matching the configured tag values
   ```bash
   docker run --env OTEL_EXPORTER_OTLP_TRACES_ENDPOINT="http://jaeger:4318/v1/traces" \
     --env OTEL_RESOURCE_ATTRIBUTES="tag1=value1,tag2=value2" \
     --network monitor_backend \
     --rm \
     jaegertracing/jaeger-tracegen:latest \
       -trace-exporter otlp-http \
       -service tag-filtering-demo \
       -traces 10
   ```

3. **Query metrics with tag filters**: Use the metrics API with tag filter parameters
   ```bash
   curl "http://localhost:16686/api/metrics/calls?service=tag-filtering-demo&tag=tag1:value1" | jq '.'
   ```

The key to this hack is ensuring that the fixed values in your configuration (`value1`, `value2`) match the values in your resource attributes when generating traces.

## Debugging Tips

If tag filtering isn't working as expected:

1. **Check Prometheus metrics**: Verify that metrics include the tag labels
   ```bash
   curl "http://localhost:9090/api/v1/query?query=traces_span_metrics_calls_total{tag1='value1'}"
   ```

2. **Verify collector configuration**: Ensure the spanmetrics connector is correctly configured with `resource_metrics_strategy` and the appropriate `resource_attributes`

3. **Inspect resource attributes**: Use the Jaeger UI to check if spans have the expected resource attributes

4. **Common issues**:
   - Missing resource attributes in the `resource_attributes` list
   - Incorrect pipeline configuration
   - Resource attributes not properly set when generating traces

## Limitations

This approach has several limitations:

1. **Fixed values only**: Only works with predefined tag values; can't handle arbitrary user-defined tag values
2. **Manual configuration**: Requires manual updates to add new tags or tag values
3. **Resource overhead**: Less efficient than native resource attribute propagation
4. **Maintenance complexity**: Configuration becomes more complex as you add more tags
