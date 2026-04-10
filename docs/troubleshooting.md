# Troubleshooting

---

## Watcher isn't running

**Symptom:** `launchctl list | grep odcus` shows a dash instead of a PID, or returns nothing.

**Check the log first:**
```bash
cat ~/.local/logs/odcus-knowhow-watcher.log
```

**Common causes:**

*Script path wrong in plist*
Open `~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist` and confirm the path to `watcher.sh` matches where you actually put it. The path must be absolute — no `~`.

*Script not executable*
```bash
chmod +x ~/.local/bin/odcus-knowhow-watcher.sh
```

*fswatch not found*
The script calls `/opt/homebrew/bin/fswatch` (Apple Silicon Homebrew path). Intel Macs use `/usr/local/bin/fswatch`. Check:
```bash
which fswatch
```
Update the path in `watcher.sh` if needed.

*Plist not loaded*
```bash
launchctl load ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
```

---

## File dropped but nothing happens

**Check the log:**
```bash
tail -20 ~/.local/logs/odcus-knowhow-watcher.log
```

**Common causes:**

*File extension not on allowlist*
The log will show `SKIP unsupported extension (.xyz): filename`. Add the extension to `ALLOWED_EXTENSIONS` in `watcher.sh` and restart the service.

*File dropped into a subfolder*
The watcher only monitors the top level of `WATCH_DIR`. Files in subfolders are ignored by design. Drop the file directly into the root of the watch folder.

*File is a hidden or temp file*
Files starting with `.` or `~` are skipped. This covers macOS `.DS_Store` and Office temp files (`~$document.docx`).

*OneDrive sync lag*
If you're watching a OneDrive folder, the file may not be fully synced to disk when fswatch fires. The 2-second sleep handles most cases, but very slow connections may need a longer delay. Edit `sleep 2` in `watcher.sh`.

---

## Conversion failed

**Symptom:** Log shows `ERROR: Conversion failed for filename.pdf`

**Try converting manually:**
```bash
uvx markitdown "/path/to/the/file.pdf"
```

If this fails too, the file may be:
- Password-protected (markitdown cannot read encrypted PDFs)
- Corrupted or incomplete
- A scanned image PDF with no embedded text (markitdown extracts text, not OCR)

For scanned PDFs, you need an OCR step before markitdown. Tools like `ocrmypdf` can add a text layer first:
```bash
brew install ocrmypdf
ocrmypdf input.pdf input-ocr.pdf
uvx markitdown input-ocr.pdf
```

---

## markitdown produces empty or near-empty output

**Symptom:** The `.md` file is created but contains almost nothing.

**Likely cause:** The source file has no extractable text. Common with:
- Image-only PDFs (scanned documents, photographed pages)
- Heavily formatted PPTX files where content is in text boxes not recognized as text
- Password-protected or DRM-restricted files

**Fix for scanned PDFs:** Add an OCR layer with `ocrmypdf` before conversion (see above).

**Fix for PPTX:** Export the presentation as PDF first, then drop the PDF.

---

## QMD not finding results

**Symptom:** Claude searches the collection and returns nothing, or returns irrelevant results.

**Check QMD is running:**
```bash
qmd status
```

**Check the collection is indexed:**
```bash
qmd list odcus-knowhow
```

If the document count is 0 or much lower than expected, trigger a re-index:
```bash
qmd reindex odcus-knowhow
```

**Check the path in your MCP config:**
The `QMD_COLLECTIONS` path must be an absolute path to the folder containing the markdown files. Confirm it matches the actual location of your `knowhow/` folder.

**Check articles exist in the discipline folders:**
QMD indexes the curated wiki articles (`cyber/`, `compliance/`, etc.), not the raw intake files. If you've dropped files but haven't run `/odcus-kb-compile`, there may be nothing in the discipline folders yet.

---

## Service keeps crashing

**Symptom:** launchd restarts the service repeatedly, PID changes on every check.

**Check the log for repeated errors:**
```bash
tail -50 ~/.local/logs/odcus-knowhow-watcher.log
```

**Common cause:** The watch directory path contains spaces or special characters that aren't properly quoted, or the directory doesn't exist at the path specified.

Confirm the path exists:
```bash
ls "/path/to/your/watch-dir"
```

If OneDrive sync is incomplete, the folder may not exist yet. Wait for OneDrive to finish syncing.

---

## Log file is growing too large

The log rotates automatically at 10 MB. If you're generating a lot of activity and want more frequent rotation, adjust the threshold in `watcher.sh`:

```bash
# Change 10485760 (10 MB) to 1048576 (1 MB)
if (( $(stat -f%z "$LOG" 2>/dev/null || echo 0) > 1048576 )); then
```

---

## Restarting after changes to watcher.sh

Any edit to `watcher.sh` requires a service restart to take effect:

```bash
launchctl unload ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
launchctl load ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
```

Confirm the new version is running:
```bash
tail -5 ~/.local/logs/odcus-knowhow-watcher.log
# Should show "Watcher started" with a recent timestamp
```
