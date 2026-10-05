# Emoji Picker evidence — inspected 2026-10-05

Installed versions: Quickshell 0.3.1 / Arch 0.3.1-1; Hyprland 0.56.2 /
Arch 0.56.2-4, commit `efb50993780079460b0cbed1363e2166a2de1d9f`;
wl-clipboard 2.3.0; noto-fonts-emoji 2.051. Baseline Git HEAD was locally
verified as `4f4205dd021a44ce88acad3869799edfcc243ab2`, Calendar / Date Surface.
No upstream implementation or visual assets were copied.

## Local data audit and Unicode selection

Local `pacman -Q` / `/usr/share` inspection found GTK3 3.24.52 and GTK4 4.22.5
emoji gresources, Vim/Neovim enumeration scripts, Perl emoji property tables,
and Noto Color Emoji. No installed unicode-emoji, unicode-character-database or
cldr-emoji-annotation package, plain `emoji-test.txt`, sequence files or English
CLDR annotation XML was found. GTK's localized binary bundles were not decoded:
this audit does not claim that their metadata is unusable, only that a complete,
versioned group/subgroup dataset was not available as a plain installed source.
Vim's `tools/emoji_list.vim` and Neovim's `scripts/emoji_list.lua` enumerate
individual codepoints; they do not demonstrate support for complete sequences.

Source: [Unicode Emoji 17.0 emoji-test.txt](https://www.unicode.org/Public/17.0.0/emoji/emoji-test.txt),
dated 2025-08-04; [Unicode License V3](https://www.unicode.org/license.txt).
Inspected/downloaded 2026-10-05; documentation/data version 17.0, no repository
commit assumed. Header describes qualification, codepoint sequences and CLDR
ordering; data rows provide names, groups and subgroups. MAGI's
`tools/generate_emoji.py:parse/generate` selects fully-qualified rows, checks
sequence spelling and duplicates, and pins the source SHA-256. License and
attribution accompany the generated JSON. See [reproduction instructions](../../.config/quickshell/magi/data/emoji/README.md).

Compatibility: Python standard library generator; Qt reads pre-generated UTF-8
JSON. Font rendering depends on the installed font's coverage, independently of
exact stored/copied sequences. No assumption that every Emoji 17 glyph renders
on this font version. English search only; no supplemental CLDR keyword aliases.
Tests cover ordinary/VS16/modifier/ZWJ/flag/tag sequences. Broader newest-glyph
and platform rendering acceptance remains open.

## Focus and reservation

Sources: Quickshell **v0.3.1**
[WlrKeyboardFocus](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/WlrKeyboardFocus/),
[ExclusionMode](https://quickshell.org/docs/v0.3.1/types/Quickshell/ExclusionMode/),
[Process](https://quickshell.org/docs/v0.3.1/types/Quickshell.Io/Process/),
[FileView](https://quickshell.org/docs/v0.3.1/types/Quickshell.Io/FileView/).
Inspected 2026-10-05; versioned documentation, no repository revision inferred.

Exclusive requests exclusive keyboard input; Ignore does not set an exclusion
zone. `Process` accepts argv and writes stdin without shell interpolation;
`FileView` loads local bytes/text. `EmojiWindow` follows the installed, working
`LauncherWindow` overlay pattern; only this thin host uses layer-shell APIs.
`Emoji` loads JSON once and sends one JSON-line to the clipboard helper. The
helper uses bounded stdin parsing and the shared `copy_payload` path, with errors
reported before closing. Neither content nor search requires a native window.

Compatibility: real component tests ran under Quickshell 0.3.1; offscreen cannot
prove compositor focus or pointer dismissal. Live status verified dataset load,
registered shortcut and unchanged 48px reservation. Physical key, pointer,
previous-app focus and multi-output acceptance are tracked in the
[checkpoint](../design/emoji-picker.md), not inferred from API documentation.

## Clipboard and optional insertion

Source: installed MAGI `services/clipboard_backend.py:Worker.command` restore
branch at baseline `4f4205d`, and installed `wl-copy` 2.3.0. The pre-existing restore
path passes MIME and exact bytes to `wl-copy`; this milestone extracts it into
`copy_payload` and adds a bounded `--copy-text` entry point. This is the same
clipboard mechanism with the existing watcher/history policy, not a second
capture service. Mock subprocess and real QML-process tests verify UTF-8 bytes,
error behavior and no newline appended to the copied sequence. The operator confirmed actual clipboard selection/paste works; no initial
clipboard was read by the automated tests.

Source: [Hyprland dispatchers](https://wiki.hypr.land/Configuring/Basics/Dispatchers/),
inspected 2026-10-05, current unversioned documentation; installed 0.56.2.
`hl.dsp.send_shortcut` provides synthesized key events. That capability alone
does not demonstrate universally correct paste or text insertion: terminals and
other clients use different paste commands, and focus restoration is asynchronous.
Neither wtype nor ydotool is installed. **Design decision:** do not inject paste;
copy, close, user pastes. No package added. A future insertion mode would require
separate focus/target/capability tests; it is not promised by this architecture.

## Shortcut audit

The installed Lua configuration and all 54 active Hyprland binds were inspected
before editing. No SUPER+period, SUPER+literal-dot, keycode 60 or SUPER catch-all
conflict was found. A single `hl.bind(SUPER .. " + period", ...)` calls
`quickshell ipc -c magi call emoji toggle`. Live registration subsequently showed
modmask 64 and key `period`; `hyprctl configerrors` was empty. The change was
approved through the filesystem escalation for the sibling Hyprland file.
Physical-key activation was subsequently confirmed by the operator. No compositor restart or package cleanup was performed.
