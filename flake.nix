{
  description = "NixOS Flake Configuration";

  # --- Flake Inputs (Dependencies) ---
  # These are the external repositories and sources used to build the system.
  inputs = {
    # Defines the primary source for packages and system modules. 
    # The 'nixos-unstable' branch is used here to receive the latest rolling-release updates.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # Manages user-specific dotfiles and application environments.
    home-manager.url = "github:nix-community/home-manager";
    # Forces Home Manager to use the exact same version of Nixpkgs as the system.
    # This prevents duplicate package downloads and ensures better version compatibility.
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Fetches the Hyprland Wayland compositor directly from its official repository.
    # This allows the system to use the absolute latest version of Hyprland, 
    # overriding the one provided by the standard nixpkgs repository.
    hyprland.url = "github:hyprwm/Hyprland";
  };

  # --- Flake Outputs (System Configurations) ---
  # This section defines the actual systems built from the inputs defined above.
  outputs = { self, nixpkgs, home-manager, ... } @ inputs: { 
    
    # Defines a NixOS configuration named "nixos" (matches the hostname).
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      
      # Passes the entire 'inputs' attribute set to all NixOS modules.
      # This is crucial for referencing external flakes (like Hyprland) directly 
      # inside files like 'configuration.nix'.
      specialArgs = { inherit inputs; };

      # The list of modules that make up this system configuration.
      modules = [
        # Explicitly defines the architecture of the target machine.
        { nixpkgs.hostPlatform = "x86_64-linux"; }
        
        # Imports the core system settings and hardware configuration.
        ./configuration.nix

        # --- Home Manager Integration ---
        # Integrates Home Manager directly into the NixOS build process.
        # This ensures system and user configurations are built and deployed together.
        home-manager.nixosModules.home-manager
        {
          # Instructs Home Manager to use the system's instantiated 'pkgs' 
          # rather than evaluating its own private instance. This saves build time and disk space.
          home-manager.useGlobalPkgs = true;
          
          # Installs user packages into `/etc/profiles/per-user/` instead of 
          # the traditional `~/.nix-profile/`. This improves integration with the base system.
          home-manager.useUserPackages = true;

          # Points to the specific Home Manager configuration file for the user 'ben'.
          home-manager.users.ben = import ./home.nix;
          
          # Passes the flake inputs specifically down to the Home Manager modules, 
          # enabling the use of external flake packages within 'home.nix'.
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
      ];
    };
  };
}