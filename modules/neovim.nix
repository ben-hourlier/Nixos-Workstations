{ pkgs, ... }:

{
  # 1. Installation des outils externes (LSP, formateurs, dépendances)
  home.packages = with pkgs; [
    # Outils système requis par les plugins
    ripgrep      # Pour que Telescope cherche ultra vite
    fd           # Pour trouver les fichiers
    gcc          # Pour compiler les langages (Treesitter)
    wl-clipboard # Pour copier/coller avec le système
    
    # Langages (Syntaxe & Outils)
    # On n'installe pas les serveurs lourds (LSP) pour l'instant vu que tu veux du Zen,
    # mais on installe de quoi gérer la syntaxe.
    tree-sitter
    lua-language-server
    nixfmt-classic
    stylua
    markdownlint-cli
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # 2. Les Plugins (Installés via Nix pour la stabilité)
    plugins = with pkgs.vimPlugins; [
      # Le moteur de plugins (pour charger le reste proprement)
      lazy-nvim
      
      # UI & Thème
      rose-pine              # Ton thème
      alpha-nvim             # Dashboard d'accueil minimaliste
      lualine-nvim           # Barre d'état (configurée minimaliste)
      zen-mode-nvim          # Mode concentration (centre le texte, cache tout)
      
      # Navigation
      telescope-nvim         # Recherche floue
      telescope-fzf-native-nvim
      oil-nvim               # Explorateur de fichiers "Zen" (édition en mode texte)
      
      # Code & Syntaxe
      nvim-treesitter.withAllGrammars # Coloration syntaxique intelligente
      render-markdown-nvim   # Rend le Markdown joli directement dans l'éditeur
      gitsigns-nvim          # Juste des petits signes dans la marge pour Git
    ];

    # 3. La Configuration Lua
    extraLuaConfig = ''
      -- ============================
      -- 1. OPTIONS DE BASE
      -- ============================
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.clipboard = "unnamedplus"
      vim.opt.tabstop = 4
      vim.opt.shiftwidth = 4
      vim.opt.expandtab = true
      vim.opt.termguicolors = true
      
      -- Thème
      require("rose-pine").setup({ disable_background = true })
      vim.cmd("colorscheme rose-pine")

      -- ============================
      -- 2. SCRATCHPAD (BROUILLON)
      -- ============================
      -- <Espace> + s ouvre un fichier temporaire
      vim.keymap.set('n', '<leader>s', function()
          vim.cmd('enew')           -- Ouvre un nouveau buffer vide
          vim.bo.buftype = 'nofile' -- Définit comme "non-fichier" (pas de sauvegarde)
          vim.bo.bufhidden = 'wipe' -- Le détruit dès qu'on le quitte
          vim.bo.swapfile = false   -- Pas de fichier swap inutile
          print("Mode Brouillon : Pas de sauvegarde")
      end, { desc = 'Nouveau Brouillon' })

      -- ============================
      -- 3. PLUGINS (LUALINE & AUTRES)
      -- ============================
      
      -- La configuration Lualine qui posait problème
      require('lualine').setup({
        options = {
          theme = 'rose-pine',
          section_separators = "",    -- C'est ici que tu avais l'erreur
          component_separators = "|", -- Nix n'aimait pas la virgule ici
          globalstatus = true,
        },
        sections = {
          lualine_a = {'mode'},
          lualine_b = {'branch', 'diff'},
          lualine_c = {'filename'},
          lualine_x = {'filetype'},
          lualine_y = {},
          lualine_z = {'location'}
        }
      })

      -- Config Oil (Explorateur)
      require("oil").setup({
        default_file_explorer = true,
        view_options = { show_hidden = true },
      })
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Ouvrir dossier parent" })

      -- Config Markdown
      require('render-markdown').setup({})

      -- Config Telescope
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Trouver Fichier' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Trouver Texte' })
      
      -- Config Zen Mode
      vim.keymap.set("n", "<leader>z", "<cmd>ZenMode<cr>", { desc = "Mode Zen" })
    ''; 
    # ^^^ TRÈS IMPORTANT : Ne pas oublier ce '' et le ; à la fin
  };
}