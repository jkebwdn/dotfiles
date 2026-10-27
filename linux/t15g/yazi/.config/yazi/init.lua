-- MAGI BOOTSTRAP v1 BEGIN
local magi = {accent="#b4befe", background="#1e1e2e", muted="#9399b2", text="#cdd6f4", green="#a6e3a1", red="#f38ba8", teal="#89dceb"}
do
    local path = (os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")) .. "/magi/theme-orchestrator/yazi/current/yatline.lua"
    local file = io.open(path, "r")
    if file then file:close(); magi = dofile(path) end
end
-- MAGI BOOTSTRAP v1 END
require("yatline"):setup({
	show_background = false,

	display_header_line = false,
	display_status_line = true,

	section_separator = {
		open = "",
		close = "",
	},

	part_separator = {
		open = "",
		close = "",
	},

	inverse_separator = {
		open = "",
		close = "",
	},

	padding = {
		inner = 1,
		outer = 1,
	},

	-- Catppuccin Mocha / transparent-looking sections
	style_a = {
		fg = magi.accent,
		bg_mode = {
			normal = magi.background,
			select = magi.background,
			un_set = magi.background,
		},
	},

	style_b = {
		fg = magi.muted,
		bg = magi.background,
	},

	style_c = {
		fg = magi.text,
		bg = magi.background,
	},

	-- Permission colours
	permissions_t_fg = magi.green,
	permissions_r_fg = magi.green,
	permissions_w_fg = magi.red,
	permissions_x_fg = magi.teal,
	permissions_s_fg = magi.text,

	status_line = {
		left = {
			section_a = {
				{
					type = "string",
					name = "hovered_name",
				},
			},

			section_b = {},
			section_c = {},
		},

		right = {
			section_a = {},
			section_b = {},

			section_c = {
				{
					type = "coloreds",
					name = "permissions",
				},
			},
		},
	},
})
