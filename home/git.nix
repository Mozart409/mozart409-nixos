{
  config,
  pkgs,
  lib,
  ...
}: {
  programs = {
    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
    };
    git = {
      enable = true;
      settings = {
        user.name = "Amadeus Mader";
        user.email = "amadeus@mozart409.com";
        aliases = {
          ci = "commit";
          s = "status";
          f = "fetch";
        };
        signing = {
          signByDefault = true;
          format = "ssh";
        };
        init.defaultBranch = "main";
        pull.rebase = "true";
        credential = {
          helper = "oauth";
          cache = "--timeout 21600";
        };
      };
      ignores = [
        "*~"
        "*.swp"
      ];
    };
    lazygit = {
      enable = true;
      settings.gui.theme = {
        activeBorderColor = ["#89b4fa" "bold"];
        inactiveBorderColor = ["#a6adc8"];
        optionsTextColor = ["#89b4fa"];
        selectedLineBgColor = ["#313244"];
        selectedRangeBgColor = ["#313244"];
        unstagedChangesColor = ["#f38ba8"];
        defaultFgColor = ["#cdd6f4"];
        searchingActiveBorderColor = ["#f9e2af"];
      };
    };
  };
}
