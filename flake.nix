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
    lib = nixpkgs.lib;
    linuxSystem = "x86_64-linux";
    darwinSystem = "x86_64-darwin";
    username = "amadeus";

    # Helper function to generate host configurations (system-agnostic)
    mkHost = hostname: system:
      if system == linuxSystem then
        lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs username;};
          modules = [
            ./hosts/${hostname}/default.nix
            home-manager.nixosModules.home-manager
            {
              nix.settings.trusted-users = [username];
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.sharedModules = [inputs.nixvim.homeModules.nixvim];
            }
          ];
        }
      else
        throw "Host configuration for ${system} is not supported yet";

    # Helper function to generate home-manager configurations
    mkHome = hostname: system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {inherit inputs username;};
        modules = [
          ./hosts/${hostname}/home.nix
          inputs.nixvim.homeModules.nixvim
        ];
      };
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
      "${username}@iso" = mkHome "iso" linuxSystem;
      # Add more user/host combinations here:
      # "${username}@laptop" = mkHome "laptop" linuxSystem;
      # "user@server" = mkHome "server" linuxSystem;
    };

    # Nixos Generator (Linux only) - standalone ISO configuration
    iso = nixos-generators.nixosGenerate {
      system = linuxSystem;
      format = "iso";
      modules = [
        ./hosts/iso/default.nix
        home-manager.nixosModules.home-manager
        ({pkgs, ...}: {
          # set disk size to to 20G
          virtualisation.diskSize = 20 * 1024;
          system.stateVersion = "25.11";
        })
        {
          nix.settings.trusted-users = [username];
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${username} = import ./hosts/iso/home.nix;
          home-manager.sharedModules = [inputs.nixvim.homeModules.nixvim];
        }
      ];
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
      ${linuxSystem}.default = let
        pkgs = nixpkgs.legacyPackages.${linuxSystem};
      in pkgs.mkShell {
        buildInputs = with pkgs; [
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

      ${darwinSystem}.default = let
        pkgs = nixpkgs.legacyPackages.${darwinSystem};
      in pkgs.mkShell {
        buildInputs = with pkgs; [
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

    # Flake checks for CI validation
    checks = {
      ${linuxSystem} = {
        # Check NixOS configuration builds
        nixos-iso = self.nixosConfigurations.iso.config.system.build.toplevel;
        
        # Check home-manager configuration builds
        home-amadeus-iso = self.homeConfigurations."${username}@iso".activationPackage;
        
        # Check flake formatting
        formatting = let
          pkgs = nixpkgs.legacyPackages.${linuxSystem};
        in pkgs.runCommand "check-formatting" {
          buildInputs = [pkgs.alejandra];
        } ''
          alejandra --check ${./.}
          touch $out
        '';
      };
    };

    # Formatter for consistent code formatting
    formatter = {
      ${linuxSystem} = nixpkgs.legacyPackages.${linuxSystem}.alejandra;
      ${darwinSystem} = nixpkgs.legacyPackages.${darwinSystem}.alejandra;
    };
  };
}
