" -----------------------------------
" Neovim Clean Config (Catppuccin)
" -----------------------------------

" Basics
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set cursorline
set clipboard=unnamedplus
set termguicolors
set background=dark

" Plugin manager
call plug#begin('~/.local/share/nvim/plugged')

" Theme
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }

" Statusline + icons
Plug 'nvim-lualine/lualine.nvim'
Plug 'nvim-tree/nvim-web-devicons'

" Treesitter (better syntax highlighting)
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

call plug#end()

" --- Catppuccin setup (Lua) ---
lua << EOF
require("catppuccin").setup({
  flavour = "mocha",               -- latte, frappe, macchiato, mocha
  transparent_background = true,   -- let Alacritty’s bg show through
  integrations = {
    treesitter = true,
    lualine = true,
  },
})
EOF

" Apply colorscheme
colorscheme catppuccin-mocha

" Lualine themed to Catppuccin
lua << EOF
require('lualine').setup({
  options = { theme = 'catppuccin', icons_enabled = true }
})
EOF

