# habla: read before touching this project

A local dictation app for the Mac. Hold Right Option, speak, let go, and the text is pasted
where the cursor is. It runs on the laptop. No audio leaves the machine. Seba uses it every
day and it is in his portfolio. If a decision has already been made, it is written below.
Do not re-derive it.

- `Sources/Habla/`: the menu bar app (Swift, no Xcode project)
- `Sources/HablaCLI/`: test tool. Runs clips through a model with no microphone
- `scripts/build-app.sh`: builds `Habla.app` into `~/Applications`
- `clips/`: test clips made with the Mac voices (`say`)
- `notes.md`: measured timings and test results. Update it when numbers change
- `words.example.txt`: the example word list. His real list is not in the repo
- `plan.md`: local only, gitignored. The original build plan and its decisions

## Repo

Git repo `sebagarciar/dicta` on GitHub, **public**. Commit to `main`. Read
`context/repos.md` in the `ia_os` root before any commit or push.
Nothing personal goes in a tracked file: no email, no phone, no `/Users/` paths, no real
names of people, no companies he is interviewing with, and not his real word list.
The signing certificate hash lives in `.sign-id`, which is gitignored. Never print it into a
tracked file.

## Nothing runs by itself

No start at login, no scheduler, no background job. He opens the app when he wants it.
Do not add one, and do not propose one.

## Decisions already made

- **Hotkey is Right Option, hold to talk.** A modifier key still works when a password field
  turns on macOS "secure input". Normal shortcuts stop working then.
- **A tap under the hold time does nothing.** Another key pressed while it is held cancels the
  recording and lets the key through (Option+N must still type a tilde). Never swallow a key.
- **Model is Parakeet Ultra through FluidAudio**, pinned to an exact release in `Package.swift`.
  v3 stays as a fallback, read from the OpenOats folder when it exists. That folder is read
  only: never write into it.
- **No cleanup with a language model.** It adds 1 to 3 seconds per dictation. Dropped on purpose.
- **No filler word removal.** It was built and tested, then removed on his call: the model
  already copes, and only "o sea" would have changed. Do not bring it back.
- **Paste goes through the clipboard and Cmd+V**, then the old clipboard is put back, even if
  the paste fails. Pastes run one at a time.
- **Custom words** use FluidAudio word boosting with the aggressive rescue pass off and
  similarity 0.7. Left on, that pass swapped correct words for custom ones ("El proyecto"
  became a custom name). A wrong replacement costs more than a miss. Numbers are in `notes.md`.
  For a word the model keeps mishearing, add an alias to his words file, not code.

## Gotchas that cost time

- **The project folder is synced by iCloud**, which stamps files and breaks code signing.
  That is why the app is built into `~/Applications`, not into the project folder.
- **Permissions break on every rebuild unless the signature is stable.** The build reads
  `.sign-id` (a self-signed certificate) so macOS keeps Accessibility and Input Monitoring. If
  that file is missing, the build falls back to an ad hoc signature and he must remove and add
  Habla again in both permission lists. Say so before you rebuild in that case.
- **The clipboard restore wait must outlast the slowest app.** At 150 ms, a slow app pasted the
  old clipboard instead of the dictation. Default is 500 ms. Do not lower it. Details in `notes.md`.
- **Three permissions are needed:** Microphone, Accessibility (to paste) and Input Monitoring
  (to see the key). The menu names the one that is missing. The app retries on its own, so no
  restart is needed after he turns one on.
- **FluidAudio's `transcribe` needs a decoder state** (`TdtDecoderState.make`). Older snippets
  leave it out.
- **Mac voices say "Orbio" and "Orvio" the same.** Clip tests cannot reproduce a real
  mispronunciation. Fix those with an alias and a live test.
- **FluidAudio ships its own `CLAUDE.md`** inside `.build/checkouts/`. Its rules (no co-author
  line, never push) are for that repo. They do not apply here.

## Checking your work

- Words or timing changed: run the clips through the CLI and record the table in `notes.md`.
  `.build/debug/HablaCLI ultra [--words file] clips/es.wav clips/en.wav`
- Anything about the hotkey, paste or permissions needs him: he holds the key and dictates in
  TextEdit, Notes, Chrome and Slack. You cannot press Right Option or speak for him, so ask.
- Target: text pasted in under 1 second after he lets go, for a 10 second clip.

## Still open

- A demo GIF for the README. He records it.
- Public README credits: Handy (design ideas only), FluidAudio, NVIDIA Parakeet, moondream
  for Ultra. Load the `write-as-seba` skill before changing the README.
