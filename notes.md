# Habla: test notes

## Clip test (no microphone)

Run on an Apple M4. Clips made with the Mac voices (`say`), 16 kHz mono. Time is from "stop" to
"text ready", second run (model warm). Model load time is a one-off at launch.

| Clip | Audio | Model | Time | Text correct |
|---|---|---|---|---|
| Spanish (Paulina) | 9.4 s | Ultra | 0.09 s | Yes, word for word |
| Spanish (Paulina) | 9.4 s | v3 | 0.09 s | Yes, word for word |
| English (Samantha) | 7.7 s | Ultra | 0.07 s | Yes, word for word |
| English (Samantha) | 7.7 s | v3 | 0.11 s | Yes, word for word |

- Model load: Ultra 35.7 s (first run included the 630 MB download), v3 21.1 s (from OpenOats copy).
- Target was under 1 s for a 10 s clip. Met by a wide margin.
- Both models are tied on clean computer voices, so Ultra stays the default. A real voice with
  noise is the better test: do it in the live test.

## Notes from building

- FluidAudio 0.18.3: `transcribe` needs a decoder state (`TdtDecoderState.make`), which the
  plan's snippet did not show.
- The project folder is synced by iCloud, which breaks code signing. `build-app.sh` builds the
  app into `~/Applications/Habla.app` instead.

## Live test (passed 2026-11-18)

- [x] Grant Microphone and Accessibility when asked
- [x] Spanish and English into TextEdit, Notes, Chrome, Slack
- [x] Old clipboard comes back after a paste
- [x] A quick tap does nothing
- [x] Option+N still types a tilde

- Result: everything passed. no failures.
- Permissions needed: Microphone, Accessibility, Input Monitoring. After a rebuild with ad-hoc
  signing, remove and re-add Habla in Accessibility (a self-signed certificate would avoid this).

## Stage 2 so far (2026-11-18)

- History (last 10, memory only) and the settings window (hold time, paste waits, sounds, model)
  work in a live test. The model picker moved from the menu into Settings.
- A self-signed certificate now keeps the permissions between rebuilds.

## Custom words (2026-11-18)

Ultra with FluidAudio word boosting (extra CTC model, about 100 MB). Mac-voice clips, 4 to 6 s:

| Setting | Fixed "Zapira" to "Sapira" | Wrong swaps | Extra time |
|---|---|---|---|
| Default | Yes | Yes ("El proyecto" became a custom word) | 0.2 to 0.4 s |
| Rescue pass off, similarity 0.7 | Yes | None | about 0.12 s |
| Rescue pass off, similarity 0.5 to 0.7 | Yes | None in 2 control sentences | about 0.12 s |

- App uses rescue off and similarity 0.6.
- Aliases ("Word = heard1, heard2") added for words the model keeps mishearing.
- Live test: passed. Names and "AI" came out right, normal sentences untouched.

## Old clipboard pasted instead of the text (2026-11-18)

- Seen twice in daily use. Cause: the clipboard was restored 150 ms after Cmd+V. An app that
  reads the clipboard later than that (slow app, busy Mac) got the old clipboard.
- Simulation with a private pasteboard: a reader at 250 ms and 400 ms got the old clipboard with
  a 150 ms wait, and the dictated text with a 500 ms wait. Reads at 50 and 120 ms were fine both ways.
- Fix: default wait before restore is now 500 ms (slider goes up to 1000 ms). Text still appears
  at the same time. Not yet confirmed in daily use.
