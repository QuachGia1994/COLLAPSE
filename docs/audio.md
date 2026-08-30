# Audio

## Android background music

COLLAPSE Android ships `android/app/src/main/res/raw/collapse_arcade_vibe.mp3` as its foreground background-music loop.

- Track: `duru-arcade-vibe`
- Creator/source: DURU / `uncle-sheepsky/duru-cc0-bgm`
- Upstream: https://github.com/uncle-sheepsky/duru-cc0-bgm
- Upstream file: `mp3/duru-arcade-vibe.mp3`
- License: CC0 1.0 Universal / public-domain dedication
- Upstream describes this track as an original, code-synthesized `[pure]` composition with no external samples or VST instruments.
- Attribution is not required by CC0; this file is kept for provenance.

Runtime policy:
- one `MediaPlayer` instance per app composition;
- loops while the app is foreground/resumed;
- pauses on lifecycle `ON_PAUSE` and resumes on `ON_RESUME`;
- volume is reduced while Android Power Save Mode is active;
- gameplay SFX/haptics remain independent.
