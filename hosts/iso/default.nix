{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../common/locale.nix
    ../common/nix-settings.nix
  ];

  # Basic host configuration
  networking = {
    hostName = "default-iso";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [22];
    };
  };

  # User configuration with default password
  users.users.amadeus = {
    isNormalUser = true;
    description = "amadeus";
    extraGroups = ["networkmanager" "wheel" "docker"];
    shell = pkgs.zsh;
    initialPassword = lib.mkForce "amadeus";
    openssh.authorizedKeys.keys = [
    ];
  };

  programs.zsh.enable = true;
  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  # Enable passwordless sudo for wheel group
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # Bootloader configuration for LXC
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 10;

  # Home-manager configuration
  home-manager.users.amadeus.home.stateVersion = "25.11";

  # System state version
  system.stateVersion = "25.11";
}
