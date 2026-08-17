----------------------------------------------------------------
-- Hyprland Config - S14T15G
-- Lua configuration
-- Migrated from hyprland.conf
----------------------------------------------------------------


----------------------------------------------------------------
-- MONITORS
----------------------------------------------------------------

hl.monitor({
    output   = "eDP-1",
    mode     = "3840x2160@60.00",
    position = "0x0",
    scale    = "2.00",
})

hl.monitor({
    output   = "HDMI-A-1",
    mode     = "3840x2160@239.99",
    position = "1920x32",
    scale    = "1.50",
})


----------------------------------------------------------------
-- INPUT
----------------------------------------------------------------

hl.config({
    input = {
        kb_layout = "gb",
    },
})


----------------------------------------------------------------
-- AUTOSTART
----------------------------------------------------------------

hl.on("hyprland.start", function()
    hl.exec_cmd('bash -c "wl-paste --watch cliphist store &"')

    -- If you later enable hyprpolkitagent as a systemd user service,
    -- this can be removed.
    hl.exec_cmd("/usr/bin/hyprpolkitagent")

    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hyprmon")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("~/.config/swaync/scripts/swaync-greeting.sh")
end)


----------------------------------------------------------------
-- GENERAL / WINDOW APPEARANCE
----------------------------------------------------------------

hl.config({
    general = {
        gaps_in     = 8,
        gaps_out    = 20,
        border_size = 2,

        col = {
            active_border = {
                colors = {
                    "rgba(89b4faee)",
                    "rgba(b4befeee)",
                },
                angle = 45,
            },

            inactive_border = "rgba(595959aa)",
        },

        layout = "dwindle",
    },


    decoration = {
        rounding = 8,

        blur = {
            enabled           = true,
            size              = 8,
            passes            = 4,

            ignore_opacity    = true,
            new_optimizations = true,
            xray              = false,

            brightness        = 0.90,
            contrast          = 0.92,
            noise             = 0.015,
            vibrancy          = 0.15,
            vibrancy_darkness = 0.50,
        },

        shadow = {
            enabled      = true,
            range        = 20,
            render_power = 2,

            -- Equivalent to rgba(0,0,0,0.35)
            color = "rgba(00000059)",
        },
    },


    animations = {
        enabled = true,
    },
})


----------------------------------------------------------------
-- DWINDLE
----------------------------------------------------------------

hl.config({
    dwindle = {
        preserve_split = true,
    },
})


----------------------------------------------------------------
-- ANIMATIONS
----------------------------------------------------------------

hl.curve("myBezier", {
    type   = "bezier",
    points = {
        { 0.05, 0.90 },
        { 0.10, 1.05 },
    },
})

hl.animation({
    leaf    = "windows",
    enabled = true,
    speed   = 7,
    bezier  = "myBezier",
})

hl.animation({
    leaf    = "border",
    enabled = true,
    speed   = 10,
    bezier  = "default",
})

hl.animation({
    leaf    = "fade",
    enabled = true,
    speed   = 7,
    bezier  = "default",
})

hl.animation({
    leaf    = "workspaces",
    enabled = true,
    speed   = 6,
    bezier  = "default",
})


----------------------------------------------------------------
-- SWAYNC LAYER POLISH
----------------------------------------------------------------

hl.layer_rule({
    name = "swaync-control-center",

    match = {
        namespace = "swaync-control-center",
    },

    blur         = true,
    ignore_alpha = 0.08,
    no_anim      = true,
})


hl.layer_rule({
    name = "swaync-notification-window",

    match = {
        namespace = "swaync-notification-window",
    },

    blur         = true,
    ignore_alpha = 0.12,
    no_anim      = true,
})


----------------------------------------------------------------
-- KEYBINDS
----------------------------------------------------------------

local SUPER = "SUPER"


----------------------------------------------------------------
-- Applications / session
----------------------------------------------------------------

hl.bind(
    SUPER .. " + RETURN",
    hl.dsp.exec_cmd("ghostty")
)

hl.bind(
    SUPER .. " + Q",
    hl.dsp.window.close()
)

hl.bind(
    SUPER .. " + SHIFT + R",
    hl.dsp.exec_cmd("hyprctl reload")
)

-- Session exit
hl.bind(
    SUPER .. " + SHIFT + Q",
    hl.dsp.exit()
)


----------------------------------------------------------------
-- SwayNC
----------------------------------------------------------------

hl.bind(
    SUPER .. " + N",
    hl.dsp.exec_cmd("swaync-client -t")
)


----------------------------------------------------------------
-- Rofi
----------------------------------------------------------------

hl.bind(
    SUPER .. " + SPACE",
    hl.dsp.exec_cmd("rofi -show drun")
)


----------------------------------------------------------------
-- MFTrunk - Connectivity Hub
----------------------------------------------------------------

hl.bind(
    SUPER .. " + C",
    hl.dsp.exec_cmd(
        "ghostty --title=MFTrunk -e /home/jkebwdn/.local/bin/mftrunk"
    )
)


----------------------------------------------------------------
-- FOCUS NAVIGATION
----------------------------------------------------------------

