# SPDX-License-Identifier: Apache-2.0 OR ISC
# SPDX-FileCopyrightText: 2024 r/ainbowroad contributors
table@{ columns, rows, ... }:
{
  config,
  inputs,
  lib,
  ...
}:

let
  inherit (config) flake;
  inherit (lib.attrsets) mapAttrs;
  flakeModules = columns.flakeModule;
  concatMapAttrs' = f: attrs: builtins.listToAttrs (concatMapAttrsToList f attrs);
  concatMapAttrsToList =
    f: attrs: builtins.concatMap (name: f name attrs.${name}) (builtins.attrNames attrs);
in
{
  imports = [
    inputs.pre-commit-hooks-nix.flakeModule
    flakeModules.pre-commit-hooks
    inputs.treefmt-nix.flakeModule
  ];

  config = {
    # flake.flakeModules = flakeModules;
    flake.overlays.k3d = pkgsFinal: pkgsPrev: { k3d = pkgsFinal.callPackage rows.k3d.package { }; };
    flake.overlays.nix2container =
      pkgsFinal: pkgsPrev:
      import (inputs.nix2container + "/default.nix") {
        inherit (pkgsFinal.stdenv) system;
        pkgs = pkgsFinal;
      };
    # flake.overlays.terraform-providers = pkgsFinal: pkgsPrev: {
    #   terraform-providers = pkgsPrev.terraform-providers // {
    #     actualProviders = pkgsPrev.terraform-providers.actualProviders // {
    #       fly = pkgsFinal.terraform-providers.mkProvider {
    #         hash = "sha256-KZEgfsYpVCY8a5Gl9xELScqprqRyGANhSe5zhamfPu0=";
    #         homepage = "https://registry.terraform.io/providers/andrewbaxter/fly";
    #         owner = "andrewbaxter";
    #         repo = "terraform-provider-fly";
    #         rev = "v0.1.13";
    #         spdx = "BSD-3-Clause";
    #         vendorHash = "sha256-Jezz6I3NKQYTE0kfpOFIBX3cy1gwHY2+VfSNkKvBdaU=";
    #       };
    #     };
    #     fly = pkgsFinal.terraform-providers.actualProviders.fly;
    #   };
    # };
    # flake.overlays.talhelper = pkgsFinal: pkgsPrev: {
    #   talhelper = pkgsFinal.callPackage (inputs.talhelper + "/default.nix") { };
    # };
    # flake.overlays.terranix =
    #   pkgsFinal: pkgsPrev:
    #   let
    #     withDefaultPkgs = fn: lib.mirrorFunctionArgs fn (args: fn ({ pkgs = pkgsFinal; } // args));
    #   in
    #   {
    #     terranixConfigurationAst = withDefaultPkgs inputs.terranix.lib.terranixConfigurationAst;
    #     terranixOptionsAst = withDefaultPkgs inputs.terranix.lib.terranixOptionsAst;
    #     terranixConfiguration = withDefaultPkgs inputs.terranix.lib.terranixConfiguration;
    #     terranixOptions = withDefaultPkgs inputs.terranix.lib.terranixOptions;
    #   };
    perSystem =
      {
        config,
        pkgs,
        system,
        ...
      }:
      {
        config = {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            };
            overlays = [
              inputs.lix-module.overlays.default

              flake.overlays.k3d
              flake.overlays.nix2container
              # flake.overlays.talhelper
              # flake.overlays.terraform-providers
              # flake.overlays.terranix
            ];
          };

          devShells.default = pkgs.callPackage (
            {
              age,
              clusterctl,
              fluxcd,
              flyctl,
              hcloud,
              jq,
              just,
              k3d,
              k9s,
              kubectl,
              kubectl-explore,
              kubernetes-helm,
              # opentofu,
              renovate,
              skaffold,
              sops,
              # talhelper,
              talosctl,
              mkShellNoCC,
            }:
            mkShellNoCC {
              inputsFrom = [
                config.pre-commit.devShell
                config.treefmt.build.devShell
              ];

              buildInputs = [
                age
                clusterctl
                fluxcd
                flyctl
                hcloud
                jq
                just
                k3d
                k9s
                kubectl
                kubectl-explore
                kubernetes-helm
                # (opentofu.withPlugins (p: [
                #   p.cloudflare
                #   p.external
                #   p.fly
                #   p.hcloud
                #   p.sops
                #   p.talos
                #   p.vault
                # ]))
                renovate
                skaffold
                sops
                # talhelper
                talosctl
              ];

              shellHook = ''
                FLAKE_ROOT="$PWD"
                if ! command -v printenv > /dev/null; then
                  printf '%s\n' "ERROR [r-ainbowroad/infra]: Install printenv(1)." >&2
                else
                  if [[ -z "''${XDG_RUNTIME_DIR:-}" && -e "/run/user/''${UID:-$(id -u)}" ]]; then
                    export XDG_RUNTIME_DIR="/run/user/''${UID:-$(id -u)}"
                    printf '%s\n' "WARNING [r-ainbowroad/infra]: $(typeset -p 'XDG_RUNTIME_DIR')" >&2
                  fi
                  if ! printenv 'XDG_RUNTIME_DIR' > /dev/null; then
                    printf '%s\n' "ERROR [r-ainbowroad/infra]: $(typeset -p 'XDG_RUNTIME_DIR')" >&2
                  else
                    case "''${DOCKER_HOST+x}''${DOCKER_SOCK+y}" in 'x')
                      case "''${DOCKER_HOST#unix://}" in ?*)
                        export DOCKER_SOCK="''${DOCKER_HOST#unix://}"
                        printf '%s\n' "INFO [r-ainbowroad/infra]: $(typeset -p 'DOCKER_SOCK')" >&2
                      esac
                    ;; ''')
                      if [[ -e "''${XDG_RUNTIME_DIR}/docker.sock" ]]; then
                        export DOCKER_SOCK="''${XDG_RUNTIME_DIR}/docker.sock"
                      elif [[ -e "''${XDG_RUNTIME_DIR}/podman/podman.sock" ]]; then
                        export DOCKER_SOCK="''${XDG_RUNTIME_DIR}/podman/podman.sock"
                      else
                        printf '%s\n' "WARNING [r-ainbowroad/infra]: Neither Docker nor Podman sockets found." >&2
                      fi
                      case "''${DOCKER_SOCK+x}" in 'x')
                        printf '%s\n' "INFO [r-ainbowroad/infra]: $(typeset -p 'DOCKER_SOCK')" >&2
                      esac
                    esac
                    case "''${DOCKER_HOST+x}''${DOCKER_SOCK:+y}" in 'y')
                      export DOCKER_HOST="unix://''${DOCKER_SOCK}"
                      printf '%s\n' "INFO [r-ainbowroad/infra]: $(typeset -p 'DOCKER_HOST')" >&2
                    esac
                    case "''${DOCKER_HOST+x}''${DOCKER_SOCK+y}" in 'xy') ;; *)
                      printf '%s\n' "WARNING [r-ainbowroad/infra]: Container engine configuration may be bad. $(typeset -p 'DOCKER_SOCK' 'DOCKER_HOST')" >&2
                    esac
                    case "''${DOCKER_SOCK:-}" in *"/docker.sock")
                      export OCI_CONTAINER_ENGINE="docker"
                    ;; *"/podman.sock")
                      export OCI_CONTAINER_ENGINE="podman"
                    ;; *)
                      printf '%s\n' "WARNING [r-ainbowroad/infra]: Couldn't detect OCI container engine." >&2
                    esac
                    case "$(LC_ALL='C' uname -s)" in 'Linux')
                      case "''${OCI_CONTAINER_ENGINE+x}" in 'x')
                        if [[ -e "/sys/fs/cgroup/user.slice/user-''${UID:-$(id -u)}.slice/user@''${UID:-$(id -u)}.service/cgroup.controllers" ]]; then
                          jq -f check-cgroup-controllers.jq -r -s --raw-input "/sys/fs/cgroup/user.slice/user-''${UID:-$(id -u)}.slice/user@''${UID:-$(id -u)}.service/cgroup.controllers" >&2
                        else
                          printf '%s\n' "WARNING [r-ainbowroad/infra]: Cgroup controllers may be missing (unknown user service manager)." >&2
                        fi
                      esac
                    esac
                  fi
                fi
                export KUBECONFIG="$PWD/kubernetes/kubeconfig" TALOSCONFIG="$PWD/kubernetes/talos/clusterconfig/talosconfig"
              '';
            }
          ) { };

          legacyPackages.nixpkgs = lib.dontRecurseIntoAttrs pkgs;

          # packages.app-vault = pkgs.nix2container.buildImage {
          #   name = "vault";

          #   config = {
          #     Cmd = [
          #       "${pkgs.vault}/bin/vault"
          #       "server"
          #     ];
          #   };

          #   maxLayers = 127;
          # };

          # # TODO(bb010g): write flake-parts module
          # packages.terraformConfig =
          #   let
          #     terranixCore = pkgs.terranixConfigurationAst {
          #       modules = [
          #         (
          #           { ... }:

          #           {
          #             config = {
          #               provider.hcloud = { };
          #             };
          #           }
          #         )
          #       ];
          #     };
          #   in
          #   (pkgs.formats.json { }).generate "config.tf.json" terranixCore.config;

          pre-commit.check.enable = true;
          pre-commit.settings.hooks.eclint.enable = true;
          pre-commit.settings.hooks.pre-commit-hook-ensure-sops.enable = true;
          pre-commit.settings.hooks.reuse.enable = true;
          pre-commit.settings.hooks.shellcheck.enable = lib.mkIf config.treefmt.programs.shellcheck.enable false;
          # pre-commit.settings.hooks.skip-worktree.enable = true;
          pre-commit.settings.hooks.treefmt.enable = true;
          pre-commit.settings.hooks.treefmt.packageOverrides.treefmt = config.treefmt.build.wrapper;
          pre-commit.settings.hooks.treefmt.settings.formatters = lib.attrValues config.treefmt.build.programs;
          pre-commit.settings.tools.shellcheck = config.treefmt.programs.shellcheck.package;

          treefmt.flakeCheck = lib.mkIf (
            config.pre-commit.check.enable && config.pre-commit.hooks.treefmt.enable
          ) false;
          treefmt.flakeFormatter = true;
          treefmt.programs.nixfmt-rfc-style.enable = true;
          treefmt.programs.shellcheck.enable = true;
          treefmt.projectRootFile = ".envrc";
        };
      };

    systems = lib.systems.flakeExposed;
  };
}
