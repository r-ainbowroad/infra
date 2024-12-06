#!/usr/bin/env -S just --justfile
# SPDX-License-Identifier: ISC OR Apache-2.0
# SPDX-FileCopyrightText: 2024 r/ainbowroad contributors

[private]
[no-exit-message]
default:
  @printf '%s\n' 'No recipe specified. List available recipes with `just --list`.'
  @exit 1

# Automatically update dependencies.
[positional-arguments]
renovate *ARGS:
  @LOG_LEVEL=DEBUG renovate --platform=local "$@"

# Create a cluster using k3d.
[group('cluster')]
create-cluster CLUSTER=(infra_bootstrap_cluster):
  git update-index --skip-worktree kubernetes/kubeconfig kubernetes/clusterctl.yaml
  if ! { k3d cluster list -o json | jq --arg cluster {{quote(CLUSTER)}} -e 'any(.name == $cluster)' > /dev/null; }; then \
    k3d cluster create --config kubernetes/k3d-{{quote(CLUSTER)}}-config.yaml; \
  fi

# Create (if new) and start a cluster using k3d.
[group('cluster')]
start-cluster CLUSTER=(infra_bootstrap_cluster):
  if { k3d cluster list -o json | jq --arg cluster {{quote(CLUSTER)}} -e 'any(.name == $cluster)' > /dev/null; }; then \
    k3d cluster start --wait {{quote(CLUSTER)}}; \
  else \
    k3d cluster create --wait --config kubernetes/k3d-{{quote(CLUSTER)}}-config.yaml; \
  fi

[group('cluster')]
init-cluster CLUSTER=(infra_bootstrap_cluster): (start-cluster CLUSTER)
  clusterctl --config kubernetes/clusterctl.yaml init --wait-providers --bootstrap="talos:v0.6.5" --control-plane="talos:v0.5.6" --infrastructure="hetzner:v1.0.0-beta.37"

# Inspect a cluster using k9s.
[group('cluster')]
inspect-cluster:
  k9s

# Stop a cluster using k3d.
[group('cluster')]
stop-cluster CLUSTER=(infra_bootstrap_cluster):
  k3d cluster stop {{quote(CLUSTER)}}

# Stop (if running) and delete a cluster using k3d.
[group('cluster')]
delete-cluster CLUSTER=(infra_bootstrap_cluster): (stop-cluster CLUSTER)
  k3d cluster delete --config kubernetes/k3d-{{quote(CLUSTER)}}-config.yaml
  git update-index --no-skip-worktree kubernetes/kubeconfig kubernetes/clusterctl.yaml

infra_bootstrap_cluster := "r-ainbowroad-bootstrap"

[group('infra')]
bootstrap-infra CLUSTER=infra_bootstrap_cluster: (start-cluster CLUSTER) && (stop-cluster CLUSTER)

# vim:et:sw=2
