# Forgotten Client (TV7 desktop)

## Prerequisites
- Flutter SDK (3.10+ recommended)
- Command-line tools on the host:
  - `yt-dlp` (keep updated: `yt-dlp -U` or `pip install -U yt-dlp`, Homebrew: `brew install yt-dlp`)
  - `ffmpeg` (`brew install ffmpeg` or your package manager)
- Backend running at the URL provided in your flavor’s dart-defines (`API_BASE_URL`).

## Run (desktop)
```bash
make run-desktop
```

Hot reload (`r`) and hot restart (`R`) work while `flutter run` is active.

## Ingest pipeline (YouTube/file)
- Ingest uses `yt-dlp` and `ffmpeg` from the host; the app will log errors if they are missing or outdated.
- Transcripts and highlights require `yt-dlp` to fetch subtitles; keep it current to avoid YouTube signature errors.
- Rendered clips are created locally via `ffmpeg`, uploaded via the backend’s upload API, and registered as clips under the video.
