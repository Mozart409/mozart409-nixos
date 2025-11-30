{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "user"
      "@wheel"
      "amadeus"
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-generations +3";
  };

  # Allow unfree packages on all hosts
  nixpkgs.config.allowUnfree = true;
}
