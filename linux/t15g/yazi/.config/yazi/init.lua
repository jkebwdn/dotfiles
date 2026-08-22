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
		fg = "#b4befe",
		bg_mode = {
			normal = "#1e1e2e",
			select = "#1e1e2e",
			un_set = "#1e1e2e",
		},
	},

	style_b = {
		fg = "#9399b2",
		bg = "#1e1e2e",
	},

	style_c = {
		fg = "#cdd6f4",
		bg = "#1e1e2e",
	},

	-- Permission colours
	permissions_t_fg = "#a6e3a1",
	permissions_r_fg = "#a6e3a1",
	permissions_w_fg = "#f38ba8",
	permissions_x_fg = "#89dceb",
	permissions_s_fg = "#cdd6f4",

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
