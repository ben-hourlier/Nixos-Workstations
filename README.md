# NixOS Workstations

Declarative, reproducible multi-machine configurations and desktop environments managed via Nix Flakes and Home Manager.

## 1. Architecture Overview

This repository maintains the system configuration and user environments for multiple personal workstations from a single declarative source of truth.

```
├── flake.nix             # Flake entrypoint and dependency pinning
├── hosts/                # Machine-specific configurations
│   ├── common-*.nix      # Shared system and user profiles
│   ├── desktop1/         # High-performance workstation (dual-GPU virtualization)
│   └── laptop1/          # Mobile workstation (power management)
├── modules/              # Reusable functional modules (services, audio, packages)
├── settings/             # Program-specific configurations (Hyprland, Neovim, Kitty)
├── scripts/              # Lightweight system utilities packaged via Nix derivations
└── themes/               # Coordinated light/dark assets and dynamic switching
```

## 2. Target Machines

| **Host**       | **Type**    | **Target Workload**               | **Key Hardware / Modules**                |
| -------------- | ----------- | --------------------------------- | ----------------------------------------- |
| **`desktop1`** | Workstation | High-performance dev & compute    | Dual-GPU passthrough / KVM virtualization |
| **`laptop1`**  | Laptop      | Mobile productivity & development |                                           |

## 3. Key Design Principles

- **Fully Declarative State:** Every package, system service, terminal configuration, and compositor binding is declared via Nix. No out-of-band manual configuration.
    
- **Separation of Concerns:**
    
    - `hosts/common-*.nix` provides the base system invariants across all targets.
        
    - Host-specific modules isolate hardware variations (virtualization, displays, power).
        
- **Decoupled Desktop Environment:** Built on Wayland (Hyprland), using modular configuration fragments for input, autostart, and keybindings.
    
- **Hermetic Utility Packaging:** Shell helpers and automation scripts (`scripts/`) are packaged as individual Nix derivations with explicit runtime dependencies, avoiding reliance on global system binaries.
    
- **Atomic Theme Synchronization:** A unified dynamic switcher script coordinates palette transitions across the window manager, Kitty, and application profiles. The Quickshell bar follows the active theme on its own.
    

## 4. Deployment

Deploying or rebuilding a host requires a Nix installation with flakes enabled.

### Rebuild Current Host

```
sudo nixos-rebuild switch --flake .#desktop1
sudo nixos-rebuild switch --flake .#laptop1
```

## 5. Repository Hygiene

- **Zero Plaintext Secrets:** All sensitive credentials are verified against `sops.nix` and encrypted via SOPS before commit.
    
- **Reproducibility:** Upstream channels (`nixpkgs`) and third-party tools are pinned via `flake.lock`.
