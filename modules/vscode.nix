{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      jnoortheen.nix-ide
      ms-python.python
      ms-vscode.cpptools
      oracle.oracle-java

      mvllow.rose-pine
    ];

    userSettings = {
      "workbench.colorTheme" = "Rosé Pine";
      "workbench.preferredDarkColorTheme" = "Rosé Pine";
      "workbench.preferredLightColorTheme" = "Rosé Pine Dawn";
      "window.autoDetectColorScheme" = true;
      "editor.fontFamily" = "JetBrainsMono Nerd Font";
      "editor.fontSize" = 14;
      "editor.fontLigatures" = true;
    };
  };
}
