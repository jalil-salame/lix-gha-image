{
  inputs = {
    nixpkgs = "nixpkgs/nixos-unstable";
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, lix-module, ... }:
    {
      nixosConfigurations.lix-gha = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          (
            { pkgs, ... }:
            {
              nix = {
                # Pin nixpkgs
                registry.nixpkgs.flake = nixpkgs;
                # Enable flakes
                settings.experimental-features = [
                  "nix-command"
                  "flakes"
                ];
              };
              # Required by GitHub actions
              environment.systemPackages = with pkgs; [
                git
                bash
                coreutils
                git
                gnutar
                gzip
                xz
                nodejs_20
              ];
            }
          )
          lix-module.nixosModules.default
        ];
      };
    };
}
