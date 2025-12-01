# TV7 v1 – High-Level Architecture  
Hybrid Local-First Editor + Thin Cloud Control Plane

---

## 1. Overview

TV7 is a local-first video clipping and repurposing application.  
All heavy media operations run on-device using the user’s CPU/GPU:

- Video ingestion  
- Transcription  
- Clip detection (with backend LLM help)  
- Cutting and editing  
- Local exporting  
- Optional local posting  

A minimal FastAPI backend acts as the control plane for:

- Accounts & authentication  
- Trials & licensing  
- LLM-based automatic clip suggestions  
- Pro-only cloud scheduling (backend posts clips when user is offline)

This architecture keeps backend cost extremely low and allows a one-time purchase model for Core and subscription for Pro.

---

## 2. Product Tiers

### 2.1 TV7 Core (Local-First)
- 1-month free trial  
- After trial → one-time purchase (activation key)  
- All heavy functionality runs offline:  
  - Ingest, transcript, clip cutting, editing, export  
- Backend used only for:  
  - Login  
  - Trial validation  
  - License activation  
  - Clip suggestion via LLM  

### 2.2 TV7 Pro (Cloud Scheduler)
Adds:  
- Cloud posting when user is offline  
- Minimal web dashboard for Pro users  
- Backend stores social tokens (Option A)  
- Scheduler worker posts clips at scheduled times  

---

## 3. Architecture Components

### 3.1 Flutter App (Desktop-first)
Responsibilities:

- User authentication (via FastAPI)  
- Caching license token for offline usage  
- Local video ingestion (file or YouTube)  
- Local transcription (Whisper.cpp)  
- Sending transcript + user prompt to backend for clip suggestions  
- Local automatic clip cutting (ffmpeg)  
- Local clip editing (timeline, trimming, text, subtitles)  
- Local exporting  
- Uploading rendered clips to backend for Pro scheduling  
- Displaying scheduled post status (from backend)  
- Opening Pro dashboard via WebView  

---

### 3.2 FastAPI Backend
Responsibilities:

- REST API for authentication & license management  
- Trial logic & activation key validation  
- Issuing signed license tokens (JWT-like)  
- Clip suggestion endpoint (calls LLM provider)  
- Pro-only clip upload endpoint  
- Pro scheduling system storage & logic  
- Storing social OAuth tokens (Option A)  
- Simple web dashboard for Pro users  
- Payment integration (Stripe, Paddle, Lemon Squeezy)  

---

### 3.3 Scheduler Worker
Responsibilities:

- Periodically checks DB for upcoming scheduled posts  
- At `publish_at`, posts the clip to the target platform  
- Handles retries & failure logging  
- Updates post status (scheduled → posted/failed)  

---

### 3.4 Storage & Database

- **Database (Postgres)**  
  - Users  
  - License records  
  - Scheduled posts  
  - Social connections (Pro)

- **Object Storage (S3-compatible)**  
  - Short-term clip file storage for scheduled posting  

---

## 4. App ↔ Backend Interactions

### 4.1 Authentication & Licensing
The app communicates with backend for:

- Register  
- Login  
- Trial validation  
- License activation  
- License refresh  

The backend responds with a **signed license token** containing:

- Plan (`trial`, `core`, `pro`)  
- Expiration timestamp  

The app works offline as long as the token is valid.

---

### 4.2 Clip Suggestion (LLM-Assisted)
The app sends:

- Transcript (local+YouTube merged)  
- Optional user prompt  

Backend returns:

- Suggested clip segments  
- Titles & descriptions  

App uses these timecodes for local cutting.

---

### 4.3 Pro Scheduling
For Pro users only:

- App uploads rendered clip file + metadata to backend  
- Backend stores clip & creates a ScheduledPost entry  
- Scheduler worker posts clip at `publish_at`  
- App can query status via API  
- Actual social account connections are done in the backend WebUI  

---

## 5. Data Model (Simplified)

### User
- `id`  
- `email`  
- `password_hash`  
- `plan` (trial | core | pro)  
- `trial_started_at`  
- `trial_expires_at`  

### License
- `user_id`  
- `activation_key`  
- `plan`  
- `expires_at`  

### ScheduledPost
- `id`  
- `user_id`  
- `platform`  
- `title`  
- `description`  
- `clip_url`  
- `publish_at`  
- `status` (draft | scheduled | posted | failed)  
- `posted_at`  
- `error_message`  

### SocialConnection
- `user_id`  
- `platform`  
- `access_token`  
- `refresh_token`  
- `expires_at`  

---

## 6. Non-functional Requirements

- Local-first operation (offline support)  
- Low backend cost (no heavy media processing)  
- Secure token storage (backend)  
- End-to-end HTTPS  
- JWT-signed license tokens  
- Scheduler worker must be reliable and retry-safe  

---

## 7. Responsibilities Overview

### Flutter App
- Local ingest, transcript, cutting, editing  
- Call backend for:
  - auth  
  - license  
  - clip suggestions  
  - Pro uploads  
- Display scheduled post status  
- Open Pro dashboard  

### FastAPI Backend
- Auth & licensing  
- LLM-based clip suggestion  
- Pro scheduling endpoints  
- Social OAuth management  
- Background worker for posting  
- Payment integration  

---

## 8. TV7 v1 Release Scope

### TV7 Core
- Login, Trial, License  
- Local ingest & transcript  
- Clip suggestion (backend)  
- Local auto-cut  
- Local editing  
- Local export  

### TV7 Pro
- Cloud OAuth (backend)  
- Clip upload to backend  
- Scheduling  
- Worker posting  
- Web dashboard  
- Status sync to app  

---

