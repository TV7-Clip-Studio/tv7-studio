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
        .invoke_handler(tauri::generate_handler![managed_engine_connection])
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
                let command = app
                    .shell()
                    .sidecar("engine-service")
                    .map_err(|e| e.to_string())?
                    .env("TV7_ENGINE_HOST", "127.0.0.1")
                    .env("TV7_ENGINE_PORT", port.to_string())
                    .env("TV7_ENGINE_API_TOKEN", &token)
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
