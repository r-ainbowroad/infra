# SPDX-License-Identifier: Apache-2.0 OR ISC
# SPDX-FileCopyrightText: 2024 Dusk Banks <me@bb010g.com>
{ ... }:
{
  config,
  flake-parts-lib,
  hookModule,
  lib,
  options,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib) mkDefault mkOption types;
  submodule' = modules: types.submoduleWith { modules = lib.toList modules; };
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    {
      config,
      options,
      pkgs,
      ...
    }:
    let
      cfg = config.pre-commit;
    in
    {
      options.pre-commit.settings = mkOption {
        type = submodule' (
          settingsArgs@{ ... }:
          let
            inherit (settingsCfg) hooks settings tools;
            settingsCfg = settingsArgs.config;
          in
          {
            options.hooks = { };
            config.hooks = mapAttrs (_: mapAttrs (_: mkDefault)) {
              # skip-worktree = {
              #   name = "skip-worktree";
              #   description = "Ensure that files have the \"assume unchanged\" bit set.";
              #   package = tools.skip-worktree;
              #   entry = "${hooks.skip-worktree.package}/bin/skip-worktree";
              #   types = [ "file" ];
              #   # TODO(me@bb010g.com): teach pre-commit how to support the post-index-change hook
              #   stages = [ "post-index-change" ];
              # };
            };
          }
        );
      };
      config.pre-commit.settings =
        { pkgs, ... }:
        let
          toolsPackage =
            { callPackage }:
            {
              # skip-worktree = callPackage (
              #   { writeScriptBin }:
              #   writeScriptBin "skip-worktree" ''
              #     #!/usr/bin/env bash
              #     printf '%s ' git update-index --skip-worktree -- "$@"; printf '\n'
              #   ''
              # ) { };
            };
        in
        {
          tools = builtins.removeAttrs (pkgs.callPackage toolsPackage { }) [
            "override"
            "overrideDerivation"
          ];
        };
    }
  );
}
