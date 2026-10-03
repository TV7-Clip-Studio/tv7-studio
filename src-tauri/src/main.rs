#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    let _ = fix_path_env::fix();
    tv7_studio_lib::run()
}
