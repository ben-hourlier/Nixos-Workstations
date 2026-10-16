{
  description = "FocusOS multi-devices";

  # ====================================================================
  # --- Flake Inputs ---
  # ====================================================================
  
  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/bfc1b8a4574108ceef22f02bafcf6611380c100d";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-eclipse.url = "github:nixos/nixpkgs/69973a9a20858b467dd936542c63554f3675e02d";
    
    home-manager.url = "github:nix-community/home-manager/cbd8a72e5fe6af19d40e2741dc440d9227836860";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-stable";

    hyprland.url = "github:hyprwm/Hyprland/f68ac7ef7589e1536d438f7fbfb3ad987538fe0f";
    antigravity.url = "github:jacopone/antigravity-nix";

    focus.url = "github:bhr-tools/Focus";
  };


  # ====================================================================
  # --- Flake Outputs ---
  # ====================================================================

  outputs = { self, nixpkgs-stable, nixpkgs-unstable, nixpkgs-eclipse, home-manager, focus, ... } @ inputs:
    let
      mkHost = hostName: nixpkgs-stable.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/${hostName}/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
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