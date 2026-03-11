-- ========================================================================== --
--                                 BASIC CONFIG                               --
-- ========================================================================== --

-- Set leader bind
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.number = true             -- Display lines number
opt.mouse = 'a'               -- Allows mouse control
opt.ignorecase = true         -- Search not case sensitive...
opt.smartcase = true          -- ...except if explicit capital
opt.tabstop = 4               -- Tabulation size
opt.shiftwidth = 4            -- Indentation size
opt.expandtab = true          -- Transform tabulation into spaces
opt.wrap = true               -- Auto line break (word wrap)
opt.linebreak = true          -- Do break on a word

-- Desactivate 24-bits color to force terminal colors
opt.termguicolors = false

-- Transparent background
vim.cmd("highlight Normal ctermbg=NONE guibg=NONE")
vim.cmd("highlight NonText ctermbg=NONE guibg=NONE")
vim.cmd("highlight LineNr ctermbg=NONE guibg=NONE")
vim.cmd("highlight SignColumn ctermbg=NONE guibg=NONE")

opt.clipboard = "unnamedplus" -- Synchronize clipboard with OS

-- ========================================================================== --
--                              PLUGINS (LAZY.NVIM)                           --
-- ========================================================================== --

-- Automatic installation of lazy vim (plugin manager) 
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins config
require("lazy").setup({

    -- Telescope
    {
        'nvim-telescope/telescope.nvim', tag = '0.1.5',
        dependencies = { 'nvim-lua/plenary.nvim' }
    },

    -- Zen Mode
    {
        "folke/zen-mode.nvim",
        opts = {
            window = {
                backdrop = 1, -- Assombrit l'arrière-plan (0 pour laisser tel quel)
                width = 100,  -- Largeur de la zone de texte
                options = {
                    signcolumn = "no",      -- Enlever la colonne des icônes
                    number = false,         -- Enlever les numéros de ligne
                    cursorline = false,     -- Enlever le surlignage de la ligne
                },
            },
            plugins = {
                -- Désactive la barre d'état et les onglets en mode Zen
                options = {
                    enabled = true,
                    laststatus = 0,
                    showtabline = 0,
                },
            },
        }
    }
})

-- Force original background for Zen Mode
vim.api.nvim_set_hl(0, "ZenBg", { ctermbg = "none", bg = "none" })

-- ========================================================================== --
--                                BINDS                                       --
-- ========================================================================== --

local keymap = vim.keymap.set

-- Telescope
local builtin = require('telescope.builtin')
keymap('n', '<leader>f', builtin.find_files, { desc = "Search file" })
keymap('n', '<leader>g', builtin.live_grep, { desc = "Search text in files" })
keymap('n', '<leader>b', builtin.buffers, { desc = "Search buffers" })

-- Zen Mode
keymap('n', '<leader>z', ':ZenMode<CR>', { desc = "Toggle Zen Mode" })

-- Other
-- navigate logical lines rather than physical
keymap('n', 'j', 'gj')
keymap('n', 'k', 'gk')

keymap('n', '<leader>n', ':enew<CR>')       -- new buffer
keymap('n', '<leader>a', ':%y<CR>')         -- copy all
keymap('n', '<Esc>', '<cmd>nohlsearch<CR>') -- remove words search