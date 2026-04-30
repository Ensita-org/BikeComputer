# BikeComputer

iOS cycling computer app with GPS tracking, live metrics, and ride history.

## Adding a New Language

Localizable strings live in `Sources/<lang>.lproj/Localizable.strings`. The file-system-synchronized build group picks up any new `.lproj` folder automatically — no Xcode project file changes are needed.

**Steps:**

1. Copy the English base as a starting point:
   ```bash
   cp -r Sources/en.lproj Sources/<lang_code>.lproj
   ```
   Use the ISO 639-1 code (e.g. `de` for German, `it` for Italian, `pt` for Portuguese).

2. Open `Sources/<lang_code>.lproj/Localizable.strings` and translate every **value** (right-hand side of `=`). Never change the **keys** (left-hand side).

   ```
   "History" = "Verlauf";   ← correct: only the value is translated
   "Verlauf" = "Verlauf";   ← wrong: key must stay as the English string
   ```

3. Build the app (`⌘B`) and change the simulator language via **Settings → General → Language & Region** (or use the scheme's *App Language* option in **Product → Scheme → Edit Scheme → Run → Options**) to verify the translation.

4. Commit the new `.lproj` folder.

## Supported Languages

| Code | Language |
|------|----------|
| `en` | English  |
| `fr` | French   |
| `es` | Spanish  |
| `pl` | Polish   |
