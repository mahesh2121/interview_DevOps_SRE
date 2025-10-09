# Fixing Pipeline Caching Issues with Terraform and the AWS Provider

## Issue Summary

In Maurice Borgmeier's article *"Fixing Pipeline Caching Issues with
Terraform and the AWS Provider"*, the problem was that **Terraform
didn't use the cached AWS provider binary in CI/CD pipelines**, even
though the `.terraform` directory was properly cached. As a result,
Terraform downloaded the large AWS provider (150--180 MB) on every run,
slowing down the pipeline by several minutes.

## Root Cause

Terraform verifies provider binaries using hashes stored in
`.terraform.lock.hcl`.\
The lock file only had **Windows platform hashes** (from the developer's
Windows machine), but the CI pipeline ran on **Linux**.\
Because the lock file didn't include Linux hashes, Terraform ignored the
cached provider and re-downloaded it every time.

## Fix

Add all relevant platform hashes to `.terraform.lock.hcl` using the
`terraform providers lock` command:

``` bash
terraform providers lock   -platform=windows_amd64   -platform=linux_amd64
```

## Result

After committing the updated lock file (with both Windows and Linux
hashes):\
✅ Terraform reused the cached providers.\
✅ Pipeline run time dropped from **6--8 minutes to under 20 seconds**.

------------------------------------------------------------------------

**In short:**\
*Issue → Missing platform hashes in `.terraform.lock.hcl`*\
*Fix → Add hashes for all target platforms using
`terraform providers lock`.*
