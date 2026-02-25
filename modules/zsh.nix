{ pkgs, ... }:

{
  # --- Prompt (Starship) ---

  # Configures Starship, a fast and highly customizable cross-shell prompt.
  programs.starship = {
    enable = true;
    settings = {
      # Prevents printing an unnecessary empty line before the prompt.
      add_newline = false; 
      
      # Defines a minimalist prompt format: Directory > Git Branch > Arrow.
      format = "$directory$git_branch$character"; 
      
      # Applies the "Rosé Pine" aesthetic color palette to the prompt elements.
      directory = {
        style = "bold #ebbcba"; # Rose (Compatible with Rosé Pine Dawn/Main)
        truncation_length = 3;
        truncation_symbol = "…/";
      };
      
      git_branch = {
        style = "bold #c4a7e7"; # Iris (Purple)
        symbol = " ";
      };
      
      character = {
        success_symbol = "[➜](bold #9ccfd8)"; # Foam (Blue/Green)
        error_symbol = "[✗](bold #eb6f92)";   # Love (Red)
      };
    };
  };


  # --- Shell (Zsh) ---

  # Configures Zsh as the primary interactive shell environment.
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    
    # Enhances productivity by suggesting the remainder of a command 
    # (in grey text) based on command history.
    autosuggestion.enable = true;    
    
    # Provides real-time syntax highlighting for commands as they are typed.
    syntaxHighlighting.enable = true; 

    # Defines custom shell aliases for quicker command execution.
    # Sorted alphabetically for easier maintenance.
    shellAliases = {
      c = "clear";
      conf = "code ~/.dotfiles && exit"; 
      ga = "git add .";
      gc = "git commit -m";
      gp = "git push";
      gs = "git status";
      ll = "ls -la";
      updatel = "cd ~/.dotfiles && git add . && sudo nixos-rebuild switch --flake .#laptop1";
      updated = "cd ~/.dotfiles && git add . && sudo nixos-rebuild switch --flake .#desktop1";
      vpn = "sudo vpnc n7-vpn.conf";
      vpnd = "sudo vpnc-disconnect";
    };

    # Configures the shell's command history settings.
    history = {
      size = 10000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      # Shares command history dynamically across all active terminal sessions.
      share = true;
    };

    # Integrates specific Oh-My-Zsh plugins efficiently via Nix.
    oh-my-zsh = {
      enable = true;
      plugins = [ 
        "git"   # Provides numerous git aliases and prompt functions.
        "sudo"  # Allows prepending 'sudo' to the current command by quickly pressing ESC twice.
      ];
    };
  };
  
  
  # --- Terminal Tools (FZF) ---

  # Enables the FZF fuzzy finder and integrates it directly into Zsh.
  # This dramatically improves the reverse history search (triggered via Ctrl+R) 
  # by replacing it with a full-screen, interactive fuzzy search menu.
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}