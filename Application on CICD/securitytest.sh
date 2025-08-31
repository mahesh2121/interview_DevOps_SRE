#!/bin/bash

while IFS= read -r package; do
  grep -q "^${package}$" whitelist.txt
  if [[ $? -ne 0 ]]; then
    echo "Security Test failed: Unauthorized package '$package' in requirements.txt"
    exit 1
  fi
done < requirements.txt

echo "All packages in requirements.txt are authorized"
exit 0