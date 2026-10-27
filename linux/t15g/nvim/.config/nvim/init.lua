-- ---------------------------------------------------------
-- Neovim — T15G
-- ---------------------------------------------------------

require("options")
require("keymaps")
require("plugins")

-- MAGI BOOTSTRAP v1 BEGIN
do
    local path = (os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")) .. "/magi/theme-orchestrator/neovim/current"
    if vim.fn.filereadable(path .. "/colors/magi.lua") == 1 then
        vim.opt.runtimepath:prepend(path)
        vim.cmd.colorscheme("magi")
    end
end
-- MAGI BOOTSTRAP v1 END
