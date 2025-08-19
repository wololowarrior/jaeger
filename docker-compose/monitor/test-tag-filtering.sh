#!/bin/bash

# Test script to demonstrate tag filtering in Jaeger SPM
# This script:
# 1. Generates traces with different tags
# 2. Waits for metrics to be collected
# 3. Tests filtering metrics by tags

echo "Generating traces with tags for testing..."

# Generate traces with env=staging
echo "Generating traces with env=staging..."
docker run --env OTEL_EXPORTER_OTLP_TRACES_ENDPOINT="http://localhost:4318/v1/traces" \
  --env OTEL_RESOURCE_ATTRIBUTES="env=staging" \
  --network host \
  --rm \
  jaegertracing/jaeger-tracegen:latest \
    -trace-exporter otlp-http \
    -service tag-filtering-demo-1 \
    -traces 10

# Generate traces with tag2=value2
echo "Generating traces with env=production..."
docker run --env OTEL_EXPORTER_OTLP_TRACES_ENDPOINT="http://localhost:4318/v1/traces" \
  --env OTEL_RESOURCE_ATTRIBUTES="env=production" \
  --network host \
  --rm \
  jaegertracing/jaeger-tracegen:latest \
    -trace-exporter otlp-http \
    -service tag-filtering-demo-1 \
    -traces 10

echo "Done generating traces. Please wait a moment for metrics to be collected..."
sleep 10  # Wait for metrics to be collected

# Current timestamp in milliseconds
CURRENT_TS=$(date +%s)000

# Test tag filtering in metrics API
echo -e "\n== Testing tag filtering in metrics API =="

echo -e "\nQuerying metrics with env=staging..."
curl -s "http://localhost:16686/api/metrics/calls?service=tag-filtering-demo-1&groupByOperation=true&endTs=$CURRENT_TS&lookback=3600000&step=5000&ratePer=60000&tag=env:staging" | jq '.'

echo -e "\nQuerying metrics with env=production..."
curl -s "http://localhost:16686/api/metrics/calls?service=tag-filtering-demo-1&groupByOperation=true&endTs=$CURRENT_TS&lookback=3600000&step=5000&ratePer=60000&tag=env:production" | jq '.'

echo -e "\nQuerying metrics with env=production..."
curl -s "http://localhost:16686/api/metrics/calls?service=tag-filtering-demo-1&groupByOperation=true&endTs=$CURRENT_TS&lookback=3600000&step=5000&ratePer=60000&tag=env:produ" | jq '.'

echo -e "\nDone testing tag filtering."
echo "Visit http://localhost:16686/monitor to see metrics in the Jaeger UI."
echo "You can now filter metrics by tags in the UI or using the API."
