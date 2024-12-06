# SPDX-License-Identifier: ISC OR Apache-2.0
# SPDX-FileCopyrightText: 2024 r/ainbowroad contributors

$ENV.OCI_CONTAINER_ENGINE as $ociContainerEngine |
["cpu", "cpuset", "hugetlb", "io", "memory", "pids"] as $optionalCgroups |
($optionalCgroups - {
  docker: ["hugetlb"],
  podman: ["hugetlb", "io", "pids"],
}[$ociContainerEngine]) as $requiredCgroups |

split("\n") |
(.[0] | split(" ") |
  ($requiredCgroups - . | if length > 0 then
    "ERROR [r-ainbowroad/infra]: Missing required cgroup controllers: \(.)"
  else empty end),
  ($optionalCgroups - . | if length > 0 then
    "WARNING [r-ainbowroad/infra]: Missing optional cgroup controllers: \(.)"
  else empty end),
empty)
