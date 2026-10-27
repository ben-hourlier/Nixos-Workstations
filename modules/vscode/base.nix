{ ext }:

# Shared by every profile. Only put here what is useful in any project.

{
  extensions = with ext; [
    # Global
    anthropic.claude-code
    tomoki1207.pdf

    # Theme
    mvllow.rose-pine

    # Languages used everywhere
    jnoortheen.nix-ide # Nix
    myriad-dreamin.tinymist # Typst
    tamasfe.even-better-toml # TOML
  ];

  userSettings = {
    # Theme: follows the system light/dark state
    "workbench.colorTheme" = "Rosé Pine";
    "workbench.preferredDarkColorTheme" = "Rosé Pine";
    "workbench.preferredLightColorTheme" = "Rosé Pine Dawn";
    "window.autoDetectColorScheme" = true;

    # Layout
    "workbench.secondarySideBar.defaultVisibility" = "hidden";
    "workbench.startupEditor" = "none";

    # Editor
    "editor.fontFamily" = "JetBrainsMono Nerd Font";
    "editor.fontSize" = 14;
    "editor.fontLigatures" = false;

    # Git
    "git.openRepositoryInParentFolders" = "never";

    # AI
    "github.copilot.enable" = {
      "*" = false;
    };
  };

  keybindings = [ ];
}
