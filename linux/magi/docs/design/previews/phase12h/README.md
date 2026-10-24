# Phase 12H status disclosure

Production Settings components, fake backend, software/offscreen renderer.
These show status presentation, not native app reload evidence. Compact and Dawn
captures were visually inspected; text and foreground retain normal contrast.

| Capture | Scene |
|---|---|
| [Normal](01-appearance-normal.png) | Appearance first frame; no new page |
| [Healthy](02-healthy.png) | Healthy supported targets, including next-launch states |
| [Mixed](03-mixed.png) | Running Zen requires restart; Ghostty reload requested |
| [Failure](04-failure.png) | Local reload failure; valid generated config retained |
| [Compact](05-compact.png) | 760px width |
| [Dawn](06-dawn.png) | Genuine light theme |

Reproduce with `MAGI_PHASE12H_PREVIEWS=<absolute-directory> python linux/magi/tests/phase12h/presentation.py`.
The same test exercises the actual 450ms QML debounce with a fake worker and verifies
that rapid A/B/C selection produces one C request. No live application is contacted.
