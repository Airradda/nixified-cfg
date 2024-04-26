{ inputs, self, ... }: {
  flake = {
    cfg.comfyui = system: let
      pkgs = import inputs.nixpkgs { inherit system; };
      models = import ./models { inherit (pkgs system) lib fetchurl stdenv; };
      basePath = "/var/lib/comfyui";
    in {
      inherit models;
      modelsPath = "${self.packages."${system}".collection}";
      inputPath = "${basePath}/input";
      outputPath = "${basePath}/output";
      tempPath = "${basePath}/temp";
      userPath = "${basePath}/user";
      customNodes = [];
    };
  };
  imports = [
    ./packages.nix
  ];
}
