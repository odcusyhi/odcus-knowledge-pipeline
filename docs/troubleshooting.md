# Troubleshooting

---

## Watcher isn't running

**Symptom:** `launchctl list | grep odcus` shows a dash instead of a PID, or returns nothing.

**Check the log first:**
```bash
cat ~/.local/logs/knowhow-watcher.log
```

**Common causes:**

*Script path wrong in plist*
Open `~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist` and confirm the path to `knowhow-watcher.sh` matches where you put it. Must be an absolute path — no `~`.

*Script not executable*
```bash
chmod +x ~/.local/bin/knowhow-watcher.sh
```

*fswatch not found at expected path*
The script calls `/opt/homebrew/bin/fswatch` (Apple Silicon Homebrew path). Intel Macs use `/usr/local/bin/fswatch`. Check:
```bash
which fswatch
```
Update the path at the bottom of `watcher.sh` if needed.

*Plist not loaded*
```bash
launchctl load ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
```

---

## File dropped but nothing happens

**Check the log:**
```bash
tail -20 ~/.local/logs/knowhow-watcher.log
```

**Common causes:**

*Extension not on allowlist*
Log will show `SKIP unsupported extension (.xyz): filename`. Add the extension to `ALLOWED_EXTENSIONS` in `watcher.sh` and restart the service.

*File is in a subfolder*
The watcher monitors top-level only. Files in subfolders are ignored. Drop the file directly into the root of the watch folder.

*Hidden or temp file*
Files starting with `.` or `~` are skipped. This covers `.DS_Store` and Office temp files (`~$document.docx`).

*Cloud sync lag*
If the drop zone is a synced folder (OneDrive, Dropbox), the file may not be fully written to disk when fswatch fires. The 2-second sleep handles most cases. Slow connections may need a longer delay — edit `sleep 2` in `watcher.sh`.

---

## Conversion failed

**Symptom:** Log shows `ERROR: Conversion failed for filename.pdf`

**Try converting manually:**
```bash
uvx markitdown "/path/to/the/file.pdf"
```

If this also fails, the file may be:
- Password-protected (markitdown cannot read encrypted PDFs)
- Corrupted or incomplete
- A scanned image PDF with no embedded text layer

For scanned PDFs, add an OCR layer first:
```bash
brew install ocrmypdf
ocrmypdf input.pdf input-ocr.pdf
uvx markitdown input-ocr.pdf
```

---

## markitdown produces empty or near-empty output

**Likely cause:** No extractable text in the source file. Common with:
- Image-only PDFs (scanned documents, photographed pages)
- Heavily formatted PPTX files where content is in unrecognized text boxes
- DRM-restricted files

**Fix for scanned PDFs:** Add an OCR layer with `ocrmypdf` before conversion (see above).

**Fix for PPTX:** Export as PDF first, then drop the PDF.

---

## QMD not finding results

**Symptom:** Claude searches the collection and returns nothing, or irrelevant results.

**Check QMD is running:**
```bash
qmd status
```

**Check the collection is indexed:**
```bash
qmd list my-knowhow
```

If the document count is 0 or lower than expected, trigger a re-index:
```bash
qmd reindex my-knowhow
```

**Check the path in your MCP config**
The `QMD_COLLECTIONS` path must be absolute and point to the folder containing your markdown files. Confirm it matches the actual location.

**Check articles exist in the discipline folders**
QMD indexes the curated wiki articles (discipline folders), not the raw intake files. If you've dropped files but haven't run `/odcus-kb-compile`, there may be nothing in the discipline folders yet.

---

## Service keeps crashing

**Symptom:** launchd restarts the service repeatedly, PID changes on every check.

**Check the log for repeated errors:**
```bash
tail -50 ~/.local/logs/knowhow-watcher.log
```

**Common cause:** The watch directory path doesn't exist, or contains spaces/special characters that aren't properly handled. Confirm:

```bash
ls "/path/to/your/watch-dir"
```

If using a cloud-synced folder, the path may not exist yet if sync hasn't completed. Wait for sync to finish before loading the service.

---

## Log file is too large

The log rotates automatically at 10 MB. To rotate more frequently, lower the threshold in `watcher.sh`:

```bash
# Change 10485760 (10 MB) to 1048576 (1 MB)
if (( $(stat -f%z "$LOG" 2>/dev/null || echo 0) > 1048576 )); then
```

---

## Restarting after changes to watcher.sh

Any edit to `watcher.sh` requires a service restart:

```bash
launchctl unload ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
launchctl load ~/Library/LaunchAgents/com.odcus.knowhow-watcher.plist
```

Confirm the new version is running:
```bash
tail -5 ~/.local/logs/knowhow-watcher.log
# Should show "Watcher started" with a recent timestamp
```
