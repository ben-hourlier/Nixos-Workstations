{
  description = "NixOS Multi-Host Flake Configuration";

  # --- Flake Inputs ---
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";
  };


  # --- Flake Outputs ---
  
  outputs = { self, nixpkgs, home-manager, ... } @ inputs: { 
    
    # Defines multiple system configurations under 'nixosConfigurations'.
    nixosConfigurations = {
      
      # --- Desktop Configuration ---
      
      # Built using: sudo nixos-rebuild switch --flake .#desktop
      desktop1 = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.hostPlatform = "x86_64-linux"; }
          
          # Imports the system configuration specific to the desktop.
          ./hosts/desktop1/configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            
            # Points to the Home Manager configuration specific to the desktop.
            home-manager.users.ben = import ./hosts/desktop1/home.nix;
          }
        ];
      };


      # --- Laptop Configuration ---
      
      # Built using: sudo nixos-rebuild switch --flake .#laptop
      laptop1 = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.hostPlatform = "x86_64-linux"; }
          
          # Imports the system configuration specific to the laptop.
          ./hosts/laptop1/configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            
            # Points to the Home Manager configuration specific to the laptop.
            home-manager.users.ben = import ./hosts/laptop1/home.nix;
          }
        ];
      };

    };
  };
}