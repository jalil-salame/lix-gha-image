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
          includeNixDB = true;
          # Enable flakes
          runAsRoot = ''
            #!${pkgs.runtimeShell}
            ${pkgs.dockerTools.shadowSetup}
            mkdir -p /etc/nix/
            echo extra-experimental-features = nix-command flakes >> /etc/nix/nix.conf
          '';
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
              nix
              nix-fast-build
            ];
            pathsToLink = [ "/bin" ];
          };
          config.Env = [ "LD_LIBRARY_PATH=\"${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}\"" ];
        };
      });
    };
}
