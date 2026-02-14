{ pkgs, ... }:

{
  # 1. STARSHIP (Le Prompt)
  # C'est la ligne de commande jolie et rapide
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false; # Pas de ligne vide inutile au début
      format = "$directory$git_branch$character"; # Minimaliste : Dossier > Git > Flèche
      
      # Configuration des couleurs (Rosé Pine)
      directory = {
        style = "bold #ebbcba"; # Rose (Rose Pine Dawn/Main compatible)
        truncation_length = 3;
        truncation_symbol = "…/";
      };
      
      git_branch = {
        style = "bold #c4a7e7"; # Iris (Violet)
        symbol = " ";
      };
      
      character = {
        success_symbol = "[➜](bold #9ccfd8)"; # Foam (Bleu/Vert)
        error_symbol = "[✗](bold #eb6f92)";   # Love (Rouge)
      };
    };
  };

  # 2. ZSH (Le Shell)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    
    # LE GRAS DU SUJET : Productivité
    autosuggestion.enable = true;    # Suggère la fin de ta commande en gris
    syntaxHighlighting.enable = true; # Colorie la commande en vert/rouge

    # Tes alias (Raccourcis)
    shellAliases = {
      ll = "ls -la";
      c = "clear";
      
      # Raccourcis NixOS
      update = "cd ~/dotfiles && git add . && sudo nixos-rebuild switch --flake .";
      conf = "code ~/dotfiles && exit"; # Ouvre VSCode dans ta config
      
      # Raccourcis Git
      gs = "git status";
      ga = "git add .";
      gc = "git commit -m";
      gp = "git push";
    };

    # Historique (Pour retrouver tes commandes d'il y a 3 mois)
    history = {
      size = 10000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      share = true;
    };

    # Plugins utiles (via Oh My Zsh, mais géré par Nix)
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" ];
      # Git permet d'afficher les informations Git
      # Sudo permet d'ajouter sudo devant la commande en pressant deux fois "esc"
    };
  };
  
  # Historique des commandes accessible avec ctrl+r
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}