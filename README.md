# FocusOS

> **FocusOS** is a distraction-free and focus-optimized multi-device desktop setup powered by NixOS and Flakes.

The goal of this project is to create a seamless, minimal, and highly efficient workflow that stays consistent across different machines while keeping performance, focus and productivity at its core. It is built to minimize virtual noise and maximize deep work.

## Key Features
- **Distraction-Free**: A minimalist UI and UX designed to eliminate visual noise
    - Zero notification ;
    - All settings and informations in one clean bar ;
    - All applications accessible from a unique menu ;
- **Optimized Workflow**: Integrated scripts and tools for instant productivity.
    - Super fast tab-switcher ;
    - Minimalist clipboard manager ;
    - Built-in deepwork and pomodoro tool.
- **Nix Flakes based**: Reproducible and declarative system configuration across multiple hosts.

- **Modular Architecture**: Clean separation between system settings, user modules, packages, and themes.
- **Multi-device support**: Tailored configurations for different hardware profiles found in the `hosts/` directory.

## Main programs

- **Compositor**: [Hyprland](https://hyprland.org/ "null") (Wayland-based, dynamic tiling). (hypridle, hyprlock, hyprpaper, hyprpicker, hyprshot)
- **Status Bar**: [Waybar](https://github.com/Alexays/Waybar "null") (Highly customized with CSS).
- **App Launcher**: [Fuzzel](https://codeberg.org/dnkl/fuzzel "null")
- **Terminal**: [Kitty](https://sw.kovidgoyal.net/kitty/ "null")
- **Shell & Prompt**: Zsh
- **File Manager**: [Yazi](https://rosepinetheme.com/fr/) (with clic & drag function)
- **Notification Daemon**: [Mako](https://wayland.emersion.fr/mako/ "null") (with all notifications blocked by default)
    
- **Colorscheme (dark/light)**: Optimized for eye comfort : [Rose Pine](https://rosepinetheme.com/fr/)

## Project Structure

```
├── hosts/      # Machine-specific configurations (Desktop, Laptop, etc.)
├── modules/    # Reusable configuration blocks (NixOS & Home-manager)
├── packages/   # Custom packages, scripts, and overlays
├── scripts/    # Utility scripts for workflow automation
├── settings/   # Global configuration variables and constants
└── themes/     # Visual styling, colors, and UI consistency
```

## Getting Started

### Prerequisites

- **NixOS** installed on your system.
    
- **Flakes** enabled in your `nix.conf`:
    
    ```
    experimental-features = nix-command flakes
    ```
    

### Installation

1. **Clone the repository:**
    
    ```
    git clone [https://github.com/jarvis-ed1th/FocusOS.git](https://github.com/jarvis-ed1th/FocusOS.git)
    cd FocusOS
    ```
    
2. **Apply configuration (dry-run first recommended):**
    
    ```
    # Replace [hostname] with your specific host name from the hosts/ directory
    sudo nixos-rebuild test --flake .#[hostname]
    ```
    
3. **Permanent switch:**
    
    ```
    sudo nixos-rebuild switch --flake .#[hostname]
    ```
