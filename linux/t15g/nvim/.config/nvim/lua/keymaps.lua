-- ---------------------------------------------------------
-- Keymaps
-- ---------------------------------------------------------

local map = vim.keymap.set

-- Neo-tree
map("n", "<leader>e", "<cmd>Neotree toggle left<CR>", {
    desc = "Toggle file explorer",
})

-- Telescope
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", {
    desc = "Find files",
})

map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", {
    desc = "Find text",
})

map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", {
    desc = "Recent files",
})

-- Easier window movement
map("n", "<C-Left>", "<C-w>h")
map("n", "<C-Down>", "<C-w>j")
map("n", "<C-Up>", "<C-w>k")
map("n", "<C-Right>", "<C-w>l")
