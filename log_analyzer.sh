#!/bin/bash


if [ $# -lt 1 ]; then
    echo "Usage: $0 <LOG_FILE>"
    exit 1
fi


LOG_FILE="$1"
THRESHOLD=5

if [ ! -f "$LOG_FILE" ]; then
    echo "Log file not found: $LOG_FILE"
    exit 1
fi

echo "Failed login attempts by IP:"
echo "-----------------------------"

grep "sshd-session\[[0-9]*\]: Failed password for" "$LOG_FILE" | awk '{print $11}' | sort | uniq -c | sort -rn | while read -r COUNT IP; do
    echo "$IP : $COUNT attempts"
  
if [ $COUNT -gt $THRESHOLD ]; then
    echo "  ^ WARNING: possible brute force"
fi

done
