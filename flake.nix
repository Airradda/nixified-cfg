{
  description = "Default configuration flake used by nixified-ai";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      perSystem = { system, pkgs, lib, ... }: let
        pkgs = import inputs.nixpkgs { inherit system; };
      in {
        _module.args = {
          inherit pkgs;
          comfyuiModels = import ./models { inherit lib; inherit (pkgs) fetchurl stdenv; };
        };
      };
      systems = [ "x86_64-linux" ];


      imports = [
        ./packages.nix
        ({ inputs', ... }: {
          flake = {
            # this doesn't feel ideal, but I am bikeshedding
            lib.comfyui.availableModels = with inputs'.nixpkgs;
              import ./models { inherit lib; inherit (pkgs) fetchurl stdenv; };
            cfg.comfyui = let basePath = "/var/lib/comfyui"; in {
              modelsPath = "${basePath}/models";
              inputPath = "${basePath}/input";
              outputPath = "${basePath}/test-output";
              tempPath = "${basePath}/temp";
              userPath = "${basePath}/user";
              customNodes = [];
              models = {
                checkpoints = {};
                clip = {};
                clip_vision = {};
                configs = {};
                controlnet = {};
                embeddings = {};
                upscale_models = {};
                vae = {};
                vae_approx = {};
              };
            };
          };
        })
      ];
    };
}
