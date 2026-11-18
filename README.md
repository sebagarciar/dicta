# Habla

A dictation app for the Mac. Hold Right Option, speak, let go. The text is pasted where your
cursor is. It runs on your laptop. No audio leaves the machine.

## Status (2026-11-18)

Early version, 0.1. Stage 1 works: hotkey, recording, transcription, paste. Tested by hand in
TextEdit, Notes, Chrome and Slack, in Spanish and English. Settings, a custom word list and
history are next. No demo GIF yet.

## Speed

Measured on an Apple M4, with the model already loaded:

| Clip | Audio | Time to text |
|---|---|---|
| Spanish | 9.4 s | 0.09 s |
| English | 7.7 s | 0.07 s |

Loading the model at launch takes 20 to 35 seconds.

## How it works

- Right Option is watched with a keyboard event tap. A tap under 150 ms does nothing.
- If you press another key while holding it (Option+N for a tilde), the recording is cancelled.
- Speech to text: NVIDIA Parakeet (the Ultra build) through the FluidAudio Swift library.
  It detects Spanish and English on its own.
- Silence is trimmed with a voice detector before transcribing.
- The text goes in through the clipboard and Cmd+V. Your old clipboard is put back.
- The app lives in the menu bar and has no Dock icon. It does not start at login.

## Build

You need a Mac with Apple silicon, macOS 14 or later, and Swift 6.

```bash
./scripts/build-app.sh
open ~/Applications/Habla.app
```

The script builds the app into `~/Applications`, not into the project folder. Folders synced by
iCloud break code signing. The first launch downloads about 630 MB of model files.

## Permissions

| Permission | Why |
|---|---|
| Microphone | To hear you while the key is held |
| Accessibility | To press Cmd+V for you |
| Input Monitoring | To see the Right Option key |

The build is signed ad hoc, so macOS forgets Accessibility after each rebuild. Remove Habla from
the list and add it again. A self-signed certificate in Keychain fixes this: set
`HABLA_SIGN_ID` to its name before building.

## Credits

- Design ideas (hold threshold, cancel on key combo, clipboard restore) from
  [Handy](https://github.com/cjpais/handy) by CJ Pais. No code was copied.
- [FluidAudio](https://github.com/FluidInference/FluidAudio) runs the models on the Apple
  Neural Engine. It has its own licence, which you should read before reusing this.
- Parakeet is by NVIDIA. The Ultra build is by moondream.

## Licence

MIT. See `LICENSE`.
