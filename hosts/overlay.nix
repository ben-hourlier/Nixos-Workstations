{ inputs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      stable = import inputs.nixpkgs-stable {
        inherit (prev.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
      
      eclipse-java-429 = (import inputs.nixpkgs-eclipse {
        inherit (prev.stdenv.hostPlatform) system;
      }).eclipses.eclipse-modeling;

      yazi = (import inputs.nixpkgs-yazi {
        inherit (prev.stdenv.hostPlatform) system;
      }).yazi;

      focus = inputs.focus.packages.${prev.stdenv.hostPlatform.system}.default;
      drill = inputs.drill.packages.${prev.stdenv.hostPlatform.system}.default;
    })
  ];
}
