# SPDX-License-Identifier: 0BSD
# SPDX-FileCopyrightText: 2024 r/ainbowroad contributors
{
  description = "r/ainbowroad infrastructure";

  nixConfig.extra-substituters = "https://cache.lix.systems https://nix-community.cachix.org";
  nixConfig.extra-trusted-public-keys = "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";

  inputs.by-name.inputs.nixpkgs.follows = "nixpkgs";
  inputs.by-name.url = "github:bb010g/by-name.nix";
  inputs.flake-compat.flake = false;
  inputs.flake-compat.url = "github:edolstra/flake-compat";
  inputs.flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.flakey-profile.url = "github:lf-/flakey-profile";
  inputs.gitignore.inputs.nixpkgs.follows = "nixpkgs";
  inputs.gitignore.url = "github:hercules-ci/gitignore.nix";
  inputs.lix-module.inputs.flake-utils.follows = "flake-utils";
  inputs.lix-module.inputs.flakey-profile.follows = "flakey-profile";
  inputs.lix-module.inputs.lix.follows = "lix";
  inputs.lix-module.inputs.nixpkgs.follows = "nixpkgs";
  inputs.lix-module.url = "git+https://git.lix.systems/lix-project/nixos-module.git";
  inputs.lix.flake = false;
  inputs.lix.url = "git+https://git.lix.systems/lix-project/lix.git";
  inputs.nix2container.flake = false;
  # inputs.nix2container.inputs.flake-utils.follows = "flake-utils";
  # inputs.nix2container.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nix2container.url = "github:nlewo/nix2container";
  inputs.nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.pre-commit-hooks-nix.inputs.flake-compat.follows = "flake-compat";
  inputs.pre-commit-hooks-nix.inputs.nixpkgs-stable.follows = "nixpkgs-stable";
  inputs.pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.pre-commit-hooks-nix.inputs.gitignore.follows = "gitignore";
  inputs.pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
  inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";

  outputs =
    inputs:
    let
      inherit (lib.modules) setDefaultModuleLocation;
      importCell = table@{ directoryEntry, ... }: import directoryEntry.path table;
      importModuleCell =
        table@{ directoryEntry, ... }:
        let
          inherit (directoryEntry) path;
        in
        setDefaultModuleLocation path (import path table);
      lib = inputs.by-name.libs.default;
      table = lib.filesystem.readNameBasedTableDirectory {
        rowFromFile."flake-module.nix" = table: { flakeModule = importModuleCell table; };
        rowFromFile."package.nix" = table: { package = importCell table; };
        rowsPath = ./by-name;
        specialColumns.input = inputs;
      };
    in
    inputs.flake-parts.lib.mkFlake {
      inherit inputs;
      moduleLocation = ./flake.nix;
    } table.rows.self.flakeModule;
}
