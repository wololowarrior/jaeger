#!/bin/bash

# Test script to demonstrate tag filtering in Jaeger SPM with resource attributes
# This script:
# 1. Generates traces with different resource attributes as tags
# 2. Waits for metrics to be collected (spanmetrics connector propagates resource attributes to metrics)
# 3. Tests filtering metrics by tags using the Jaeger API

echo "Generating traces with tags for testing..."

# Generate traces with tag1=value1
echo "Generating traces with tag1=value1..."
docker run --env OTEL_EXPORTER_OTLP_TRACES_ENDPOINT="http://localhost:4318/v1/traces" \
  --env OTEL_RESOURCE_ATTRIBUTES="tag1=value1" \
  --network host \
  --rm \
  jaegertracing/jaeger-tracegen:latest \
    -trace-exporter otlp-http \
    -service tag-filtering-demo-1 \
    -traces 10

# Generate traces with tag2=value2
echo "Generating traces with tag2=value2..."
docker run --env OTEL_EXPORTER_OTLP_TRACES_ENDPOINT="http://localhost:4318/v1/traces" \
  --env OTEL_RESOURCE_ATTRIBUTES="tag2=value2" \
  --network host \
  --rm \
  jaegertracing/jaeger-tracegen:latest \
    -trace-exporter otlp-http \
    -service tag-filtering-demo-2 \
    -traces 10

# Generate traces with both tags
echo "Generating traces with both tag1=value1 and tag2=value2..."
docker run --env OTEL_EXPORTER_OTLP_TRACES_ENDPOINT="http://localhost:4318/v1/traces" \
  --env OTEL_RESOURCE_ATTRIBUTES="tag1=value1,tag2=value2" \
  --network host \
  --rm \
  jaegertracing/jaeger-tracegen:latest \
    -trace-exporter otlp-http \
    -service tag-filtering-demo-both \
    -traces 10

echo "Done generating traces. Please wait a moment for metrics to be collected..."
sleep 10  # Wait for metrics to be collected

# Current timestamp in milliseconds
CURRENT_TS=$(date +%s)000

# Test tag filtering in metrics API
echo -e "\n== Testing tag filtering in metrics API =="
echo "Querying metrics with tag1=value1..."
curl -s "http://localhost:16686/api/metrics/calls?service=tag-filtering-demo-1&service=tag-filtering-demo-both&groupByOperation=true&endTs=$CURRENT_TS&lookback=3600000&step=5000&ratePer=60000&tag=tag1:value1" | jq '.'

echo -e "\nDone testing tag filtering."
echo "Visit http://localhost:16686/monitor to see metrics in the Jaeger UI."
echo "You can now filter metrics by tags in the UI or using the API."
