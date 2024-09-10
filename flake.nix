{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, lix-module, ... }:
    let
      inherit (nixpkgs) lib;
      systems = [ "x86_64-linux" ];
      nixpkgsFor = lib.genAttrs systems (
        system:
        import nixpkgs {
          inherit system;
          overlays = [ lix-module.overlays.lixFromNixpkgs ];
        }
      );
      forEachSystem = f: lib.genAttrs systems (system: f nixpkgsFor.${system});
    in
    {
      packages = forEachSystem (pkgs: {
        lix-gha-image = pkgs.dockerTools.buildImage {
          name = "lix-gha-image";
          tag = "latest";
          fromImage = "ghcr.io/lix-project/lix";
          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = with pkgs; [
              bash
              coreutils
              git
              gnutar
              gzip
              nodejs_20
              # Useful for nix projects
              nix
              nix-fast-build
            ];
            pathsToLink = [ "/bin" ];
          };
        };
      });
    };
}
