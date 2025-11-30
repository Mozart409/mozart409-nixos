{
  description = "NixOS multi-host configuration with home-manager and nixvim";

  nixConfig = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://nixvim.cachix.org"
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nixvim.cachix.org-1:key1CvQ9TbRj2UeMvq8F7Kz8L5X6Z9YcWdVfBnHmGpKs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixvim,
    nixos-generators,
    colmena,
    hyprland,
    hyprland-plugins,
    quickshell,
    caelestia-shell,
    disko,
  } @ inputs: let
    # Helper function to generate host configurations
    mkHost = hostname: system:
      lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/${hostname}/default.nix
          home-manager.nixosModules.home-manager
          {
            nix.settings.trusted-users = ["amadeus"];
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules = [inputs.nixvim.homeModules.nixvim];
          }
        ];
      };

    # Helper function to generate home-manager configurations
    mkHome = hostname: system:
      home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {inherit inputs;};
        modules = [
          ./hosts/${hostname}/home.nix
          inputs.nixvim.homeModules.nixvim
        ];
      };

    lib = nixpkgs.lib;
    linuxSystem = "x86_64-linux";
    darwinSystem = "x86_64-darwin";
  in {
    # NixOS configurations for each host (Linux only)
    nixosConfigurations = {
      iso = mkHost "iso" linuxSystem;
      # Add more hosts here:
      # laptop = mkHost "laptop" linuxSystem;
      # server = mkHost "server" linuxSystem;
    };

    # Home-manager configurations for each user/host
    homeConfigurations = {
      "amadeus@iso" = mkHome "iso" linuxSystem;
      # Add more user/host combinations here:
      # "amadeus@laptop" = mkHome "laptop" linuxSystem;
      # "user@server" = mkHome "server" linuxSystem;
    };

    # Nixos Generator (Linux only)
    iso = nixos-generators.nixosGenerate {
      system = linuxSystem;
      modules = [
        ({pkgs, ...}: {
          # set disk size to to 20G
          virtualisation.diskSize = 20 * 1024;
          system.stateVersion = "25.11";
        })
        ./hosts/iso/default.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.amadeus = import ./hosts/iso/home.nix;
          home-manager.sharedModules = [inputs.nixvim.homeModules.nixvim];
        }
      ];
      format = "iso";
    };

    # Colmena configuration for multi-host deployment (Linux only)
    colmenaHive = colmena.lib.makeHive {
      meta = {
        nixpkgs = import nixpkgs {
          system = linuxSystem;
          config.allowUnfree = true;
        };
        specialArgs = {inherit inputs;};
      };
    };

    # Development shells for both Linux and Darwin
    devShells = {
      ${linuxSystem}.default = nixpkgs.legacyPackages.${linuxSystem}.mkShell {
        buildInputs = with nixpkgs.legacyPackages.${linuxSystem}; [
          git
          nh
          alejandra
          colmena.packages.${linuxSystem}.colmena
        ];
        shellHook = ''
          echo "Welcome to the NixOS configuration development shell!"
          echo "Available commands:"
          echo "  nix flake check .#nixosConfigurations.iso"
          echo "  nix flake check .#homeConfigurations.amadeus@iso"
          echo "  sudo nixos-rebuild switch --flake .#iso"
          echo "  home-manager switch --flake .#amadeus@iso"
        '';
      };

      ${darwinSystem}.default = nixpkgs.legacyPackages.${darwinSystem}.mkShell {
        buildInputs = with nixpkgs.legacyPackages.${darwinSystem}; [
          git
          alejandra
        ];
        shellHook = ''
          echo "Welcome to the NixOS configuration development shell (Darwin)!"
          echo "This shell provides tools for working with the configuration."
          echo "Note: NixOS-specific features are not available on macOS."
        '';
      };
    };
  };
}
