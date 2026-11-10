use std::net::TcpListener;
use std::sync::Mutex;
use serde::Serialize;
use tauri::{Manager, RunEvent, State};
use tauri_plugin_shell::{process::CommandChild, ShellExt};

struct ManagedEngine {
    connection: Result<EngineConnection, String>,
    child: Mutex<Option<CommandChild>>,
}

#[derive(Clone, Serialize)]
struct EngineConnection {
    base_url: String,
    token: String,
}

#[tauri::command]
fn managed_engine_connection(engine: State<'_, ManagedEngine>) -> Result<EngineConnection, String> {
    engine.connection.clone()
}

fn validated_social_login_url(value: &str) -> Result<tauri::Url, String> {
    let invalid = || "Unsupported social authorization URL".to_string();
    if value.len() > 8192 {
        return Err(invalid());
    }
    let url = tauri::Url::parse(value).map_err(|_| invalid())?;
    if url.scheme() != "https"
        || !url.username().is_empty()
        || url.password().is_some()
        || url.port().is_some()
        || url.fragment().is_some()
    {
        return Err(invalid());
    }
    let supported = match url.host_str() {
        Some("accounts.google.com") => {
            matches!(url.path(), "/o/oauth2/v2/auth" | "/o/oauth2/auth")
        }
        Some("www.instagram.com") => {
            matches!(url.path(), "/oauth/authorize" | "/oauth/authorize/")
        }
        Some("www.tiktok.com") => {
            matches!(url.path(), "/v2/auth/authorize" | "/v2/auth/authorize/")
        }
        _ => false,
    };
    if !supported {
        return Err(invalid());
    }
    Ok(url)
}

#[tauri::command]
fn open_social_login(app: tauri::AppHandle, url: String) -> Result<(), String> {
    let url = validated_social_login_url(&url)?;
    // Authorization stays in the system browser; Studio's webview keeps its navigation guard.
    #[allow(deprecated)]
    app.shell()
        .open(url.to_string(), None)
        .map_err(|_| "Could not open social authorization in your browser".to_string())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(
            tauri::plugin::Builder::<tauri::Wry>::new("navigation-guard")
                .on_navigation(|_, url| {
                    (url.scheme() == "tauri" && url.host_str() == Some("localhost"))
                        || (cfg!(debug_assertions)
                            && url.scheme() == "http"
                            && url.host_str() == Some("127.0.0.1")
                            && url.port() == Some(5173))
                })
                .build(),
        )
        .plugin(tauri_plugin_shell::init())
        .invoke_handler(tauri::generate_handler![managed_engine_connection, open_social_login])
        .setup(|app| {
            let started = (|| -> Result<(EngineConnection, CommandChild), String> {
                let listener = TcpListener::bind("127.0.0.1:0").map_err(|e| e.to_string())?;
                let port = listener.local_addr().map_err(|e| e.to_string())?.port();
                drop(listener);
                let mut random = [0u8; 32];
                getrandom::fill(&mut random).map_err(|e| e.to_string())?;
                let token: String = random.iter().map(|byte| format!("{byte:02x}")).collect();
                let work_dir = app
                    .path()
                    .app_local_data_dir()
                    .map_err(|e| e.to_string())?
                    .join("engine");
                std::fs::create_dir_all(&work_dir).map_err(|e| e.to_string())?;
                let executable_dir = std::env::current_exe()
                    .map_err(|e| e.to_string())?
                    .parent()
                    .ok_or("Cannot locate Studio's executable directory")?
                    .to_path_buf();
                let bundled_yt_dlp = executable_dir
                    .join("../Resources/yt-dlp/yt-dlp-macos");
                let yt_dlp = if bundled_yt_dlp.is_file() {
                    bundled_yt_dlp
                } else {
                    executable_dir.join("yt-dlp/yt-dlp-macos")
                };
                if !yt_dlp.is_file() {
                    return Err(format!("Bundled yt-dlp is missing: {}", yt_dlp.display()));
                }
                let command = app
                    .shell()
                    .sidecar("engine-service")
                    .map_err(|e| e.to_string())?
                    .env("TV7_ENGINE_HOST", "127.0.0.1")
                    .env("TV7_ENGINE_PORT", port.to_string())
                    .env("TV7_ENGINE_API_TOKEN", &token)
                    .env("TV7_ENGINE_YT_DLP_BIN", yt_dlp.to_string_lossy().to_string())
                    .env("TV7_ENGINE_WORK_DIR", work_dir.to_string_lossy().to_string());
                let (mut events, child) = command.spawn().map_err(|e| e.to_string())?;
                tauri::async_runtime::spawn(async move {
                    while events.recv().await.is_some() {}
                });
                Ok((EngineConnection {
                    base_url: format!("http://127.0.0.1:{port}"),
                    token,
                }, child))
            })();
            let (connection, child) = match started {
                Ok((connection, child)) => (Ok(connection), Some(child)),
                Err(error) => (Err(format!("Packaged Engine failed to start: {error}")), None),
            };
            app.manage(ManagedEngine {
                connection,
                child: Mutex::new(child),
            });
            Ok(())
        })
        .build(tauri::generate_context!())
        .expect("failed to build TV7 Studio")
        .run(|app, event| {
            if let RunEvent::Exit = event {
                if let Some(engine) = app.try_state::<ManagedEngine>() {
                    if let Ok(mut child) = engine.child.lock() {
                        if let Some(child) = child.take() {
                            let _ = child.kill();
                        }
                    }
                }
            }
        });
}

#[cfg(test)]
mod tests {
    use super::validated_social_login_url;

    #[test]
    fn social_login_only_opens_official_https_authorization_endpoints() {
        for url in [
            "https://accounts.google.com/o/oauth2/v2/auth?client_id=test&state=test",
            "https://accounts.google.com/o/oauth2/auth?client_id=test",
            "https://www.instagram.com/oauth/authorize/?client_id=test",
            "https://www.tiktok.com/v2/auth/authorize/?client_key=test",
        ] {
            assert!(validated_social_login_url(url).is_ok(), "{url}");
        }
        for url in [
            "http://accounts.google.com/o/oauth2/v2/auth",
            "https://accounts.google.com.evil.example/o/oauth2/v2/auth",
            "https://user:password@accounts.google.com/o/oauth2/v2/auth",
            "https://accounts.google.com:8443/o/oauth2/v2/auth",
            "https://accounts.google.com/logout",
            "https://www.instagram.com/direct/inbox/",
            "https://www.tiktok.com/v2/auth/authorize/#fragment",
            "file:///tmp/login.html",
            "https://127.0.0.1/oauth/authorize",
        ] {
            assert!(validated_social_login_url(url).is_err(), "{url}");
        }
    }
}
