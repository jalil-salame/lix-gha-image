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

          fromImage = pkgs.dockerTools.pullImage {
            imageName = "ghcr.io/lix-project/lix";
            imageDigest = "sha256:f98cbd665473fe30e2d8c39269d568a9e7577f18750b87551dbb26ef0f601968";
            sha256 = "sha256-hQN5VAEFUcv4y3U8Rdhbx1EcZkQuieXlW1CsRDPifs4=";
          };

          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = with pkgs; [
              bash
              coreutils
              git
              gnutar
              gzip
              nodejs_20
              curl
              xz
              # Useful for nix projects
              nix-fast-build
              nix-ld
            ];
            pathsToLink = [ "/bin" ];
          };

          # Add std libs (required for external dynamically linked binaries)
          config.Env = [
            "NIX_LD=\"${pkgs.nix-ld}\""
            "NIX_LD_LIBRARY_PATH=\"${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}\""
            "LD_LIBRARY_PATH=\"${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}\""
          ];

          diskSize = 1024;
          buildVMMemorySize = 512;
        };
      });
    };
}
