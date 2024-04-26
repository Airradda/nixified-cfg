{ inputs', ... }: {
  perSystem = { pkgs, comfyuiModels, lib, ... }: let
    # this packages a model, but does not concern itself with directory structure:
    # placing it where it needs to go is left to whomever or whatever makes use of it
    modelDrv = name: fetched: with lib; let
      join = with strings; (sep: (xs: concatStrings (intersperse sep xs)));
      join-lines = join "\n";
      fetched-to-symlink = name: fetched: let inherit (trivial) throwIfNot; in
        throwIfNot (isString name) "name must be a string."
        throwIfNot (isAttrs fetched) "fetched must be an attrset."
        throwIfNot (isString fetched.format) "fetched.format must be a string."
        throwIfNot (isString fetched.path) "fetched.path must be a string."
          ''
           ln -snf ${fetched.path} $out/${name}.${fetched.format}
          '';
    in pkgs.stdenv.mkDerivation {
      inherit name;
      pname = name;
      sourceRoot = name;
      installPhase = ''
        mkdir -p $out
      '' + (fetched-to-symlink name fetched);
      phases = [ "installPhase" ];
    };

    collectionDrv = pkgs.callPackage ./models/make-collection.nix {};
  in {
    # Populate the packages provided by the flake with the models in `comfyuiModels`
    # plus the entire collection ready to be added to extra_model_paths.yaml.
    # We package the individual models just in case someone wishes to simply install
    # a subset manually
    packages = with lib; let
    in {
      comfyui-model-collection = collectionDrv comfyuiModels;
    } // pipe comfyuiModels [
      (mapAttrsToList (type:
        mapAttrsToList (name: fetched: {
          name = "comfyui-${type}-${name}";
          value = modelDrv name fetched;
        })))
      (lists.flatten)
      (builtins.listToAttrs)
    ];

    checks = let
      yaml-file = import ./models/fetch-model.nix { inherit lib; inherit (pkgs) fetchurl; } {
          format = "yaml";
          url = "https://huggingface.co/lllyasviel/ControlNet-v1-1/raw/main/control_v11f1e_sd15_tile.yaml";
          sha256 = "sha256-OeEzjEFDYYrbF2BPlsOj90DBq10VV9cbBE8DB6CmrbQ=";
        };
    in {
      # TODO: add some more (lightweight) stuff to the model set
      comfyui-model-collection = collectionDrv { configs = { controlnet-v1_1_fe-sd15-tile = yaml-file; }; };
      # fetch a 2KB yaml file to check that it works.
      # nix build .#checks.<system>.comfyuiModelPkg => ./result/controlnet-v1_1_fe-sd15-tile.yaml
      comfyui-model-fetch = modelDrv "controlnet-v1_1_fe-sd15-tile" yaml-file;
    };
  };
}
