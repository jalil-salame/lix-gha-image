FROM ghcr.io/lix-project/lix:2.91

WORKDIR /nixos
COPY flake.nix flake.nix
RUN nixos-rebuild switch --flake '.#lix-gha'
