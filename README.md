# TV7 Studio

TV7 Studio is the downloadable creator app. Its React/TypeScript interface runs in a Tauri desktop window and, for local development and automation, in a browser. The bundled Rust Engine handles media work on the creator's computer. Backend handles accounts, private storage, schedule drafts, and eventual publishing.

## Current workflow

- Import a video file into Engine, or discover a YouTube channel and explicitly select videos to download. A single video URL can also be submitted. YouTube downloads depend on the upstream site and may fail.
- Import a WebVTT transcript, review timestamp candidates, adjust a range, and render a captioned MP4 locally in Engine. Timing candidates are not viral quality scores.
- Optionally sign in, approve upload of a finished clip to private Backend storage, and create a YouTube schedule draft. A draft is not a published post.

Local import and render do not require Backend login. Studio holds access tokens in memory and does not retain passwords or refresh tokens.

## Develop

Prerequisites: Node.js, Rust, a sibling `../tv7-engine` checkout, and Engine's host media tools. The desktop build currently targets macOS.

```sh
npm ci
make check
make run-web
```

The browser app opens at `http://127.0.0.1:5173` and needs a separately running Engine at `http://127.0.0.1:7070`. For the coordinated Backend, Engine, and Studio stack, use `make dev-browser-up` from `../tv7-core`. Browser builds may set `VITE_ENGINE_URL` and `VITE_BACKEND_URL` at build time. Engine and Backend must allow the browser origin through CORS.

```sh
make run-desktop
make package
```

The Tauri package starts its bundled Engine on a dynamic loopback port with a per-launch bearer token and an app-owned work directory. Quitting Studio stops that Engine child. The development browser Engine is a separate process. `make package` compiles the sibling Engine and creates `src-tauri/target/release/bundle/macos/TV7 Studio.app`.

## Checks

`make check` runs lint and the web build. `make package` verifies desktop packaging. An isolated Rust toolchain newer than Homebrew Rust 1.86 may be required by current Tauri dependencies; if installed in `.toolchain`, add `.toolchain/cargo/bin` to `PATH` and set `RUSTUP_HOME=.toolchain/rustup` and `CARGO_HOME=.toolchain/cargo` for the package command.

## Release boundaries

The current editor supports timing adjustments for one candidate and has no timeline preview, automatic transcription, or viral scoring. FFmpeg, FFprobe, yt-dlp, and a JavaScript runtime for some downloads still rely on host installation. Windows packaging, signing, updates, provider connections, live scheduled publishing, billing, and paid storage remain release work. A browser tab is for local development; the shipped app is the desktop package.

## License

TV7 source in this repository is available under the [MIT License](LICENSE). External dependencies and tools retain their respective licenses. See the [TV7 project overview](https://github.com/TV7-Clip-Studio/tv7-core/blob/main/PROJECT.md) for the repository map and current scope.
