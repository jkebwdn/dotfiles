# MAGI icon-pack fixture

This bounded fixture renders the real production `components/controls/Icon.qml`
at 12, 16, 20 and 24 logical pixels. It covers narrow, full, complex and
multi-opacity first-party SVGs, the three semantic foreground states and one
role inherited from MAGI Legacy.

Run it independently from the shell:

```sh
python3 /home/jkebwdn/dotfiles/linux/magi/experiments/icon-pack/run.py
```

The runner copies the production component tree to a disposable configuration,
selects `magi-default` there and launches the fixture. This satisfies
Quickshell's config-root isolation while ensuring the fixture uses the actual
production `Icon.qml`. It creates a normal desktop window, does not create a
layer-shell surface or reserve desktop space, and removes the temporary copy on
exit.
