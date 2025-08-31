#!/bin/bash
while IFS= read -r user; do
  echo "Processing user: $user"
done < <(awk -F: '$3 >= 1000 {print $1}' /etc/passwd)