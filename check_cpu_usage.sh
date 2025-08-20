#!/bin/bash

# Threshold for high CPU usage (in percentage)
THRESHOLD=80

# Get the current CPU usage using top (average over all cores)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | \
            awk '{print 100 - $8}')  # $8 is the idle percentage

# Round CPU usage to integer
CPU_USAGE_INT=${CPU_USAGE%.*}

echo "Current CPU Usage: $CPU_USAGE_INT%"

# Check if CPU usage exceeds threshold
if [ "$CPU_USAGE_INT" -gt "$THRESHOLD" ]; then
    echo "⚠️ High CPU usage detected: $CPU_USAGE_INT%"
    # You can add alerting logic here (e.g., send email, log to file, etc.)
else
    echo "✅ CPU usage is normal."
fi


###############################################################################
# top -bn1: Runs the top command in batch mode (-b) for one iteration (-n1), which gives a snapshot of system performance.
# awk '/Cpu\(s\)/ {print 100 - $8}':
# Filters the line containing Cpu(s) (escaped parentheses are needed).
# $8 typically represents the idle CPU percentage.
# 100 - $8 calculates the active CPU usage (i.e., how much CPU is being used).
# CPU=$(...): Stores the result (CPU usage) in the variable CPU.
