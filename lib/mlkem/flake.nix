# SPDX-License-Identifier: Apache-2.0

{
  description = "mlkem-native";

  inputs = {
    nixpkgs-2405.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, pkgs, system, ... }:
        let
          pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
          pkgs-2405 = inputs.nixpkgs-2405.legacyPackages.${system};
          util = pkgs.callPackage ./nix/util.nix {
            cbmc = pkgs-unstable.cbmc;
            bitwuzla = pkgs-unstable.bitwuzla;
            z3 = pkgs-unstable.z3;
          };
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (_:_: {
                gcc48 = pkgs-2405.gcc48;
                gcc49 = pkgs-2405.gcc49;
                qemu = pkgs-unstable.qemu; # 9.2.0
              })
            ];
          };

          packages.linters = util.linters;
          packages.cbmc = util.cbmc_pkgs;
          packages.hol_light = util.hol_light';
          packages.s2n_bignum = util.s2n_bignum;
          packages.valgrind_varlat = util.valgrind_varlat;
          packages.toolchains = util.toolchains;
          packages.toolchains_native = util.toolchains_native;

          devShells.default = util.mkShell {
            packages = builtins.attrValues
              {
                inherit (config.packages) linters cbmc hol_light s2n_bignum toolchains_native;
                inherit (pkgs)
                  direnv
                  nix-direnv;
              } ++ pkgs.lib.optionals (!pkgs.stdenv.isDarwin) [ config.packages.valgrind_varlat ];
          };

          devShells.hol_light = util.mkShell {
            packages = builtins.attrValues {
              inherit (config.packages) hol_light s2n_bignum;
            };
          };
          devShells.ci = util.mkShell {
            packages = builtins.attrValues { inherit (config.packages) linters toolchains_native; };
          };
          devShells.ci-bench = util.mkShell {
            packages = builtins.attrValues { inherit (config.packages) toolchains_native; };
          };
          devShells.ci-cbmc = util.mkShell {
            packages = builtins.attrValues { inherit (config.packages) cbmc toolchains_native; };
          };
          devShells.ci-cross = util.mkShell {
            packages = builtins.attrValues { inherit (config.packages) linters toolchains; };
          };
          devShells.ci-linter = util.mkShellNoCC {
            packages = builtins.attrValues { inherit (config.packages) linters; };
          };
          devShells.ci_clang14 = util.mkShellWithCC' pkgs.clang_14;
          devShells.ci_clang15 = util.mkShellWithCC' pkgs.clang_15;
          devShells.ci_clang16 = util.mkShellWithCC' pkgs.clang_16;
          devShells.ci_clang17 = util.mkShellWithCC' pkgs.clang_17;
          devShells.ci_clang18 = util.mkShellWithCC' pkgs.clang_18;
          devShells.ci_clang19 = util.mkShellWithCC' pkgs.clang_19;
          devShells.ci_gcc48 = util.mkShellWithCC' pkgs.gcc48;
          devShells.ci_gcc49 = util.mkShellWithCC' pkgs.gcc49;
          devShells.ci_gcc7 = util.mkShellWithCC' pkgs.gcc7;
          devShells.ci_gcc11 = util.mkShellWithCC' pkgs.gcc11;
          devShells.ci_gcc12 = util.mkShellWithCC' pkgs.gcc12;
          devShells.ci_gcc13 = util.mkShellWithCC' pkgs.gcc13;
          devShells.ci_gcc14 = util.mkShellWithCC' pkgs.gcc14;

          # valgrind with a patch for detecting variable-latency instructions
          devShells.ci_valgrind-varlat_clang14 = util.mkShellWithCC_valgrind' pkgs.clang_14;
          devShells.ci_valgrind-varlat_clang15 = util.mkShellWithCC_valgrind' pkgs.clang_15;
          devShells.ci_valgrind-varlat_clang16 = util.mkShellWithCC_valgrind' pkgs.clang_16;
          devShells.ci_valgrind-varlat_clang17 = util.mkShellWithCC_valgrind' pkgs.clang_17;
          devShells.ci_valgrind-varlat_clang18 = util.mkShellWithCC_valgrind' pkgs.clang_18;
          devShells.ci_valgrind-varlat_clang19 = util.mkShellWithCC_valgrind' pkgs.clang_19;
          devShells.ci_valgrind-varlat_gcc48 = util.mkShellWithCC_valgrind' pkgs.gcc48;
          devShells.ci_valgrind-varlat_gcc49 = util.mkShellWithCC_valgrind' pkgs.gcc49;
          devShells.ci_valgrind-varlat_gcc7 = util.mkShellWithCC_valgrind' pkgs.gcc7;
          devShells.ci_valgrind-varlat_gcc11 = util.mkShellWithCC_valgrind' pkgs.gcc11;
          devShells.ci_valgrind-varlat_gcc12 = util.mkShellWithCC_valgrind' pkgs.gcc12;
          devShells.ci_valgrind-varlat_gcc13 = util.mkShellWithCC_valgrind' pkgs.gcc13;
          devShells.ci_valgrind-varlat_gcc14 = util.mkShellWithCC_valgrind' pkgs.gcc14;
        };
      flake = {
        devShell.x86_64-linux =
          let
            pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
            pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.x86_64-linux;
            util = pkgs.callPackage ./nix/util.nix {
              inherit pkgs;
              cbmc = pkgs-unstable.cbmc;
              bitwuzla = pkgs-unstable.bitwuzla;
              z3 = pkgs-unstable.z3;
            };
          in
          util.mkShell {
            packages =
              [
                util.linters
                util.cbmc_pkgs
                util.hol_light'
                util.s2n_bignum
                util.toolchains_native
              ]
              ++ pkgs.lib.optionals (!pkgs.stdenv.isDarwin) [ util.valgrind_varlat ];
          };
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

      };
    };
}
