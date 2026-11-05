{ inputs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        inherit (prev.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
      
      eclipse-java-429 = (import inputs.nixpkgs-eclipse {
        inherit (prev.stdenv.hostPlatform) system;
      }).eclipses.eclipse-modeling;

      focus = inputs.focus.packages.${prev.stdenv.hostPlatform.system}.default;
      drill = inputs.drill.packages.${prev.stdenv.hostPlatform.system}.default;
    })
  ];
}