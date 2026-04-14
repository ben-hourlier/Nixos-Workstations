{
  description = "FocusOS multi-devices";

  # ====================================================================
  # --- Flake Inputs ---
  # ====================================================================
  
  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/bfc1b8a4574108ceef22f02bafcf6611380c100d";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-stable";

    hyprland.url = "github:hyprwm/Hyprland";
  };


  # ====================================================================
  # --- Flake Outputs ---
  # ====================================================================
  

  outputs = { self, nixpkgs-stable, nixpkgs-unstable, home-manager, ... } @ inputs:

    let
      system = "x86_64-linux";
      
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

    in {
      # Variables pkgs, config and lib are automatically given to home.nix and configuration.nix
      # (or equivalent). To add other variables, use SpecialArgs or extraSpecialArgs
      nixosConfigurations = {

        # --- Desktop Configuration ---
        
        # Built using: sudo nixos-rebuild switch --flake .#desktop1
        desktop1 = nixpkgs-stable.lib.nixosSystem {
          specialArgs = { inherit inputs unstable system; };
          modules = [
            { nixpkgs.hostPlatform = system; }
            
            ./hosts/desktop1/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs unstable system; };
              home-manager.users.ben = import ./hosts/desktop1/home.nix;
            }
          ];
        };


        # --- Laptop Configuration ---
        
        # Built using: sudo nixos-rebuild switch --flake .#laptop1
        laptop1 = nixpkgs-stable.lib.nixosSystem {
          specialArgs = { inherit inputs system; };
          modules = [
            { nixpkgs.hostPlatform = system; }
            
            ./hosts/laptop1/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs unstable system; };
              home-manager.users.ben = import ./hosts/laptop1/home.nix;
            }
          ];
        };
      };
    };
}