# https://just.systems

set dotenv-load

default:
    just --choose

# Test NixOS configuration for specific host
test hostname:
    sudo nixos-rebuild test --flake .#{{hostname}}

# Switch NixOS configuration for specific host
switch hostname:
    sudo nixos-rebuild switch --flake .#{{hostname}}

iso: clear
    nix build .#iso --system x86_64-linux

clear:
    clear

fmt: clear
    alejandra .

check: clear
    nix flake check
