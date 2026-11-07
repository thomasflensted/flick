## Software Architecture

- Channel YAGNI in everything you do. When in doubt, ask.
- Do not do premature optimizations.
- Always look and opt for the simplest solution.
- Respect DRY - extract duplicated code.
- Respect SOLID principles.
- Write functions that do exactly one thing.
- Extract pure functions that can be easily tested.
- Extract business rules to separate functions. The naming of the function alone justifies the extraction.
- Put all functions and files in appropriate packages/folders/files.
- Do not optimize for or handle theoretical or near-theoretical edge cases. Tell the user if in doubt.
- Do not use type casting (`as`, `as?`, `as!`).
- Do not write comments. The code should be self-explanatory. Only add comments if something is genuinely hard to understand or there's a weird reason something needs to be done in a special way.

## Testing

- Write tests when it makes sense. Do not over-test.
- Do not write tautological tests
- Think of tests bottom-up. Rather many small and fast unit tests, than large and slow e2e tests.

## Git / GitHub

- Work trunk-based: finish a feature, then commit it straight to `main` and push. Don't create branches or pull requests.
- Give branches short and descriptive names. Do not include "claude/" or random id's.
- Always run the test suite (`swift test`) before pushing, and only push when it passes.

## Project

A small native macOS launcher (Raycast replacement): ⌘Space opens a search panel for
quicklinks, apps and Google search. SwiftPM project; `./build.sh` builds and installs to
/Applications (`--no-install` to only build into `build/Flick.app`). `swift test` runs the tests.

Pure logic (templates, URL handling, matching, ranking, Raycast parsing) lives in `Sources/FlickCore`
and is unit tested in `Tests/FlickCoreTests`. `Sources/Flick` is the AppKit/SwiftUI app.

## Editing quicklinks (for agents)

Quicklinks are a plain JSON array at:

    ~/Library/Application Support/Flick/quicklinks.json

Flick re-reads the file every time the panel opens, so edits apply immediately with no restart.
Only `name` and `link` are required; `id` is generated if missing (keep existing ids so usage ranking survives).

```json
[
  { "name": "GitHub", "link": "https://github.com" },
  { "name": "Search GitHub", "keyword": "gh", "link": "https://github.com/search?q={argument}" },
  { "name": "Linear", "link": "https://linear.app", "openWith": "com.google.Chrome" },
  { "name": "Projects folder", "link": "~/Developer" }
]
```

- `link`: URL, app URL scheme (e.g. `slack://`), or file/folder path (`/…` or `~/…`).
- `{argument}` is replaced by the text typed after the name or keyword (URL-encoded for URLs).
  `{argument name="x" default="y"}` sets the input label and the value used when nothing is typed.
- `keyword`: optional short alias. Typing `gh react` runs "Search GitHub" with `react`.
- `openWith`: optional bundle id (`com.google.Chrome`, `com.apple.Safari`, `company.thebrowser.Browser`)
  or a path to a `.app`. Omit to use the default handler.

Write valid JSON (validate with `python3 -m json.tool <file>`). If the file is invalid,
Flick keeps the last good list and shows an error row in the panel.

Usage counts for ranking live in `usage.json` next to it.

## Editing snippets (for agents)

Snippets are a plain JSON array at `~/Library/Application Support/Flick/snippets.json`, reloaded the
same way as quicklinks. Only `name` and `text` are required.

```json
[
  { "name": "Work email", "keyword": "@@w", "text": "me@work.com" },
  { "name": "Test email", "keyword": "@test", "text": "me+{id}@work.com" }
]
```

- `keyword`: typing it in any app at the start of a word replaces it with the text.
- `{id}` becomes a random 8-character nano id each time the snippet is inserted.
