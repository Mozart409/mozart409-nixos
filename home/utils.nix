{
  config,
  pkgs,
  lib,
  ...
}: {
  programs = {
    fastfetch.enable = true;
    ripgrep.enable = true;
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
