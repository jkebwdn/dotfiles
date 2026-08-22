-- =========================================================
-- Neovim
-- Mac mini — Everforest Dark Hard
-- =========================================================

vim.opt.termguicolors = true
vim.opt.background = "dark"

-- Everforest
vim.g.everforest_background = "hard"
vim.g.everforest_better_performance = 1

vim.cmd.colorscheme("everforest")

-- ---------------------------------------------------------
-- Editor appearance
-- ---------------------------------------------------------

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"

vim.opt.showmode = false
vim.opt.laststatus = 3

vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- ---------------------------------------------------------
-- Indentation
-- ---------------------------------------------------------

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

-- ---------------------------------------------------------
-- Search
-- ---------------------------------------------------------

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true

-- ---------------------------------------------------------
-- General quality-of-life
-- ---------------------------------------------------------

vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
