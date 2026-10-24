"""Capabilities, not claims of native acceptance or running-process detection."""
CAPABILITIES = [
 dict(id='ghostty', label='Ghostty', support='reload-required', blur='supported', detail='Native background alpha; reload with Ctrl+Shift+,. GTK blur request and the Ghostty-only rule work together. Native four-state transparency/blur acceptance passed on Ghostty 1.3.1 / GTK 4.24.1.'),
 dict(id='zen', label='Zen', support='partial', blur='deferred', detail='Linux chrome transparency exists; current hybrid theme and workspace colours need native verification. Web content unchanged. Restart required; no alpha output yet.'),
 dict(id='gtk', label='GTK / Thunar', support='partial', blur='deferred', detail='Nested view, toolbar and dialog backgrounds need coherent styling; transparency deferred. No broad transparent CSS.'),
 dict(id='neovim', label='Neovim', support='inherits-host', blur='via-host', detail='Normal and NormalNC already use NONE. Floating panels, selections and other explicit backgrounds remain opaque.'),
 dict(id='yazi', label='Yazi / yatline', support='partial', blur='via-host', detail='Terminal-default areas inherit Ghostty; explicit cells and selection backgrounds remain intentional. yatline background disabled locally.'),
 dict(id='btop', label='btop', support='inherits-host', blur='via-host', detail='Local theme_background=false permits host transparency. Full theme polish remains Phase 12H.'),
 dict(id='starship', label='Starship', support='inherits-host', blur='via-host', detail='Prompt text uses host background; explicit segment backgrounds stay opaque.'),
 dict(id='fastfetch', label='Fastfetch', support='inherits-host', blur='via-host', detail='Terminal output inherits host; artwork and foreground colours unchanged.'),
 dict(id='hyprland', label='Hyprland', support='not-applicable', blur='engine', detail='Blurs application-supplied transparent pixels. Participation does not change global parameters. The separate opt-in global amount service owns size only while enabled.'),
]
