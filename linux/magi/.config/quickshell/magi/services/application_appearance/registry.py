"""Capabilities, not claims of native acceptance or running-process detection."""
CAPABILITIES = [
 dict(id='ghostty', label='Ghostty', support='reload-required', blur='supported', detail='Native background transparency with Hyprland blur. Fully quit and reopen Ghostty once after installing the launch integration; subsequent appearance changes use normal config reload.'),
 dict(id='zen', label='Zen', support='partial', blur='deferred', detail='Linux chrome transparency exists; current hybrid theme and workspace colours need native verification. Web content unchanged. Restart required; no alpha output yet.'),
 dict(id='gtk', label='GTK / Thunar', support='next-launch', blur='supported', detail='Thunar main-window background alpha with compositor blur. Relaunch Thunar after changes. Text, icons, controls, menus and dialogs remain opaque; other GTK applications stay unchanged.'),
 dict(id='neovim', label='Neovim', support='inherits-host', blur='via-host', detail='Normal and NormalNC already use NONE. Floating panels, selections and other explicit backgrounds remain opaque.'),
 dict(id='yazi', label='Yazi / yatline', support='partial', blur='via-host', detail='Terminal-default areas inherit Ghostty; explicit cells and selection backgrounds remain intentional. yatline background disabled locally.'),
 dict(id='btop', label='btop', support='inherits-host', blur='via-host', detail='Local theme_background=false permits host transparency. Full theme polish remains Phase 12H.'),
 dict(id='starship', label='Starship', support='inherits-host', blur='via-host', detail='Prompt text uses host background; explicit segment backgrounds stay opaque.'),
 dict(id='fastfetch', label='Fastfetch', support='inherits-host', blur='via-host', detail='Terminal output inherits host; artwork and foreground colours unchanged.'),
 dict(id='hyprland', label='Hyprland', support='not-applicable', blur='engine', detail='Blurs application-supplied transparent pixels. Participation does not change global parameters. The separate opt-in global amount service owns size only while enabled.'),
]
