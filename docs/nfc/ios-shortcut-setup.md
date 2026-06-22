# NFC tag writing on book pages

Staff with editor access can write NFC tags from a book’s show page. Android uses WebNFC in Chrome; iPhone uses a one-time Shortcuts setup.

## Android (Chrome)

1. Open the book page in Chrome on an NFC-capable Android phone.
2. Tap **Write NFC tag**.
3. Allow NFC access if prompted.
4. Hold the top of the phone near the blank tag until you see confirmation.

Tags are written with two records:

- A **URL** that opens the book page when tapped
- A **JSON** record with ISBN, title, authors, and location (shortened if needed to fit the tag)

Use NTAG215 tags or larger when possible. Smaller tags (NTAG213) may truncate metadata.

Production requires HTTPS. Local development on `http://localhost` is allowed for WebNFC.

## iPhone (Shortcuts)

iOS cannot write multiple NDEF records from Safari. The library writes the **book URL only** via Shortcuts.

### One-time setup

1. Install the **Write Library Book Tag** shortcut (see your admin for the iCloud link, or build it below).
2. If you rename the shortcut, set `NFC_IOS_SHORTCUT_NAME` in `.env` to match.

### Build the shortcut

1. Open the **Shortcuts** app → **+** → name it **Write Library Book Tag**.
2. Add action **Set NFC Tag**.
3. For the URL, choose **Shortcut Input** (the shortcut receives text from the library website).
4. Save the shortcut.

Optional: share it via iCloud and distribute the link to other editors.

### Writing a tag

1. Open the book page in Safari.
2. Tap **Write NFC tag**.
3. Confirm **Open in Shortcuts** if asked.
4. When Shortcuts prompts, hold the phone to the tag.

Use **Copy book link** if you prefer to paste the URL into NFC Tools or another writer manually.

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `NFC_IOS_SHORTCUT_NAME` | `Write Library Book Tag` | Name passed to `shortcuts://run-shortcut` |
| `NFC_TAG_MAX_BYTES` | `496` | Max estimated NDEF size for Android dual-record writes |
| `APP_BASE_URL` | — | Canonical host for URLs written to tags |
