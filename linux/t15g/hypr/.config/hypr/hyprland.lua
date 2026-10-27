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
    hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_STATE_HOME XDG_SESSION_ID XDG_SESSION_TYPE XDG_CURRENT_DESKTOP DISPLAY && systemctl --user start magi-hypridle.service")
    hl.exec_cmd("hyprmon")
    hl.exec_cmd("quickshell -c magi")
end)


----------------------------------------------------------------
-- GENERAL / WINDOW APPEARANCE
----------------------------------------------------------------

hl.config({
    general = {
        gaps_in     = 8,
        gaps_out = {
                        top = 6,
                        right = 18,
                        bottom = 20,
                        left = 18,
                    },
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
-- Notifications
----------------------------------------------------------------

hl.bind(
    SUPER .. " + N",
    hl.dsp.exec_cmd("quickshell ipc -c magi call hub toggle notifications")
)


----------------------------------------------------------------
-- MAGI applications and Settings
----------------------------------------------------------------

hl.bind(
    SUPER .. " + SPACE",
    hl.dsp.exec_cmd("quickshell ipc -c magi call hub toggle apps")
)

-- Direct Emoji Hub route.
hl.bind(
    SUPER .. " + E",
    hl.dsp.exec_cmd("quickshell ipc -c magi call hub toggle emoji")
)

-- First-party MAGI clipboard history; SUPER+V remains the floating toggle.
hl.bind(
    SUPER .. " + C",
    hl.dsp.exec_cmd("quickshell ipc -c magi call hub toggle clipboard")
)


----------------------------------------------------------------
-- MAGI anchored surfaces
----------------------------------------------------------------

hl.bind(SUPER .. " + M", hl.dsp.exec_cmd("quickshell ipc -c magi call magi toggle controlcentre"))
hl.bind(SUPER .. " + W", hl.dsp.exec_cmd("quickshell ipc -c magi call magi toggle wifi"))
hl.bind(SUPER .. " + B", hl.dsp.exec_cmd("quickshell ipc -c magi call magi toggle bluetooth"))
hl.bind(SUPER .. " + A", hl.dsp.exec_cmd("quickshell ipc -c magi call magi toggle audio"))
hl.bind(SUPER .. " + T", hl.dsp.exec_cmd("quickshell ipc -c magi call magi toggle tray"))

hl.bind(SUPER .. " + S", hl.dsp.exec_cmd("quickshell ipc -c magi call hub open settings"))

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

-- MAGI Settings is a normal Quickshell desktop window. Match its stable title
-- as well as Quickshell's process-wide app ID so shell layer surfaces are not
-- affected by this rule.
hl.window_rule({
    name = "magi-settings-window",
    match = {
        class = "^org\\.quickshell$",
        title = "^MAGI Settings$",
    },
    float = true,
    center = true,
    size = "940 720",
})

-- Clipboard is a normal focused-on-open window, without a keyboard grab.
hl.window_rule({
    name = "magi-clipboard-window",
    match = {
        class = "^org\\.quickshell$",
        title = "^MAGI Clipboard$",
    },
    float = true,
    center = true,
    size = "540 660",
})

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

-- MAGI BOOTSTRAP v1 BEGIN
do
    local path = (os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")) .. "/magi/theme-orchestrator/hyprland/current/colors.lua"
    local file = io.open(path, "r")
    if file then file:close(); dofile(path) end
end
-- MAGI BOOTSTRAP v1 END

-- hyprmon: managed monitor profile include
do
    local path = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/hyprmon.lua"
    local file = io.open(path, "r")
    if file then
        file:close()
        require("hyprmon")
    end
end

-- MAGI APPLICATION BACKGROUND BEGIN -- after operator rules/includes
-- One immutable Ghostty-only rule. No opacity options or generated include.
do
    local uuid = assert(io.open("/proc/sys/kernel/random/uuid", "r"))
    magi_application_background = {
        generation = assert(uuid:read("*l")),
        rule = hl.window_rule({
            name = "magi-ghostty-background-no-blur",
            match = {class = "^com\\.mitchellh\\.ghostty$"},
            enabled = false,
            no_blur = true,
        }),
    }
    uuid:close()
end
-- MAGI APPLICATION BACKGROUND END
