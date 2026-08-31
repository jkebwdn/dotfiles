-- ---------------------------------------------------------
-- lazy.nvim bootstrap
-- ---------------------------------------------------------

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end

vim.opt.rtp:prepend(lazypath)

-- ---------------------------------------------------------
-- Plugins
-- ---------------------------------------------------------

require("lazy").setup({

    -- -----------------------------------------------------
    -- Catppuccin
    -- -----------------------------------------------------

    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,

        config = function()
            require("catppuccin").setup({
                flavour = "mocha",
                transparent_background = true,

                integrations = {
                    treesitter = true,
                    telescope = true,
                    neo_tree = true,
                    gitsigns = true,
                    which_key = true,
                    indent_blankline = {
                        enabled = true,
                        scope_color = "lavender",
                        colored_indent_levels = false,
                    },

                    native_lsp = {
                        enabled = true,
                    },
                },
            })

            vim.cmd.colorscheme("catppuccin-mocha")
        end,
    },

    -- -----------------------------------------------------
    -- Icons
    -- -----------------------------------------------------

    {
        "nvim-tree/nvim-web-devicons",
        lazy = true,
    },

    -- -----------------------------------------------------
    -- Statusline
    -- -----------------------------------------------------

    {
        "nvim-lualine/lualine.nvim",

        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },

        config = function()
            require("lualine").setup({
                options = {
                    theme = "auto",
                    icons_enabled = true,
                    component_separators = "",
                    section_separators = "",
                    globalstatus = true,
                },

                sections = {
                    lualine_a = {
                        {
                            "mode",
                            fmt = function(str)
                                return str:sub(1, 1)
                            end,
                        },
                    },

                    lualine_b = {
                        "branch",
                        "diff",
                    },

                    lualine_c = {
                        {
                            "filename",
                            path = 1,
                            symbols = {
                                modified = " ●",
                                readonly = " ",
                                unnamed = "[No Name]",
                            },
                        },
                    },

                    lualine_x = {
                        "diagnostics",
                        "encoding",
                        "filetype",
                    },

                    lualine_y = {
                        "progress",
                    },

                    lualine_z = {
                        "location",
                    },
                },
            })
        end,
    },

    -- -----------------------------------------------------
    -- Bufferline
    -- -----------------------------------------------------

    {
        "akinsho/bufferline.nvim",
        version = "*",

        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },

        config = function()
            require("bufferline").setup({
                options = {
                    mode = "buffers",
                    numbers = "none",

                    diagnostics = "nvim_lsp",

                    separator_style = "thin",

                    show_buffer_close_icons = false,
                    show_close_icon = false,

                    always_show_bufferline = false,

                    offsets = {
                        {
                            filetype = "neo-tree",
                            text = "FILES",
                            text_align = "center",
                            separator = true,
                        },
                    },
                },
            })
        end,
    },

    -- -----------------------------------------------------
    -- Treesitter
    -- -----------------------------------------------------

    {
        "nvim-treesitter/nvim-treesitter",

        lazy = false,
        build = ":TSUpdate",

        config = function()
            local ts = require("nvim-treesitter")

            ts.install({
                "lua",
                "vim",
                "vimdoc",
                "bash",
                "json",
                "toml",
                "markdown",
                "markdown_inline",
            })

            vim.api.nvim_create_autocmd("FileType", {
                pattern = {
                    "lua",
                    "vim",
                    "vimdoc",
                    "bash",
                    "json",
                    "toml",
                    "markdown",
                },

                callback = function()
                    vim.treesitter.start()

                    vim.bo.indentexpr =
                        "v:lua.require'nvim-treesitter'.indentexpr()"
                end,
            })
        end,
    },

    -- -----------------------------------------------------
    -- Neo-tree
    -- -----------------------------------------------------

    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",

        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons",
        },

        config = function()
            require("neo-tree").setup({
                close_if_last_window = true,
                popup_border_style = "rounded",

                filesystem = {
                    follow_current_file = {
                        enabled = true,
                    },

                    use_libuv_file_watcher = true,

                    filtered_items = {
                        visible = false,
                        hide_dotfiles = true,
                        hide_gitignored = false,
                    },
                },

                window = {
                    position = "left",
                    width = 32,
                },

                default_component_configs = {
                    indent = {
                        with_expanders = true,
                        expander_collapsed = "",
                        expander_expanded = "",
                    },

                    git_status = {
                        symbols = {
                            added = "✚",
                            modified = "",
                            deleted = "✖",
                            renamed = "󰁕",
                            untracked = "?",
                            ignored = "",
                            unstaged = "󰄱",
                            staged = "",
                            conflict = "",
                        },
                    },
                },
            })
        end,
    },

    -- -----------------------------------------------------
    -- Telescope
    -- -----------------------------------------------------

    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.8",

        dependencies = {
            "nvim-lua/plenary.nvim",
        },

        config = function()
            require("telescope").setup({
                defaults = {
                    prompt_prefix = "   ",
                    selection_caret = "  ",

                    sorting_strategy = "ascending",

                    layout_config = {
                        horizontal = {
                            prompt_position = "top",
                            preview_width = 0.55,
                        },

                        width = 0.90,
                        height = 0.85,
                    },

                    path_display = {
                        "truncate",
                    },

                    border = true,
                },
            })
        end,
    },

    -- -----------------------------------------------------
    -- Git signs
    -- -----------------------------------------------------

    {
        "lewis6991/gitsigns.nvim",

        config = function()
            require("gitsigns").setup({
                signs = {
                    add = {
                        text = "│",
                    },

                    change = {
                        text = "│",
                    },

                    delete = {
                        text = "_",
                    },

                    topdelete = {
                        text = "‾",
                    },

                    changedelete = {
                        text = "~",
                    },

                    untracked = {
                        text = "┆",
                    },
                },

                signcolumn = true,
                numhl = false,
                linehl = false,
                word_diff = false,
            })
        end,
    },

    -- -----------------------------------------------------
    -- Indent guides
    -- -----------------------------------------------------

    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",

        config = function()
            require("ibl").setup({
                indent = {
                    char = "│",
                },

                scope = {
                    enabled = true,
                    char = "│",
                    show_start = false,
                    show_end = false,
                },

                exclude = {
                    filetypes = {
                        "alpha",
                        "dashboard",
                        "neo-tree",
                        "help",
                    },
                },
            })
        end,
    },

    -- -----------------------------------------------------
    -- Which-key
    -- -----------------------------------------------------

    {
        "folke/which-key.nvim",
        event = "VeryLazy",

        config = function()
            require("which-key").setup({
                preset = "modern",
                delay = 300,

                win = {
                    border = "rounded",
                },
            })
        end,
    },

    -- -----------------------------------------------------
    -- Dashboard
    -- -----------------------------------------------------

    {
        "goolord/alpha-nvim",

        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },

        config = function()
            local alpha = require("alpha")
            local dashboard = require("alpha.themes.dashboard")

            dashboard.section.header.val = {
                [[                                             ]],
                [[                  N E R V I M                 ]],
                [[                                             ]],
                [[        ███╗   ██╗██╗   ██╗██╗███╗   ███╗   ]],
                [[        ████╗  ██║██║   ██║██║████╗ ████║   ]],
                [[        ██╔██╗ ██║██║   ██║██║██╔████╔██║   ]],
                [[        ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║   ]],
                [[        ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║   ]],
                [[        ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝   ]],
                [[                                             ]],
                [[              N E R V  //  T 1 5 G           ]],
                [[                                             ]],
            }

            dashboard.section.buttons.val = {
                dashboard.button(
                    "n",
                    "  New File",
                    "<cmd>ene <BAR> startinsert<CR>"
                ),

                dashboard.button(
                    "f",
                    "  Find File",
                    "<cmd>Telescope find_files<CR>"
                ),

                dashboard.button(
                    "r",
                    "  Recent Files",
                    "<cmd>Telescope oldfiles<CR>"
                ),

                dashboard.button(
                    "w",
                    "  Find Word",
                    "<cmd>Telescope live_grep<CR>"
                ),

                dashboard.button(
                    "e",
                    "  File Explorer",
                    "<cmd>Neotree toggle left<CR>"
                ),

                dashboard.button(
                    "c",
                    "  Config",
                    "<cmd>edit ~/.config/nvim/init.lua<CR>"
                ),

                dashboard.button(
                    "q",
                    "󰅚  Quit",
                    "<cmd>qa<CR>"
                ),
            }

            dashboard.section.footer.val = {
                "Neovim • Arch Linux • T15G",
            }

            dashboard.section.header.opts.hl = "Keyword"
            dashboard.section.buttons.opts.hl = "Function"
            dashboard.section.footer.opts.hl = "Comment"

            dashboard.config.opts.noautocmd = true

            alpha.setup(dashboard.config)
        end,
    },

})
