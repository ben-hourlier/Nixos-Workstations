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

    antigravity.url = "github:jacopone/antigravity-nix";
  };


  # ====================================================================
  # --- Flake Outputs ---
  # ====================================================================

  outputs = { self, nixpkgs-stable, nixpkgs-unstable, home-manager, ... } @ inputs:

    {
      nixosConfigurations = {

        desktop1 =  
        let

          system = "x86_64-linux";
    
          unstable = import nixpkgs-unstable {
            inherit system;
            config = {
              allowUnfree = true;
              permittedInsecurePackages = [
                "ventoy-1.1.12"
              ];
            };
          };

        in nixpkgs-stable.lib.nixosSystem {
          specialArgs = { inherit inputs unstable system; };
          modules = [
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


        laptop1 = 
        let 
          system = "x86_64-linux";

          unstable = import nixpkgs-unstable {
            inherit system;
            config = {
              allowUnfree = true;
              permittedInsecurePackages = [
                "ventoy-1.1.12"
              ];
            };
          };
        in nixpkgs-stable.lib.nixosSystem {
          specialArgs = { inherit inputs unstable system; };
          modules = [
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