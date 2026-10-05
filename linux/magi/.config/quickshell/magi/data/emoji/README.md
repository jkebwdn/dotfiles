# Unicode Emoji metadata

`emoji.json` is generated from Unicode's Emoji **17.0** keyboard/display test
source, dated 2025-08-04, inspected/downloaded 2026-10-05:
https://www.unicode.org/Public/17.0.0/emoji/emoji-test.txt

SHA-256 of the source bytes:
`1d8a944f88d7952f7ef7c5167fef3c67995bcae24543949710231b03a201acda`.

Copyright © 2025 Unicode, Inc. Distributed under the Unicode License V3;
see [LICENSE.txt](LICENSE.txt), downloaded from https://www.unicode.org/license.txt
on 2026-10-05. No third-party database, artwork or fonts are bundled.

The 3,944 fully-qualified entries preserve every codepoint in source order,
including presentation selectors, modifiers, regional indicators and ZWJ/tag
sequences. Unqualified/minimally-qualified duplicates and standalone components
are omitted. The source supplies English emoji names (sequence labels, not
individual UCD character names), groups, subgroups and emoji introduction versions.
No supplemental CLDR keyword database or invented aliases are included.

Reproduce from the MAGI project root:

```sh
curl -fL https://www.unicode.org/Public/17.0.0/emoji/emoji-test.txt -o /tmp/magi-emoji-test-17.txt
python3 tools/generate_emoji.py /tmp/magi-emoji-test-17.txt .config/quickshell/magi/data/emoji/emoji.json
node tests/emoji/model.cjs
python3 tests/emoji/backend.py
```

The generator rejects a checksum mismatch. For a deliberate data update, review
the upstream source/license, change its URL/version/hash constants, regenerate,
update the expected count and provenance here, then run the Emoji tests. Runtime
uses only bundled JSON; it does not fetch data or spawn a process while searching.
