-- ==========================================
-- CONFIGURATION DE BASE
-- ==========================================

-- Activer les numéros de ligne
vim.opt.number = true

-- Activer la souris
vim.opt.mouse = 'a'

-- Gestion des tabulations (4 espaces par défaut)
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true -- Transforme les tabs en espaces

-- Recherche intelligente (ignore la casse sauf si majuscule)
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- ==========================================
-- PRESSE-PAPIER (CLIPBOARD)
-- ==========================================

-- Synchronisation de nvim et du clipboard
vim.opt.clipboard = "unnamedplus"