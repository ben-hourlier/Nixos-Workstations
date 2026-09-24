{ inputs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        inherit (prev.stdenv.hostPlatform) system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "ventoy-1.1.12"
          ];
        };
      };
      
      eclipse-java-429 = (import inputs.nixpkgs-eclipse {
        inherit (prev.stdenv.hostPlatform) system;
      }).eclipses.eclipse-java;

      antigravity = inputs.antigravity.packages.${prev.stdenv.hostPlatform.system}.default;
    })
  ];
}