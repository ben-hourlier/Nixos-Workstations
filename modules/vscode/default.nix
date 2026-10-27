{ pkgs, lib, ... }:

# ====================================================================
# --- VSCode, one profile per ecosystem ---
# ====================================================================
#
#   base.nix            what every profile gets (theme, editor, Claude, Nix...)
#   profiles/<name>.nix what one ecosystem adds on top of base
#
# The "default" profile is base alone: VSCode uses it for any folder
# that has no profile assigned (e.g. this NixOS config).
#
# Add a profile:    copy profiles/python.nix to profiles/<name>.nix,
#                   edit it, add "<name>" to `profiles` below.
# Use a profile:    open the folder, gear icon > Profiles > <name>.
#                   VSCode remembers the choice for that folder.
#
# Notes:
# - Extensions can only be installed through Nix (the extensions folder
#   is read-only as soon as there is more than one profile).
# - Close VSCode before rebuilding when you add a new profile, otherwise
#   VSCode overwrites the profile list when it exits.

let
  ext = pkgs.unstable.vscode-extensions;
  base = import ./base.nix { inherit ext; };

  profiles = [
    "c"
    "java"
    "ocaml"
    "python"
  ];

  # A profile = base + its own extensions, settings and keybindings.
  # Settings with the same key: the profile wins over base.
  withBase = profile: {
    extensions = base.extensions ++ (profile.extensions or [ ]);
    userSettings = lib.recursiveUpdate base.userSettings (profile.userSettings or { });
    keybindings = (base.keybindings or [ ]) ++ (profile.keybindings or [ ]);
  };

  loadProfile = name: withBase (import ./profiles/${name}.nix { inherit ext pkgs; });
in
{
  programs.vscode = {
    enable = true;
    package = pkgs.unstable.vscode-fhs;
    profiles = { default = withBase { }; } // lib.genAttrs profiles loadProfile;
  };
}
