#!/usr/bin/env bash
# Usage: ./switch_backend.sh blue|green
set -e
TARGET=$1
if [[ "$TARGET" != "blue" && "$TARGET" != "green" ]]; then
  echo "Usage: $0 blue|green"
  exit 1
fi

HAPROXY_IP=${HAPROXY_IP:-"127.0.0.1"}
OTHER=$( [[ "$TARGET" == "blue" ]] && echo "green" || echo "blue" )
echo "Disabling ${OTHER} backend..."
echo "disable backend pg_${OTHER}" | socat stdio TCP:${HAPROXY_IP}:9999 || true
echo "enable backend pg_${TARGET}" | socat stdio TCP:${HAPROXY_IP}:9999
echo "Switched traffic to $TARGET"
