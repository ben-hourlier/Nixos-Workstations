{
  description = "FocusOS multi-devices";

  # ====================================================================
  # --- Flake Inputs ---
  # ====================================================================
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-eclipse.url = "github:nixos/nixpkgs/69973a9a20858b467dd936542c63554f3675e02d";
    nixpkgs-yazi.url = "github:nixos/nixpkgs/bfc1b8a4574108ceef22f02bafcf6611380c100d";
    
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland/f68ac7ef7589e1536d438f7fbfb3ad987538fe0f";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    capture.url = "github:bhr-tools/Capture";
    drill.url = "github:bhr-tools/Drill";
    focus.url = "github:bhr-tools/Focus";
    workspace-manager.url = "github:bhr-tools/Workspace-Manager";
  };


  # ====================================================================
  # --- Flake Outputs ---
  # ====================================================================

  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
    let
      mkHost = hostName: nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/${hostName}/configuration.nix
            inputs.sops-nix.nixosModules.sops

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.sharedModules = [
                inputs.workspace-manager.homeManagerModules.default
                inputs.capture.homeManagerModules.default
              ];
              home-manager.users.ben = ./hosts/${hostName}/home.nix;
            }
          ];
      };
    in {
      nixosConfigurations = {
        desktop1 = mkHost "desktop1";
        laptop1 = mkHost "laptop1" ;
      };
    };
}