{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.ghostty = {
    enable = true;
  };

  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        decorations = "Full";
        dynamic_padding = true;
        padding = {
          x = 5;
          y = 5;
        };
        startup_mode = "Windowed";
        dynamic_title = true;
      };

      general.working_directory = "/home/amadeus/code";
      scrolling.history = 10000;

      font = {
        normal.family = "JetBrainsMono Nerd Font";
        bold.family = "JetBrainsMono Nerd Font";
        italic.family = "JetBrainsMono Nerd Font";
        size = 13;
      };

      window.opacity = 1.0;
    };
  };
}