hl.bind(
    SUPER .. " + left",
    hl.dsp.focus({ direction = "left" })
)

hl.bind(
    SUPER .. " + right",
    hl.dsp.focus({ direction = "right" })
)

hl.bind(
    SUPER .. " + up",
    hl.dsp.focus({ direction = "up" })
)

hl.bind(
    SUPER .. " + down",
    hl.dsp.focus({ direction = "down" })
)


----------------------------------------------------------------
-- MOVE WINDOWS
----------------------------------------------------------------

hl.bind(
    SUPER .. " + SHIFT + left",
    hl.dsp.window.move({ direction = "left" })
)

hl.bind(
    SUPER .. " + SHIFT + right",
    hl.dsp.window.move({ direction = "right" })
)

hl.bind(
    SUPER .. " + SHIFT + up",
    hl.dsp.window.move({ direction = "up" })
)

hl.bind(
    SUPER .. " + SHIFT + down",
    hl.dsp.window.move({ direction = "down" })
)


----------------------------------------------------------------
-- WORKSPACES 1-9
----------------------------------------------------------------

for i = 1, 9 do

    hl.bind(
        SUPER .. " + " .. i,
        hl.dsp.focus({ workspace = i })
    )

    hl.bind(
        SUPER .. " + SHIFT + " .. i,
        hl.dsp.window.move({ workspace = i })
    )

end


----------------------------------------------------------------
-- WINDOW CONTROLS
----------------------------------------------------------------

hl.bind(
    SUPER .. " + V",
    hl.dsp.window.float({
        action = "toggle",
    })
)

hl.bind(
    SUPER .. " + F",
    hl.dsp.window.fullscreen({
        mode   = "fullscreen",
        action = "toggle",
    })
)


----------------------------------------------------------------
-- DWINDLE PRESELECT
----------------------------------------------------------------

hl.bind(
    SUPER .. " + H",
    hl.dsp.layout("preselect l")
)

hl.bind(
    SUPER .. " + L",
    hl.dsp.layout("preselect r")
)

hl.bind(
    SUPER .. " + K",
    hl.dsp.layout("preselect u")
)

hl.bind(
    SUPER .. " + J",
    hl.dsp.layout("preselect d")
)


----------------------------------------------------------------
-- MOUSE
----------------------------------------------------------------

hl.bind(
    SUPER .. " + mouse:272",
    hl.dsp.window.drag(),
    {
        mouse = true,
    }
)

hl.bind(
    SUPER .. " + mouse:273",
    hl.dsp.window.resize(),
    {
        mouse = true,
    }
)


----------------------------------------------------------------
-- MULTIMEDIA KEYS
----------------------------------------------------------------

hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("pamixer -i 5"),
    {
        locked    = true,
        repeating = true,
    }
)

hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("pamixer -d 5"),
    {
        locked    = true,
        repeating = true,
    }
)

hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd("pamixer -t"),
    {
        locked    = true,
        repeating = true,
    }
)

hl.bind(
    "XF86MonBrightnessUp",
    hl.dsp.exec_cmd("brightnessctl set +5%"),
    {
        locked    = true,
        repeating = true,
    }
)

hl.bind(
    "XF86MonBrightnessDown",
    hl.dsp.exec_cmd("brightnessctl set 5%-"),
    {
        locked    = true,
        repeating = true,
    }
)


----------------------------------------------------------------
-- KEYBOARD BACKLIGHT
----------------------------------------------------------------

hl.bind(
    "XF86KbdBrightnessUp",
    hl.dsp.exec_cmd(
        "brightnessctl -d tpacpi::kbd_backlight set +1"
    )
)

hl.bind(
    "XF86KbdBrightnessDown",
    hl.dsp.exec_cmd(
        "brightnessctl -d tpacpi::kbd_backlight set 0"
    )
)


----------------------------------------------------------------
-- ALT-TAB STYLE SWITCHING
----------------------------------------------------------------

hl.bind(
    SUPER .. " + TAB",
    hl.dsp.focus({
        last = true,
    })
)


----------------------------------------------------------------
-- SCREENSHOTS
----------------------------------------------------------------

hl.bind(
    "Print",
    hl.dsp.exec_cmd(
        "hyprshot -m output -o ~/Pictures/Screenshots"
    )
)

hl.bind(
    "SHIFT + Print",
    hl.dsp.exec_cmd(
        "hyprshot -m region -o ~/Pictures/Screenshots"
    )
)

hl.bind(
    SUPER .. " + Print",
    hl.dsp.exec_cmd(
        "hyprshot -m window -o ~/Pictures/Screenshots"
    )
)


----------------------------------------------------------------
-- OPTIONAL SCREENSHOT-TO-CLIPBOARD VARIANTS
----------------------------------------------------------------

-- hl.bind(
--     "Print",
--     hl.dsp.exec_cmd("hyprshot -m output -c")
-- )
--
-- hl.bind(
--     "SHIFT + Print",
--     hl.dsp.exec_cmd("hyprshot -m region -c")
-- )
--
-- hl.bind(
--     SUPER .. " + Print",
--     hl.dsp.exec_cmd("hyprshot -m window -c")
-- )
