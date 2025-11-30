# Mozart409 NixOS Configuration

Personal NixOS configuration with home-manager setup.

## Structure
- `home/` - Home-manager configurations
- `hosts/` - Host-specific configurations
- `iso/` - ISO configuration

## Usage
```bash
# Rebuild configuration
sudo nixos-rebuild switch --flake .#hostname

# Home-manager rebuild
home-manager switch --flake .#hostname
```