{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.unstable.vscode-fhs;
    profiles.default = {
      extensions = with pkgs.unstable.vscode-extensions; [
        # Global
        github.copilot-chat
        tomoki1207.pdf
        
        # C
        ms-vscode.cpptools
        ms-vscode.cpptools-extension-pack
        llvm-vs-code-extensions.vscode-clangd

        # Java
        oracle.oracle-java
        redhat.java
        tamasfe.even-better-toml
        vscjava.vscode-java-debug
        vscjava.vscode-java-dependency
        vscjava.vscode-java-pack
        vscjava.vscode-java-test
        vscjava.vscode-maven

        # Nix
        jnoortheen.nix-ide

        #OCaml
        ocamllabs.ocaml-platform

        # Phython
        ms-python.python

        # Theme
        mvllow.rose-pine
      ];

      userSettings = {
        "workbench.colorTheme" = "Rosé Pine";
        "workbench.preferredDarkColorTheme" = "Rosé Pine";
        "workbench.preferredLightColorTheme" = "Rosé Pine Dawn";
        "window.autoDetectColorScheme" = true;
        "editor.fontFamily" = "JetBrainsMono Nerd Font";
        "editor.fontSize" = 14;
        "editor.fontLigatures" = false;
        "jdk.telemetry.enabled"= false;
        "git.openRepositoryInParentFolders"= "never";
        "github.copilot.enable" = {
          "*" = false;
        };
        "C_Cpp.intelliSenseEngine" = "disabled";
      };
    };
  };
}
