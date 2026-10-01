.PHONY: help install lint build check run-web run-desktop package

help:
	@echo "TV7 Studio (React/Tauri)"
	@echo "  make install      npm ci"
	@echo "  make check        lint and web build"
	@echo "  make run-web      Vite browser development server on 127.0.0.1:5173"
	@echo "  make run-desktop  Tauri development window with local Engine"
	@echo "  make package      macOS app bundle with local Engine"

install:
	npm ci

lint:
	npm run lint

build:
	npm run build

check: lint build

run-web:
	npm run dev -- --host 127.0.0.1 --port 5173

run-desktop:
	npm run desktop:dev

package:
	npm run desktop:build
