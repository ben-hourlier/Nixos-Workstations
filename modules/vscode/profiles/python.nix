{ ext, ... }:

# Template for a new profile: copy this file, rename it, and add its
# name to the `profiles` list in ../default.nix.
#
#   extensions    names from nixpkgs (search.nixos.org, "vscode-extensions.")
#   userSettings  same keys as VSCode's settings.json
#   keybindings   same entries as VSCode's keybindings.json

{
  extensions = with ext; [
    ms-python.python
  ];

  userSettings = {
    # Settings for one language only go under "[<language>]"
    # "[python]" = { "editor.tabSize" = 4; };
  };

  keybindings = [ ];
}
