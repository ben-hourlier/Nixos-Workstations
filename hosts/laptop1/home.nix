{ config, pkgs, inputs, ... }:

{
  imports = [
    ../common-home.nix
  ];

  # --- User Information ---

  # Determines the release version from which default settings are inherited.
  # Similar to the NixOS stateVersion, this should generally be left at the version 
  # of the initial installation to avoid breaking changes in user-level databases or paths.
  home.stateVersion = "25.11";

}