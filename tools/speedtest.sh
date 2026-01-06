#!/bin/bash
# Speed Test Tool

echo "Running speed test..."

# Install speedtest-cli if not exists
if ! command -v speedtest-cli &> /dev/null; then
    apt install -y speedtest-cli
fi

echo ""
echo "Testing download/upload speed..."
speedtest-cli --simple

echo ""
echo "Testing ping..."
ping -c 4 8.8.8.8
