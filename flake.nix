{
  description = "Config NixOS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = {self, nixpkgs, home-manager, ...}@inputs: { 
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {

      specialArgs = { inherit inputs; };

      modules = [
        { nixpkgs.hostPlatform = "x86_64-linux"; }
        ./configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.ben = import ./home.nix;
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
      ];
    };
  };
}
