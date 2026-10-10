{ inputs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        inherit (prev.stdenv.hostPlatform) system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "ventoy-1.1.17"
          ];
        };
      };
      
      eclipse-java-429 = (import inputs.nixpkgs-eclipse {
        inherit (prev.stdenv.hostPlatform) system;
      }).eclipses.eclipse-modeling;

      antigravity = inputs.antigravity.packages.${prev.stdenv.hostPlatform.system}.default;

      focus = inputs.focus.packages.${prev.stdenv.hostPlatform.system}.default;
    })
  ];
}