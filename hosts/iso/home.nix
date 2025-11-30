{
  config,
  lib,
  pkgs,
  ...
}: {
  import = [
    ../../home/git.nix
    ../../home/shared.nix
    ../../home/tmux.nix
    ../../home/utils.nix
    ../../home/zsh.nix
    ../../home/fun.nix
    ../../home/nixvim/nixvim.nix
    ../../home/terminals/alacritty.nix
  ];
}
