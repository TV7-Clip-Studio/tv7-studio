import { lazy, Suspense, useCallback, useEffect, useMemo, useRef, useState } from "react";
import { invoke, isTauri } from "@tauri-apps/api/core";
import MultiClipTimeline from "./components/clipping/MultiClipTimeline";
import SocialConnections, { type SocialConnection, type SocialProvider } from "./components/SocialConnections";
import SubtitleControls from "./components/SubtitleControls";
import { defaultSubtitleStyle, normalizeSubtitleStyle, withWordTiming, colorForClip, subtitleColors, wordGroups, highlightedWords, type SubtitleStyle } from "./subtitles";
import "./App.css";
import { releaseSlot, nextFreeSlots, shuffledUniqueClips } from "./schedule";
import { accountSession, saveSession, sessionChanged, sessionToken, type AccountSession } from "./session";

const RemixStudio = lazy(() => import("./remix/RemixStudio"));

import {shuffledRecipe,shuffleErrorSummary} from "./remix/shuffle";
import {patchBatchClip} from "./batch-state";
import MemeLibrary from "./remix/MemeLibrary";
import {outputFrames,type CutawayMedia} from "./remix/cutaways";
import type {RemixPlan} from "./remix/plan";
import {defaultRemixSettings} from "./remix/settings";
import type {RemixSettings} from "./remix/settings";

type Video = {
  id: string;
  url: string;
  title: string;
  duration_seconds?: number | null;
};
type Discovery = {
  channel_url: string;
  videos: Video[];
  next_cursor?: string | null;
};
type Job = {
  id: string;
  status: string;
  progress?: number;
  error?: string;
  result?: { media_path?: string | null; transcript_path?: string | null; url?: string; metadata?: unknown };
};
type BatchJob = { title: string; url: string; jobId: string; job?: Job };
type BatchVideo = {
  status: string;
  count: number;
  transcriptPath?: string;
  clips: ClipDraft[];
  error?: string;
  aiSuggestions?: AiSuggestion[];
  aiError?: string;
  aiUsage?: AiResult["usage"];
  aiModel?: string;
};
type Diagnostics = {
  status?: string;
  capabilities?: { name: string; status: string }[];
  tools?: { name: string; available: boolean | null; required_for?: string[]; error?: string | null }[];
};
type MediaMetadata = {
  duration_seconds: number | null;
  width: number | null;
  height: number | null;
  format: string;
};
type TranscriptImport = {
  name: string;
  transcript_id: string;
  transcript_path: string;
  cue_count: number;
  duration_seconds: number;
};
type Candidate = {
  start_seconds: number;
  end_seconds: number;
  text: string;
  cue_count: number;
};
type ClipDraft = Candidate & {
  id: string;
  title?: string | null;
  postCopy?: PostCopy;
  remixSettings?: RemixSettings | null;
  proposalSource?: "local_timing" | "ai" | "remix_comedy" | "remix_editorial" | "remix_retro";
  start: string;
  end: string;
  captionText: string;
  burnSubtitles: boolean;
  subtitleStyle?: SubtitleStyle;
  subtitleLanguage?: string;
  originalTranscriptPath?: string | null;
  wordTranscriptPath?: string | null;
  format?: "source" | "vertical_9_16" | "vertical_9_16_crop" | "vertical_9_16_blur";
  result?: RenderResult;
  transcriptPath?: string | null;
  error?: string;
  rendering?: boolean;
};
type AiSuggestion = { title: string; start_seconds: number; end_seconds: number; reason: string; score: number };
type AiResult = { provider: string; model: string; clips: AiSuggestion[]; usage?: { credits_charged?: number; credits_remaining?: number } };
type PostCopy = { mood: string; hook: string; youtube_title: string; youtube_description: string; instagram_caption: string; tiktok_caption: string; hashtags: string[]; source: "template" | "ai" | "edited"; model?: string | null };
type PostCopyResult = { provider: string; model: string; copy: Omit<PostCopy, "source" | "model">; usage?: AiResult["usage"] };
type RenderResult = {
  output_path: string;
  duration_seconds: number;
  media_id?: string;
  start_seconds: number;
  end_seconds: number;
  caption_text: string;
};
type LibraryVideo = {
  media_path: string;
  title: string;
  source_url: string | null;
  duration_seconds: number | null;
  size_bytes: number | null;
  transcript_path: string | null;
  clips: { id: string; title?: string | null; start: string; end: string; text: string; cue_count: number; proposal_source: string | null; caption_text: string; burn_subtitles: boolean; subtitle_style?: SubtitleStyle | null; subtitle_language?: string | null; original_transcript_path?: string | null; word_transcript_path?: string | null; format: string; output_path: string | null; transcript_path?: string | null; post_copy?: PostCopy | null; remix_settings?: RemixSettings | null }[];
  recovered: boolean;
  content_hash?: string | null;
  modified_unix_ms?: number | null;
};
type UnlinkedClip = { path: string; name: string; size_bytes: number };
type LibraryGroup = { key: string; title: string; copies: LibraryVideo[]; primary: LibraryVideo; clipCount: number; readyCount: number; identical: boolean; latest: number };
type CreatorProfile = { id: string; name: string; channelUrl: string; defaultClipCount: number; daysBetweenPosts: number; instagramHandle: string; tiktokHandle: string; subtitleStyle?: SubtitleStyle };
type CreatorWorkspace = { profiles: CreatorProfile[]; activeProfileId: string; projectAssignments: Record<string, string> };
type BackendAsset = {
  asset_id: number;
  asset_url: string;
  asset_checksum: string;
  asset_size_bytes: number;
};
type CloudClip = { id: number; video_id: number };
type CloudVideo = {
  id: number;
  clips: { id: number; asset_url: string | null }[];
};
type YouTubeConnection = {
  oauth_configured: boolean;
  connected: boolean;
  channel_id: string | null;
  channel_title: string | null;
  creator_profile_id: string | null;
};
type PublishingTarget = { platform: string; account_ref: string; display_name: string; publishing_ready: boolean };
type LicenseReadiness = {
  account_active?: boolean;
  license_status: string;
  cloud_ai_available: boolean;
  cloud_ai_credits_remaining: number;
  can_request_engine_cloud_ai_token?: boolean;
  reason_code?: string;
};
type ScheduleDraft = {
  id: number;
  status: string;
  scheduled_at: string | null;
  remote_post_id: string | null;
  published_at: string | null;
  error_message: string | null;
};
type QueueJob = ScheduleDraft & {
  clip_id: number;
  platform: string;
  target_account_ref: string | null;
  creator_profile_id: string | null;
  caption: string | null;
  attempt_count: number;
};
type PlanItem = {
  id: string;
  platform?: string;
  target?: string;
  jobId: string;
  sourcePath?: string;
  sourceTitle?: string;
  title: string;
  render: RenderResult;
  caption: string;
  scheduledAt: string;
  idempotencyKey: string;
  status: "pending" | "uploading" | "asset_ready" | "clip_ready" | "draft_ready" | "error";
  asset?: BackendAsset;
  clipId?: number;
  draftId?: number;
  error?: string;
};
type SavedPlan = { ownerEmail: string; profileId: string; platform: string; target: string; items: PlanItem[]; approvalStarted: boolean };
type DirectYouTubeReview = { profileId: string; clipId: string; localClipId: string; outputPath: string; destinationRef: string; destinationName: string; channelId: string; title: string; description: string; mode: "private_now" | "publish_later"; publishAt: string | null; idempotencyKey: string };
type DirectUploadReceipt = { ownerEmail: string; review: DirectYouTubeReview; uploadId?: number; remoteVideoId?: string; providerStatus?: string; status: "ready" | "creating" | "transferring" | "verifying" | "processing" | "verified" | "error"; error?: string };
type BackendDirectUpload = { idempotency_key: string; upload_id: number; creator_profile_id: string; target_account_ref: string; local_clip_id: string; checksum_sha256?: string; title: string; scheduled_at: string | null; status: string; remote_video_id: string | null; last_error: string | null };
type Page = "overview" | "ingest" | "library" | "editor" | "profile" | "schedule";
type EngineConnection = { base_url: string; token: string };
const channelStorageKey = "tv7-channel-batch-v1";
const schedulePlanStorageKey = "tv7-channel-schedule-plan-v1";
const directUploadStorageKey = "tv7-direct-youtube-upload-v1";
const directBatchStorageKey = "tv7-direct-youtube-batch-v1";
const libraryDefaultsStorageKey = "tv7-library-default-copies-v1";
const profilesStorageKey = "tv7-creator-profiles-v1";
const assignmentsStorageKey = "tv7-project-profile-assignments-v1";
const platformName = (platform: string) => platform === "youtube_shorts" ? "YouTube Shorts" : platform === "instagram" ? "Instagram" : platform === "tiktok" ? "TikTok" : platform;
const monthKey = (date: Date) => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
function starterPostCopy(clipTitle: string): PostCopy {
  const title = (clipTitle.trim() || "New clip").slice(0, 100);
  return { mood: "", hook: "", youtube_title: title, youtube_description: "",
    instagram_caption: "", tiktok_caption: "", hashtags: [], source: "template" };
}
function platformCaption(copy: PostCopy, platform: string): string {
  const tags = copy.hashtags.join(" ");
  const body = platform === "youtube_shorts"
    ? `${copy.youtube_title}\n${copy.youtube_description}`
    : platform === "instagram" ? copy.instagram_caption : copy.tiktok_caption;
  return `${body.trim()}${tags ? `\n${tags}` : ""}`.slice(0, 5000);
}
function hasPostCopyForPlatform(copy: PostCopy | null | undefined, platform: string): boolean {
  if (!copy || copy.source === "template") return false;
  if (platform === "youtube_shorts") return Boolean(copy.youtube_title.trim() && copy.youtube_description.trim());
  return Boolean((platform === "instagram" ? copy.instagram_caption : copy.tiktok_caption).trim());
}
function LibraryIcon({ kind }: { kind: "ready" | "draft" | "calendar" | "edit" | "regenerate" }) {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
    {kind === "regenerate" ? <><path d="M20 7v5h-5M4 17v-5h5" /><path d="M6 7a7 7 0 0 1 12-1l2 6M4 12l2 6a7 7 0 0 0 12-1" /></> : kind === "ready" ? <><circle cx="12" cy="12" r="9" /><path d="m8 12 3 3 5-6" /></> : kind === "calendar" ? <><rect x="3" y="5" width="18" height="16" rx="2" /><path d="M7 3v4m10-4v4M3 10h18m-9 3v5m-2.5-2.5h5" /></> : kind === "edit" ? <path d="m4 16-1 5 5-1L20 8l-4-4ZM14 6l4 4" /> : <><path d="M6 3h8l4 4v14H6ZM14 3v5h4M9 12h6m-6 4h4" /></>}
  </svg>;
}
function ScheduleCalendar({ month, jobs, plan, uploads }: { month: string; jobs: QueueJob[]; plan: SavedPlan | null; uploads: { id: string; title: string; scheduledAt: string; status: string; idempotencyKey: string; clipId?: string }[] }) {
  const [year, monthNumber] = month.split("-").map(Number);
  const first = new Date(year, monthNumber - 1, 1);
  const days = new Date(year, monthNumber, 0).getDate();
  const offset = (first.getDay() + 6) % 7;
  return <div className="schedule-calendar" aria-label={`${first.toLocaleString(undefined, { month: "long", year: "numeric" })} posting calendar`}>
    {["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map((day) => <strong className="calendar-weekday" key={day}>{day}</strong>)}
    {Array.from({ length: offset }, (_, index) => <div className="calendar-day empty" key={`empty-${index}`} />)}
    {Array.from({ length: days }, (_, index) => {
      const date = index + 1;
      const daily = jobs.filter((job) => job.scheduled_at && new Date(job.scheduled_at).getFullYear() === year &&
        new Date(job.scheduled_at).getMonth() === monthNumber - 1 && new Date(job.scheduled_at).getDate() === date);
      const remote = uploads.filter((item) => new Date(item.scheduledAt).getFullYear() === year && new Date(item.scheduledAt).getMonth() === monthNumber - 1 && new Date(item.scheduledAt).getDate() === date);
      const planned = plan?.items.filter((item) => new Date(item.scheduledAt).getFullYear() === year &&
        new Date(item.scheduledAt).getMonth() === monthNumber - 1 && new Date(item.scheduledAt).getDate() === date) ?? [];
      return <div className="calendar-day" key={date}><span className="calendar-date">{date}</span>
        {daily.map((job) => <span className="calendar-post" key={job.id} title={`${platformName(job.platform)} · ${job.status} · ${job.caption ?? ""}`}>
          {new Date(job.scheduled_at!).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })} {platformName(job.platform)} · {job.status}</span>)}
        {remote.map((item) => <span className="calendar-post" key={item.id} title={`${item.title} · YouTube confirmed`}>{new Date(item.scheduledAt).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })} {item.title} · {item.status}</span>)}
        {planned.filter((item) => !item.draftId && !remote.some((upload) => upload.idempotencyKey === item.idempotencyKey || upload.clipId === item.jobId)).map((item) => <span className="calendar-post calendar-planned" key={item.id} title={`${item.title} · review plan`}>
          {new Date(item.scheduledAt).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })} {platformName(item.platform ?? plan!.platform)} · review</span>)}</div>;
    })}
  </div>;
}
function loadProfiles(): CreatorProfile[] {
  try {
    const saved = JSON.parse(window.localStorage.getItem(profilesStorageKey) ?? "null");
    if (Array.isArray(saved) && saved.length) {
      return saved;
    }
  } catch { /* Start a local creator profile. */ }
  return [{ id: "personal", name: "My creator profile", channelUrl: "", defaultClipCount: 5, daysBetweenPosts: 2, instagramHandle: "", tiktokHandle: "" }];
}
function loadAssignments(): Record<string, string> {
  try { const saved = JSON.parse(window.localStorage.getItem(assignmentsStorageKey) ?? "{}"); return saved && typeof saved === "object" && !Array.isArray(saved) ? saved : {}; }
  catch { return {}; }
}
function loadLibraryDefaults(): Record<string, string> {
  try {
    const saved = JSON.parse(window.localStorage.getItem(libraryDefaultsStorageKey) ?? "{}");
    return saved && typeof saved === "object" && !Array.isArray(saved) ? saved : {};
  } catch { return {}; }
}
function loadSchedulePlan(): SavedPlan | null {
  try {
    const saved = JSON.parse(window.localStorage.getItem(schedulePlanStorageKey) ?? "null") as SavedPlan | null;
    return saved && Array.isArray(saved.items) && saved.items.length > 0 ? { ...saved, profileId: saved.profileId || "personal" } : null;
  } catch { return null; }
}
function loadDirectUploads(): DirectUploadReceipt[] {
  try {
    const saved = JSON.parse(window.localStorage.getItem(directUploadStorageKey) ?? "[]") as DirectUploadReceipt[] | DirectUploadReceipt | null;
    return (Array.isArray(saved) ? saved : saved ? [saved] : []).filter((item) =>
      item?.review?.idempotencyKey && item.review.destinationRef.startsWith("youtube:")).map((item) =>
      item.status === "verified" || item.status === "processing" || item.status === "error" ? item
        : { ...item, status: "error", error: "Upload was interrupted. Confirm the channel and retry this receipt." });
  } catch { return []; }
}
function loadDirectBatch(): { ownerEmail: string; reviews: DirectYouTubeReview[] } | null {
  try {
    const saved = JSON.parse(window.localStorage.getItem(directBatchStorageKey) ?? "null") as { ownerEmail: string; reviews: DirectYouTubeReview[] } | null;
    return saved && Array.isArray(saved.reviews) && saved.reviews.length <= 25 ? saved : null;
  } catch { return null; }
}
function loadChannelBatch(): { jobs: BatchJob[]; videos: Record<string, BatchVideo> } {
  try {
    const saved = JSON.parse(window.localStorage.getItem(channelStorageKey) ?? "null") as { jobs?: BatchJob[]; videos?: Record<string, BatchVideo> } | null;
    if (!saved || !Array.isArray(saved.jobs) || !saved.videos || typeof saved.videos !== "object") return { jobs: [], videos: {} };
    const videos = Object.fromEntries(Object.entries(saved.videos).map(([id, video]) => [id, {
      ...video,
      status: video.status === "Local batch finished. Review each clip." ? video.status : "Interrupted. Retry this video to continue.",
      clips: Array.isArray(video.clips) ? video.clips.map((clip) => ({ ...clip, rendering: false })) : [],
    }]));
    return { jobs: saved.jobs, videos };
  } catch { return { jobs: [], videos: {} }; }
}
const restoredChannelBatch = loadChannelBatch();
const jobStatus = (job?: Job) =>
  job
    ? `${job.status}${job.progress == null ? "" : ` · ${Math.round(job.progress * 100)}%`}`
    : "queued";
const browserBase = (
  import.meta.env.VITE_ENGINE_URL || "http://127.0.0.1:7070"
).replace(/\/$/, "");
const backendBase = (
  import.meta.env.VITE_BACKEND_URL || "http://127.0.0.1:8000"
).replace(/\/$/, "");
const formatSize = (bytes: number) =>
  bytes < 1048576
    ? `${(bytes / 1024).toFixed(1)} KiB`
    : `${(bytes / 1048576).toFixed(1)} MiB`;
const mediaFilename = (video: LibraryVideo) => video.media_path.split("/").pop() ?? video.title;
const isTechnicalTitle = (title: string) => !title || /^(?:job_|upload-)/.test(title) || /^(?:undefined|null|unknown)$/i.test(title.trim());
function youtubeId(video: LibraryVideo): string | null {
  if (video.source_url) {
    try {
      const url = new URL(video.source_url);
      const id = url.hostname.includes("youtu.be") ? url.pathname.slice(1) : url.searchParams.get("v");
      if (id && /^[A-Za-z0-9_-]{11}$/.test(id)) return id;
    } catch { /* Legacy source URLs may not be valid URLs. */ }
  }
  const name = mediaFilename(video);
  if (!name.startsWith("job_")) return null;
  return name.match(/-([A-Za-z0-9_]{11})-[^-]+(?:.*)\.[^.]+$/)?.[1] ?? null;
}
function displayVideoTitle(video: LibraryVideo): string {
  if (!isTechnicalTitle(video.title)) return video.title;
  const name = mediaFilename(video);
  const sourceId = youtubeId(video);
  if (sourceId) {
    const suffix = name.split(`-${sourceId}-`).slice(1).join(`-${sourceId}-`);
    if (suffix) {
      const title = suffix.replace(/\.[^.]+$/, "").replaceAll("_", " ");
      return /^(?:YouTube's YouTube|YouTube|video|undefined)$/i.test(title) ? "Needs title" : title;
    }
  }
  if (name.startsWith("upload-")) {
    return "Needs title";
  }
  return "Needs title";
}
type LibraryClip = LibraryVideo["clips"][number];
function clipEditKey(clip: LibraryClip): string {
  return [Number(clip.start).toFixed(2), Number(clip.end).toFixed(2), clip.title?.trim() ?? "", clip.caption_text.trim(), clip.text.trim(), String(clip.burn_subtitles), clip.format, JSON.stringify(clip.subtitle_style ?? defaultSubtitleStyle), clip.transcript_path ?? "", clip.word_transcript_path ?? "", clip.subtitle_language ?? "original",JSON.stringify(clip.remix_settings??null)].join("|");
}
function uniqueLibraryClips(clips: LibraryClip[]): LibraryClip[] {
  const result: LibraryClip[] = [];
  for (const clip of clips) {
    const existing = result.findIndex((item) => clipEditKey(item) === clipEditKey(clip) && (!item.output_path || !clip.output_path || item.output_path === clip.output_path));
    if (existing < 0) result.push(clip);
    else if (!result[existing].output_path && clip.output_path) result[existing] = clip;
  }
  return result;
}
const libraryCopyRank = (video: LibraryVideo) =>
  video.clips.filter((clip) => clip.output_path).length * 100 + video.clips.length * 10 +
  Number(!video.recovered) * 5 + Number(!isTechnicalTitle(video.title)) * 3 + Number(mediaFilename(video).startsWith("job_"));
function groupLibrary(videos: LibraryVideo[]): LibraryGroup[] {
  const parent = videos.map((_, index) => index);
  const root = (index: number): number => {
    while (parent[index] !== index) { parent[index] = parent[parent[index]]; index = parent[index]; }
    return index;
  };
  const merge = (a: number, b: number) => { parent[root(b)] = root(a); };
  const byHash = new Map<string, number>();
  const byYouTubeId = new Map<string, number>();
  videos.forEach((video, index) => {
    if (video.content_hash) {
      const previous = byHash.get(video.content_hash);
      if (previous == null) byHash.set(video.content_hash, index); else merge(previous, index);
    }
    const id = youtubeId(video);
    if (id) {
      const previous = byYouTubeId.get(id);
      if (previous == null) byYouTubeId.set(id, index); else merge(previous, index);
    }
  });
  const grouped = new Map<number, LibraryVideo[]>();
  videos.forEach((video, index) => grouped.set(root(index), [...(grouped.get(root(index)) ?? []), video]));
  return [...grouped].map(([index, copies]) => {
    copies.sort((a, b) => libraryCopyRank(b) - libraryCopyRank(a) || (b.modified_unix_ms ?? 0) - (a.modified_unix_ms ?? 0));
    const primary = copies[0];
    const named = copies.find((copy) => !isTechnicalTitle(copy.title)) ?? copies.find((copy) => youtubeId(copy)) ?? primary;
    const sourceId = copies.map(youtubeId).find(Boolean);
    return { key: sourceId ? `youtube:${sourceId}` : `hash:${videos[index].content_hash ?? videos[index].media_path}`, title: displayVideoTitle(named), copies, primary,
      clipCount: copies.reduce((total, copy) => total + copy.clips.length, 0),
      readyCount: copies.reduce((total, copy) => total + copy.clips.filter((clip) => clip.output_path).length, 0),
      identical: copies.every((copy) => copy.content_hash && copy.content_hash === primary.content_hash),
      latest: Math.max(...copies.map((copy) => copy.modified_unix_ms ?? 0)) };
  }).sort((a, b) => Number(b.clipCount > 0) - Number(a.clipCount > 0) || b.latest - a.latest);
}
const localDateTime = (value: string) => {
  const date = new Date(value);
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}T${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;
};

async function request<T>(
  base: string,
  token: string,
  path: string,
  init?: RequestInit,
): Promise<T> {
  let response: Response;
  try {
    const headers = new Headers(init?.headers);
    if (token) headers.set("Authorization", `Bearer ${token}`);
    response = await fetch(base + path, { ...init, headers });
  } catch {
    throw new Error("Cannot reach local Engine at " + base);
  }
  const data: unknown = await response.json().catch(() => null);
  if (!response.ok) {
    const detail =
      data && typeof data === "object" && "message" in data
        ? String(data.message)
        : data && typeof data === "object" && "error" in data
          ? String(data.error)
          : "HTTP " + response.status;
    throw new Error(detail);
  }
  return data as T;
}

async function backendRequest<T>(
  path: string,
  accessToken: string,
  init?: RequestInit,
): Promise<T> {
  const headers = new Headers(init?.headers);
  let auth = accessToken ? await sessionToken(backendBase, accessToken) : "";
  if (auth) headers.set("Authorization", `Bearer ${auth}`);
  let response: Response;
  try {
    response = await fetch(backendBase + path, { ...init, headers });
    if (response.status === 401 && auth && accountSession()) {
      const renewed = await sessionToken(backendBase, auth, true);
      if (renewed !== auth) {
        auth = renewed;
        headers.set("Authorization", `Bearer ${auth}`);
        response = await fetch(backendBase + path, { ...init, headers });
      }
    }
  } catch {
    throw new Error("Cannot reach Backend at " + backendBase);
  }
  const data: unknown = await response.json().catch(() => null);
  if (!response.ok) {
    const detail =
      data && typeof data === "object" && "detail" in data
        ? data.detail
        : data && typeof data === "object" && "error" in data
          ? data.error
          : null;
    const message =
      typeof detail === "string"
        ? detail
        : detail && typeof detail === "object" && "message" in detail
          ? String(detail.message)
          : "HTTP " + response.status;
    throw new Error(message);
  }
  return data as T;
}

export default function App() {
  const mediaVersion = useRef(0);
  const sourcePlayer = useRef<HTMLVideoElement | null>(null);
  const autoSeekedClip = useRef<string | null>(null);
  const previewRangeEnd = useRef<number | null>(null);
  const selectedClipIdRef = useRef<string | null>(null);
  const [page, setPage] = useState<Page>("overview");
  const [profiles, setProfiles] = useState<CreatorProfile[]>(loadProfiles);
  const [activeProfileId, setActiveProfileId] = useState(() => window.localStorage.getItem("tv7-active-profile-v1") || "personal");
  const activeProfileIdRef = useRef(activeProfileId);
  activeProfileIdRef.current = activeProfileId;
  const [projectAssignments, setProjectAssignments] = useState<Record<string, string>>(loadAssignments);
  const [workspaceLoaded, setWorkspaceLoaded] = useState(false);
  const [workspaceError, setWorkspaceError] = useState("");
  const workspaceWrite = useRef<Promise<void>>(Promise.resolve());
  const [editingTitleKey, setEditingTitleKey] = useState<string | null>(null);
  const [titleDraft, setTitleDraft] = useState("");
  const [consolidateBusy, setConsolidateBusy] = useState(false);
  const [consolidateMessage, setConsolidateMessage] = useState("");
  const activeProfile = profiles.find((profile) => profile.id === activeProfileId) ?? profiles[0]!;
  const updateProfile = (patch: Partial<CreatorProfile>) => setProfiles((current) => current.map((profile) => profile.id === activeProfile.id ? { ...profile, ...patch } : profile));
  const addProfile = () => { const id = crypto.randomUUID(); setProfiles((current) => [...current, { id, name: `Creator profile ${current.length + 1}`, channelUrl: "", defaultClipCount: 5, daysBetweenPosts: 2, instagramHandle: "", tiktokHandle: "" }]); setActiveProfileId(id); setPage("profile"); };
  const [connection, setConnection] = useState<EngineConnection>(() =>
    isTauri()
      ? { base_url: "", token: "" }
      : { base_url: browserBase, token: "" },
  );
  const base = connection.base_url;
  const token = connection.token;
  useEffect(() => {
    if (!base) return;
    let cancelled = false;
    setWorkspaceLoaded(false);
    void request<CreatorWorkspace>(base, token, "/v1/workspace").then(async (saved) => {
      const legacy = window.localStorage.getItem(profilesStorageKey);
      const migrate = saved.profiles.length === 1 && saved.profiles[0]?.id === "personal" && !saved.profiles[0]?.channelUrl && Boolean(legacy);
      const workspace = migrate ? await request<CreatorWorkspace>(base, token, "/v1/workspace", {
        method: "PUT", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ profiles, activeProfileId, projectAssignments }),
      }) : saved;
      if (cancelled) return;
      setProfiles(workspace.profiles);
      setActiveProfileId(workspace.activeProfileId);
      setProjectAssignments(workspace.projectAssignments);
      setWorkspaceError("");
      setWorkspaceLoaded(true);
      if (migrate) {
        window.localStorage.removeItem(profilesStorageKey);
        window.localStorage.removeItem(assignmentsStorageKey);
        window.localStorage.removeItem("tv7-active-profile-v1");
      }
    }).catch((error) => { if (!cancelled) setWorkspaceError(String(error)); });
    return () => { cancelled = true; };
  // This load belongs to the Engine connection, not to every profile edit.
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [base, token]);
  useEffect(() => {
    if (!base || !workspaceLoaded) return;
    const timer = window.setTimeout(() => {
      const body = JSON.stringify({ profiles, activeProfileId, projectAssignments });
      workspaceWrite.current = workspaceWrite.current.catch(() => undefined).then(async () => {
        try {
          await request<CreatorWorkspace>(base, token, "/v1/workspace", {
            method: "PUT", headers: { "Content-Type": "application/json" }, body,
          });
          setWorkspaceError("");
        } catch (error) { setWorkspaceError(String(error)); }
      });
    }, 400);
    return () => window.clearTimeout(timer);
  }, [base, token, workspaceLoaded, profiles, activeProfileId, projectAssignments]);
  const [engineStartError, setEngineStartError] = useState("");
  useEffect(() => {
    if (!isTauri()) return;
    void invoke<EngineConnection>("managed_engine_connection")
      .then(setConnection)
      .catch((error: unknown) => setEngineStartError(String(error)));
  }, []);
  const [health, setHealth] = useState<string | null>(null);
  const [diagnostics, setDiagnostics] = useState<Diagnostics | null>(null);
  const [healthError, setHealthError] = useState("");
  const [fileBusy, setFileBusy] = useState(false);
  const [fileResult, setFileResult] = useState<{
    name: string;
    media_id: string;
    media_path: string;
    size_bytes: number | null;
    source_url?: string | null;
    metadata?: MediaMetadata;
    probeError?: string;
  } | null>(null);
  const [fileError, setFileError] = useState("");
  const [library, setLibrary] = useState<LibraryVideo[]>([]);
  const [libraryDefaults, setLibraryDefaults] = useState<Record<string, string>>(loadLibraryDefaults);
  const [unlinkedClips, setUnlinkedClips] = useState<UnlinkedClip[]>([]);
  const [unlinkedSelected, setUnlinkedSelected] = useState<string | null>(null);
  const [libraryError, setLibraryError] = useState("");
  const [libraryBusy, setLibraryBusy] = useState(false);
  const [transcript, setTranscript] = useState<TranscriptImport | null>(null);
  const [transcriptBusy, setTranscriptBusy] = useState(false);
  const [transcriptError, setTranscriptError] = useState("");
  const [candidates, setCandidates] = useState<Candidate[]>([]);
  const [clipCount, setClipCount] = useState(5);
  const [creationStatus, setCreationStatus] = useState("");
  const [creationError, setCreationError] = useState("");
  const [queuedCreatePath, setQueuedCreatePath] = useState<string | null>(null);
  const creationLock = useRef(false);
  const [clipDrafts, setClipDrafts] = useState<ClipDraft[]>([]);
  const clipDraftsRef = useRef(clipDrafts);
  useEffect(() => { clipDraftsRef.current = clipDrafts; }, [clipDrafts]);
  const [openedBatchJobId, setOpenedBatchJobId] = useState<string | null>(null);
  const [selectedClipId, setSelectedClipId] = useState<string | null>(null);
  const [playhead, setPlayhead] = useState(0);
  const [localAiSuggestions, setLocalAiSuggestions] = useState<AiSuggestion[]>([]);
  const [localAiError, setLocalAiError] = useState("");
  const [aiConsent, setAiConsent] = useState(false);
  const [aiBusy, setAiBusy] = useState(false);
  const [aiUsage, setAiUsage] = useState<AiResult["usage"]>();
  const [postCopyBusy, setPostCopyBusy] = useState<string | null>(null);
  const [postCopyError, setPostCopyError] = useState("");

  const [localAiModel, setLocalAiModel] = useState("");
  const [aiCueEstimates, setAiCueEstimates] = useState<Record<string, { count: number; error?: string }>>({});
  const [batchRendering, setBatchRendering] = useState(false);
  const [selectedCandidate, setSelectedCandidate] = useState<number | null>(
    null,
  );
  const [clipStart, setClipStart] = useState("");
  const [clipEnd, setClipEnd] = useState("");
  const [renderBusy, setRenderBusy] = useState(false);
  const [renderError, setRenderError] = useState("");
  const [renderResult, setRenderResult] = useState<RenderResult | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [sourcePreviewUrl, setSourcePreviewUrl] = useState<string | null>(null);
  const [sourcePreviewError, setSourcePreviewError] = useState("");
  const [previewError, setPreviewError] = useState("");
  const [accountEmail, setAccountEmail] = useState("");
  const [accountPassword, setAccountPassword] = useState("");
  const [accessToken, setAccessToken] = useState(() => accountSession()?.accessToken ?? "");
  const accessTokenRef = useRef(accessToken);
  accessTokenRef.current = accessToken;
  const [signedInEmail, setSignedInEmail] = useState(() => accountSession()?.email ?? "");
  const [youtubeConnection, setYoutubeConnection] =
    useState<YouTubeConnection | null>(null);
  const [storedPublishingTargets, setPublishingTargets] = useState<PublishingTarget[]>([]);
  const [socialProviders, setSocialProviders] = useState<SocialProvider[]>([]);
  const [socialConnections, setSocialConnections] = useState<SocialConnection[]>([]);
  const [socialScope, setSocialScope] = useState({ auth: "", profileId: "" });
  const publishingTargets = socialScope.auth === accessToken && socialScope.profileId === activeProfileId ? storedPublishingTargets : [];
  const [connectionBusy, setConnectionBusy] = useState("");
  const [pendingSocialLogin, setPendingSocialLogin] = useState<{ platform: string; url: string; profileId: string; priorVersions: string[] } | null>(null);
  const [connectionError, setConnectionError] = useState("");
  const [license, setLicense] = useState<LicenseReadiness | null>(null);
  const [loginBusy, setLoginBusy] = useState(false);
  const [loginError, setLoginError] = useState("");
  const [asset, setAsset] = useState<BackendAsset | null>(null);
  const [cloudClip, setCloudClip] = useState<CloudClip | null>(null);
  const [handoffBusy, setHandoffBusy] = useState(false);
  const [handoffError, setHandoffError] = useState("");
  const [targetAccount, setTargetAccount] = useState("");
  const [scheduleAt, setScheduleAt] = useState("");
  const [scheduleCaption, setScheduleCaption] = useState("");
  const [draftBusy, setDraftBusy] = useState(false);
  const [draftError, setDraftError] = useState("");
  const [draft, setDraft] = useState<ScheduleDraft | null>(null);
  const [singleUrl, setSingleUrl] = useState("");
  const [singleBusy, setSingleBusy] = useState(false);
  const [singleError, setSingleError] = useState("");
  const [downloadOpenError, setDownloadOpenError] = useState("");
  const [singleJob, setSingleJob] = useState<Job | null>(null);
  const [channelUrl, setChannelUrl] = useState("");
  const [discovery, setDiscovery] = useState<Discovery | null>(null);
  const [selection, setSelection] = useState<Record<string, Video>>({});
  const [discoverBusy, setDiscoverBusy] = useState(false);
  const [discoverError, setDiscoverError] = useState("");
  const [confirming, setConfirming] = useState(false);
  const [batchBusy, setBatchBusy] = useState(false);
  const [batchError, setBatchError] = useState("");
  const [jobs, setJobs] = useState<BatchJob[]>(restoredChannelBatch.jobs);
  const [batchVideos, setBatchVideos] = useState<Record<string, BatchVideo>>(restoredChannelBatch.videos);
  const startedBatchVideos = useRef(new Set([...Object.keys(restoredChannelBatch.videos),...restoredChannelBatch.jobs.map(item=>item.jobId)]));
  const [sampleSource,setSampleSource]=useState(()=>localStorage.getItem('tv7-remix-sample-source')??'');
  useEffect(()=>{localStorage.setItem('tv7-remix-sample-source',sampleSource);},[sampleSource]);
  const [libraryArtBusy,setLibraryArtBusy]=useState(false);
  const [libraryArtStatus,setLibraryArtStatus]=useState(()=>localStorage.getItem('tv7-shuffle-status-v1')??'');
  const [libraryArtStarted,setLibraryArtStarted]=useState<number|null>(null);
  const [libraryArtElapsed,setLibraryArtElapsed]=useState(0);
  const libraryArtStop=useRef(false);
  const [libraryRenderProgress,setLibraryRenderProgress]=useState<number|null>(null);
  useEffect(()=>{if(!libraryArtBusy||!libraryArtStatus.includes(': rendering'))return;let stopped=false;const timer=setInterval(()=>{void request<{status:string;progress:number}>(base,token,'/v1/media/remix-progress').then(p=>{if(!stopped&&p.status==='rendering')setLibraryRenderProgress(Math.round(p.progress*100));}).catch(()=>{});},1000);return()=>{stopped=true;clearInterval(timer);};},[base,token,libraryArtBusy,libraryArtStatus]);
  const [libraryArtErrors,setLibraryArtErrors]=useState<Record<string,string>>(()=>{try{return JSON.parse(localStorage.getItem('tv7-shuffle-errors-v1')??'{}');}catch{return {};}});
  useEffect(()=>{localStorage.setItem('tv7-shuffle-status-v1',libraryArtStatus);},[libraryArtStatus]);
  useEffect(()=>{localStorage.setItem('tv7-shuffle-errors-v1',JSON.stringify(libraryArtErrors));},[libraryArtErrors]);
  useEffect(()=>{if(!libraryArtBusy||libraryArtStarted===null)return;const timer=setInterval(()=>setLibraryArtElapsed(Math.floor((Date.now()-libraryArtStarted)/1000)),1000);return()=>clearInterval(timer);},[libraryArtBusy,libraryArtStarted]);
  const [clipRecovery,setClipRecovery]=useState<LibraryVideo[]|null>(()=>{try{return JSON.parse(localStorage.getItem('tv7-clips-recovery-v1')??'null');}catch{return null;}});
  const cancelledChannelJobs=useRef(new Set<string>());
  function cancelBackgroundChannelWork(){for(const job of jobs)cancelledChannelJobs.current.add(job.jobId);setJobs([]);setBatchVideos({});}
  const batchQueue = useRef<Promise<void>>(Promise.resolve());
  const refreshLibrary = useCallback(async () => {
    if (!base) return;
    setLibraryBusy(true);
    try {
      const [videos, unlinked] = await Promise.all([
        request<LibraryVideo[]>(base, token, "/v1/library/videos"),
        request<UnlinkedClip[]>(base, token, "/v1/library/unlinked-clips"),
      ]);
      setLibrary(videos);
      setUnlinkedClips(unlinked);
      setLibraryError("");
    } catch (error) { setLibraryError(String(error)); }
    finally { setLibraryBusy(false); }
  }, [base, token]);
  useEffect(() => { void refreshLibrary(); }, [refreshLibrary]);

  const saveLibraryVideo = useCallback(async (video: LibraryVideo) => {
    if (!base) return;
    await request<LibraryVideo>(base, token, "/v1/library/videos", {
      method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(video),
    });
    await refreshLibrary();
  }, [base, token, refreshLibrary]);

  const catalogClips = (clips: ClipDraft[]): LibraryVideo["clips"] => clips.map((clip) => ({
    id: clip.id, remix_settings:clip.remixSettings??null, title: clip.title?.trim() || null, start: clip.start, end: clip.end, text: clip.text,
    cue_count: clip.cue_count, proposal_source: clip.proposalSource ?? null, caption_text: clip.captionText,
    burn_subtitles: clip.burnSubtitles, subtitle_style: clip.subtitleStyle ?? defaultSubtitleStyle, format: clip.format ?? "source", output_path: clip.result?.output_path ?? null,
    transcript_path: clip.transcriptPath ?? null, subtitle_language: clip.subtitleLanguage ?? "original", original_transcript_path: clip.originalTranscriptPath ?? null, word_transcript_path: clip.wordTranscriptPath ?? null,
    post_copy: clip.postCopy ?? starterPostCopy(clip.title || "Selected clip"),
  }));
  useEffect(() => {
    if (!fileResult || !base || libraryArtBusy) return;
    const batch = openedBatchJobId ? jobs.find((item) => item.jobId === openedBatchJobId) : undefined;
    const timer = window.setTimeout(() => {
      void saveLibraryVideo({ media_path: fileResult.media_path, title: fileResult.name,
        source_url: batch?.url ?? fileResult.source_url ?? null, duration_seconds: fileResult.metadata?.duration_seconds ?? null,
        size_bytes: fileResult.size_bytes, transcript_path: transcript?.transcript_path ?? null,
        clips: catalogClips(clipDrafts), recovered: false }).catch((error) => setLibraryError(String(error)));
    }, 450);
    return () => window.clearTimeout(timer);
  }, [fileResult, transcript, clipDrafts, openedBatchJobId, jobs, base, saveLibraryVideo, libraryArtBusy]);

  useEffect(() => {
    if (!base) return;
    const timer = window.setTimeout(() => {
      for (const item of jobs) {
        if (item.jobId === openedBatchJobId || item.job?.status !== "succeeded" || !item.job.result?.media_path) continue;
        const video = batchVideos[item.jobId];
        if (!video || libraryArtBusy) continue;
        void saveLibraryVideo({ media_path: item.job.result.media_path, title: item.title,
          source_url: item.url, duration_seconds: null, size_bytes: null,
          transcript_path: video?.transcriptPath ?? null, clips: catalogClips(video?.clips ?? []),
          recovered: false }).catch((error) => setLibraryError(String(error)));
      }
    }, 500);
    return () => window.clearTimeout(timer);
  }, [jobs, batchVideos, openedBatchJobId, base, saveLibraryVideo, libraryArtBusy]);
  const [planStart, setPlanStart] = useState(() => {
    const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);
    tomorrow.setHours(9, 0, 0, 0);
    return `${tomorrow.getFullYear()}-${String(tomorrow.getMonth() + 1).padStart(2, "0")}-${String(tomorrow.getDate()).padStart(2, "0")}T09:00`;
  });
  const [batchPostCopy, setBatchPostCopy] = useState(false);
  const [planSpacing, setPlanSpacing] = useState(2);
  const [planCadence, setPlanCadence] = useState<"normal" | "custom">("normal");
  const [planDestination, setPlanDestination] = useState("all");
  const [scheduleFilter, setScheduleFilter] = useState("all");
  const [scheduleMonth, setScheduleMonth] = useState(() => monthKey(new Date()));
  const [planIncluded, setPlanIncluded] = useState<Record<string, boolean>>({});
  const [schedulePlan, setSchedulePlan] = useState<SavedPlan | null>(loadSchedulePlan);
  const [directClipId, setDirectClipId] = useState("");
  const [directTarget, setDirectTarget] = useState("");
  const [directTitle, setDirectTitle] = useState("");
  const [directDescription, setDirectDescription] = useState("");
  const [directMode, setDirectMode] = useState<"private_now" | "publish_later">("private_now");
  const [directPublishAt, setDirectPublishAt] = useState("");
  const [directReview, setDirectReview] = useState<DirectYouTubeReview | null>(null);
  const [directError, setDirectError] = useState("");
  const [directConfirmed, setDirectConfirmed] = useState(false);
  const [directRetryConfirmed, setDirectRetryConfirmed] = useState<Record<string, boolean>>({});
  const [directReceipts, setDirectReceipts] = useState<DirectUploadReceipt[]>(loadDirectUploads);
  const [directBatchIncluded, setDirectBatchIncluded] = useState<Record<string, boolean>>({});
  const [directBatch, setDirectBatch] = useState<{ ownerEmail: string; reviews: DirectYouTubeReview[] } | null>(loadDirectBatch);
  const [directBatchConfirmed, setDirectBatchConfirmed] = useState(false);
  const [directBatchBusy, setDirectBatchBusy] = useState(false);
  const directBatchInFlight = useRef(false);
  const [backendDirectUploads, setBackendDirectUploads] = useState<BackendDirectUpload[]>([]);
  const [directBusy, setDirectBusy] = useState(false);
  const directInFlight = useRef(false);
  useEffect(() => {
    window.localStorage.setItem(directUploadStorageKey, JSON.stringify(directReceipts));
  }, [directReceipts]);
  useEffect(() => {
    if (directBatch) window.localStorage.setItem(directBatchStorageKey, JSON.stringify(directBatch));
    else window.localStorage.removeItem(directBatchStorageKey);
  }, [directBatch]);
  useEffect(() => {
    if (!accessToken) { queueMicrotask(() => setBackendDirectUploads([])); return; }
    let cancelled = false;
    void backendRequest<BackendDirectUpload[]>(`/api/v1/youtube/local-uploads?creator_profile_id=${encodeURIComponent(activeProfileId)}`, accessToken)
      .then((items) => { if (!cancelled) setBackendDirectUploads(items); })
      .catch(() => { if (!cancelled) setBackendDirectUploads([]); });
    return () => { cancelled = true; };
  }, [accessToken, activeProfileId]);
  useEffect(() => {
    if (!signedInEmail || !backendDirectUploads.length) return;
    setDirectReceipts((current) => current.map((receipt) => {
      const saved = backendDirectUploads.find((item) => item.upload_id === receipt.uploadId && item.creator_profile_id === receipt.review.profileId && item.target_account_ref === receipt.review.destinationRef);
      if (!saved || receipt.ownerEmail !== signedInEmail) return receipt;
      return { ...receipt, providerStatus: saved.status,
        status: saved.status === "scheduled" || saved.status === "private_uploaded" ? "verified" : saved.status === "processing" ? "processing" : receipt.status,
        remoteVideoId: saved.remote_video_id ?? receipt.remoteVideoId,
        review: { ...receipt.review, publishAt: saved.scheduled_at, mode: saved.scheduled_at ? "publish_later" : "private_now" } };
    }));
  }, [backendDirectUploads, signedInEmail]);
  const [planBusy, setPlanBusy] = useState(false);
  const approvalInFlight = useRef(false);
  const [planError, setPlanError] = useState("");
  const [smartScheduleBusy, setSmartScheduleBusy] = useState(false);
  const [clearSchedulePrompt, setClearSchedulePrompt] = useState(false);
  const [libraryScheduleNotice, setLibraryScheduleNotice] = useState("");
  const [scheduleUndo, setScheduleUndo] = useState<{ previous: SavedPlan | null; addedIds: string[]; regenerate?: boolean } | null>(null);
  const [queue, setQueue] = useState<QueueJob[]>([]);
  const [queueBusy, setQueueBusy] = useState(false);
  const [queueError, setQueueError] = useState("");
  const [queueHasMore, setQueueHasMore] = useState(false);
  const [queueDates, setQueueDates] = useState<Record<number, string>>({});
  const [directReleaseDates, setDirectReleaseDates] = useState<Record<number, string>>({});
  const loadQueue = useCallback(async (offset = 0) => {
    if (!accessToken) return;
    setQueueBusy(true);
    setQueueError("");
    try {
      const [fetched, uploads] = await Promise.all([
        backendRequest<QueueJob[]>(`/api/v1/schedule-jobs?limit=100&offset=${offset}&creator_profile_id=${encodeURIComponent(activeProfileId)}`, accessToken),
        backendRequest<BackendDirectUpload[]>(`/api/v1/youtube/local-uploads?creator_profile_id=${encodeURIComponent(activeProfileId)}`, accessToken),
      ]);
      if (accessToken !== accessTokenRef.current || activeProfileId !== activeProfileIdRef.current) return;
      setQueue((current) => offset ? [...current, ...fetched] : fetched);
      setBackendDirectUploads(uploads);
      setQueueHasMore(fetched.length === 100);
      setQueueDates((current) => ({ ...current, ...Object.fromEntries(fetched.filter((job) => job.scheduled_at).map((job) => [job.id, localDateTime(job.scheduled_at!)])) }));
    } catch (error) { setQueueError(String(error)); }
    finally { setQueueBusy(false); }
  }, [accessToken, activeProfileId]);
  useEffect(() => { if (accessToken) queueMicrotask(() => void loadQueue()); }, [accessToken, loadQueue]);
  useEffect(() => {
    if (!accessToken) return;
    queueMicrotask(() => void refreshPublishingTargets(accessToken, activeProfileId).catch((error) => setConnectionError(String(error))));
  // Profile changes must reload Backend-owned connections.
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [accessToken, activeProfileId]);
  useEffect(() => {
    if (!accessToken || !pendingSocialLogin || pendingSocialLogin.profileId !== activeProfileId) return;
    let checking = false;
    const refresh = () => {
      if (checking) return;
      checking = true;
      void refreshPublishingTargets(accessToken, activeProfileId).catch((error) => setConnectionError(String(error))).finally(() => { checking = false; });
    };
    const interval = window.setInterval(refresh, 5000);
    const timeout = window.setTimeout(() => { setPendingSocialLogin(null); setConnectionError("The connection window expired. Choose Connect or Reconnect to start again."); }, 10 * 60 * 1000);
    window.addEventListener("focus", refresh);
    return () => { window.clearInterval(interval); window.clearTimeout(timeout); window.removeEventListener("focus", refresh); };
  // Authorization refresh is scoped to the account and creator profile.
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [accessToken, activeProfileId, pendingSocialLogin]);
  const selected = Object.values(selection);
  const sourceStreamUrl = !token && fileResult?.media_path && base
    ? `${base}/v1/media/source?path=${encodeURIComponent(fileResult.media_path)}`
    : null;
  const sourceDisplayUrl = sourceStreamUrl ?? sourcePreviewUrl;
  const sourceTooLarge = Boolean(token && (fileResult?.size_bytes ?? 0) > 250 * 1024 * 1024);
  const [remixBusy, setRemixBusy] = useState(false);
  const activeClip = clipDrafts.find((clip) => clip.id === selectedClipId) ?? clipDrafts[0];
  const [remixCues,setRemixCues]=useState<{start_seconds:number;end_seconds:number;text:string}[]>([]);
  const [memeMedia,setMemeMedia]=useState<Record<string,CutawayMedia>>({});
  const [memeRevision,setMemeRevision]=useState(0);
  const [memeError,setMemeError]=useState("");
  useEffect(()=>{
    let cancelled=false;const urls:string[]=[];setMemeError("");
    if(base)void request<{assets:{id:string;title:string;attribution:string;duration:number;media_id:string}[]}>(base,token,"/v1/remix/assets").then(async data=>{
      const entries=await Promise.all(data.assets.map(async a=>{let src=`${base}/v1/media/assets/${encodeURIComponent(a.media_id)}`;
        if(token){const r=await fetch(src,{headers:{Authorization:`Bearer ${token}`}});if(!r.ok)throw new Error("Reaction preview unavailable");const blob=await r.blob();src=URL.createObjectURL(blob);if(cancelled){URL.revokeObjectURL(src);}else urls.push(src);}
        return [a.id,{src,title:a.title,attribution:a.attribution,duration:a.duration}] as const;
      }));if(!cancelled)setMemeMedia(Object.fromEntries(entries));
    }).catch(e=>{if(!cancelled)setMemeError(String(e));});
    return()=>{cancelled=true;urls.forEach(url=>URL.revokeObjectURL(url));};
  },[base,token,memeRevision,activeClip?.id]);
  const remixWordPath=activeClip?.wordTranscriptPath;
  useEffect(()=>{
    let cancelled=false;setRemixCues([]);
    if(remixWordPath)void request<{cues:{start_seconds:number;end_seconds:number;text:string}[]}>(base,token,`/v1/transcripts/cues?path=${encodeURIComponent(remixWordPath)}`).then(data=>{if(!cancelled)setRemixCues(data.cues);}).catch(()=>{});
    return ()=>{cancelled=true;};
  },[base,token,remixWordPath]);
  const wordBox = activeClip?.subtitleStyle?.preset === "word_box";
  const previewTranscriptPath = wordBox ? activeClip?.wordTranscriptPath : activeClip?.transcriptPath ?? transcript?.transcript_path;
  const [wordTimingBusy, setWordTimingBusy] = useState(false);
  const [wordTimingError, setWordTimingError] = useState("");
  const [previewCues, setPreviewCues] = useState<{ start_seconds: number; end_seconds: number; text: string }[]>([]);
  const [previewCuePath, setPreviewCuePath] = useState("");
  useEffect(() => {
    if (!previewTranscriptPath) return;
    let cancelled = false;
    void request<{ cues: { start_seconds: number; end_seconds: number; text: string }[] }>(base, token, `/v1/transcripts/cues?path=${encodeURIComponent(previewTranscriptPath)}`)
      .then((result) => { if (!cancelled) { setPreviewCues(result.cues); setPreviewCuePath(previewTranscriptPath); } }).catch(() => {});
    return () => { cancelled = true; };
  }, [base, token, previewTranscriptPath]);
  const previewStyle = { ...defaultSubtitleStyle, ...activeClip?.subtitleStyle };
  const previewWordGroups = useMemo(() => wordGroups(previewCues.filter(cue => cue.end_seconds > Number(activeClip?.start) && cue.start_seconds < Number(activeClip?.end))), [previewCues, activeClip?.start, activeClip?.end]);
  const previewWordGroup = wordBox && previewCuePath === previewTranscriptPath ? previewWordGroups.find(group => playhead >= group[0]!.start_seconds && playhead < group[group.length - 1]!.end_seconds) : undefined;
  const previewText = activeClip?.burnSubtitles && playhead >= Number(activeClip.start) && playhead < Number(activeClip.end)
    ? wordBox ? previewWordGroup?.map(cue => cue.text.trim()).join(" ") ?? "" : activeClip.captionText !== activeClip.text ? activeClip.captionText : previewCuePath === previewTranscriptPath ? previewCues.filter((cue) => playhead >= cue.start_seconds && playhead < cue.end_seconds).map((cue) => cue.text).join("\n") : ""
    : "";
  const previewHighlights = highlightedWords(previewText, previewStyle.keywords);
  useEffect(() => {
    if (!wordBox || !sourceDisplayUrl) return;
    let frame = 0;
    const tick = () => { const player = sourcePlayer.current; if (player) setPlayhead(player.currentTime); frame = requestAnimationFrame(tick); };
    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, [wordBox, sourceDisplayUrl]);
  const blurPlayer = useRef<HTMLVideoElement>(null);
  const activeClipId = activeClip?.id;
  const activeClipStart = activeClip?.start;
  useEffect(() => {
    if (!fileResult?.media_path || !activeClipId || !sourceDisplayUrl || !sourcePlayer.current || sourcePlayer.current.readyState < 1) return;
    const key = `${fileResult.media_path}:${activeClipId}`;
    if (autoSeekedClip.current === key) return;
    sourcePlayer.current.currentTime = Number(activeClipStart) || 0;
    autoSeekedClip.current = key;
  }, [fileResult?.media_path, activeClipId, activeClipStart, sourceDisplayUrl]);

  useEffect(() => {
    try { window.localStorage.setItem(channelStorageKey, JSON.stringify({ jobs, videos: batchVideos })); } catch { /* Local storage may be unavailable. */ }
  }, [jobs, batchVideos]);
  useEffect(() => {
    try {
      if (schedulePlan) window.localStorage.setItem(schedulePlanStorageKey, JSON.stringify(schedulePlan));
      else window.localStorage.removeItem(schedulePlanStorageKey);
    } catch { /* Local storage may be unavailable. */ }
  }, [schedulePlan]);

  useEffect(() => {
    if (!fileResult?.media_path || !base || !token || sourceTooLarge) return;
    const sourceUrl = `${base}/v1/media/source?path=${encodeURIComponent(fileResult.media_path)}`;
    let cancelled = false;
    let objectUrl: string | null = null;
    const headers = new Headers();
    headers.set("Authorization", `Bearer ${token}`);
    void fetch(sourceUrl, { headers })
      .then(async (response) => {
        if (!response.ok) throw new Error(`Source preview unavailable: HTTP ${response.status}`);
        const bytes = Number(response.headers.get("Content-Length"));
        if (!Number.isFinite(bytes) || bytes <= 0 || bytes > 250 * 1024 * 1024)
          throw new Error("Source preview exceeds the 250 MiB desktop limit or has unknown size.");
        const blob = await response.blob();
        if (!cancelled) { objectUrl = URL.createObjectURL(blob); setSourcePreviewUrl(objectUrl); }
      })
      .catch((error: unknown) => { if (!cancelled) setSourcePreviewError(String(error)); });
    return () => { cancelled = true; if (objectUrl) URL.revokeObjectURL(objectUrl); };
  }, [base, fileResult?.media_path, sourceTooLarge, token]);


  useEffect(() => {
    if ((!renderResult?.media_id && !renderResult?.output_path) || !base) return;
    let cancelled = false;
    let objectUrl: string | null = null;
    const headers = new Headers();
    if (token) headers.set("Authorization", `Bearer ${token}`);
    void fetch(
      renderResult.media_id
        ? `${base}/v1/media/assets/${encodeURIComponent(renderResult.media_id)}`
        : `${base}/v1/media/source?path=${encodeURIComponent(renderResult.output_path)}`,
      { headers },
    )
      .then(async (response) => {
        if (!response.ok)
          throw new Error(`Preview unavailable: HTTP ${response.status}`);
        const blob = await response.blob();
        if (!blob.type.startsWith("video/"))
          throw new Error("Engine did not return video for preview.");
        if (!cancelled) {
          objectUrl = URL.createObjectURL(blob);
          setPreviewUrl(objectUrl);
        }
      })
      .catch((error: unknown) => {
        if (!cancelled) setPreviewError(String(error));
      });
    return () => {
      cancelled = true;
      if (objectUrl) URL.revokeObjectURL(objectUrl);
      setPreviewUrl(null);
    };
  }, [base, renderResult?.media_id, renderResult?.output_path, token]);

  useEffect(() => {
    if (!fileResult || !renderResult?.output_path || renderResult.media_id || !base) return;
    let cancelled = false;
    void request<{ media_id: string }>(base, token, "/v1/media/register-export", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ output_path: renderResult.output_path }),
    }).then(({ media_id }) => {
      if (!cancelled) setRenderResult((current) => current?.output_path === renderResult.output_path ? { ...current, media_id } : current);
    }).catch((error) => { if (!cancelled) setPreviewError(String(error)); });
    return () => { cancelled = true; };
  }, [base, token, fileResult, renderResult?.output_path, renderResult?.media_id]);

  const refresh = useCallback(async () => {
    if (!base) return;
    try {
      const [h, d] = await Promise.all([
        request<{ status: string }>(base, token, "/health"),
        request<Diagnostics>(base, token, "/v1/diagnostics"),
      ]);
      setHealth(h.status);
      setDiagnostics(d);
      setHealthError("");
    } catch (error) {
      setHealth(null);
      setDiagnostics(null);
      setHealthError(String(error));
    }
  }, [base, token]);
  // Polling synchronizes the UI with Engine, an external process.
  useEffect(() => {
    // oxlint-disable-next-line react/set-state-in-effect
    void refresh();
    const timer = setInterval(() => void refresh(), 10_000);
    return () => clearInterval(timer);
  }, [refresh]);
  useEffect(() => {
    const pending = jobs.filter(
      (item) =>
        !item.job ||
        !["succeeded", "failed", "cancelled", "poll_error"].includes(
          item.job.status,
        ),
    );
    if (!pending.length) return;
    const timer = setInterval(async () => {
      const updates = await Promise.all(
        pending.map(async (item) => {
          try {
            return {
              jobId: item.jobId,
              job: await request<Job>(
                base,
                token,
                "/v1/jobs/" + encodeURIComponent(item.jobId),
              ),
            };
          } catch (error) {
            return {
              jobId: item.jobId,
              job: {
                id: item.jobId,
                status: "poll_error",
                error: String(error),
              },
            };
          }
        }),
      );
      setJobs((current) =>
        current.map((item) => ({
          ...item,
          job:
            updates.find((update) => update.jobId === item.jobId)?.job ??
            item.job,
        })),
      );
    }, 1500);
    return () => clearInterval(timer);
  }, [base, jobs, token]);
  useEffect(() => {
    for (const item of jobs) {
      if (item.job?.status !== "succeeded" || !item.job.result?.media_path || startedBatchVideos.current.has(item.jobId)) continue;
      startedBatchVideos.current.add(item.jobId);
      batchQueue.current = batchQueue.current.then(() => processBatchVideo(item, clipCount));
    }
  });
  useEffect(() => {
    if (
      !singleJob ||
      ["succeeded", "failed", "cancelled", "poll_error"].includes(
        singleJob.status,
      )
    )
      return;
    const timer = setInterval(async () => {
      try {
        setSingleJob(
          await request<Job>(
            base,
            token,
            "/v1/jobs/" + encodeURIComponent(singleJob.id),
          ),
        );
      } catch (error) {
        setSingleJob({
          id: singleJob.id,
          status: "poll_error",
          error: String(error),
        });
      }
    }, 1500);
    return () => clearInterval(timer);
  }, [base, singleJob, token]);

  async function waitForJob(id: string): Promise<Job> {
    for (;;) {
      const job = await request<Job>(base, token, `/v1/jobs/${encodeURIComponent(id)}`);
      if (job.status === "succeeded") return job;
      if (["failed", "cancelled"].includes(job.status))
        throw new Error(job.error || `Engine job ${job.status}`);
      await new Promise((resolve) => setTimeout(resolve, 1500));
    }
  }

  async function proposeClips(path: string, count: number, version: number) {
    const found = await request<{ candidates: Candidate[] }>(base, token, "/v1/transcripts/candidates", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ transcript_path: path, max_candidates: count }),
    });
    if (version !== mediaVersion.current) return;
    setCandidates(found.candidates);
    const drafts: ClipDraft[] = found.candidates.map((candidate) => ({
      ...candidate,
      id: clipDraftsRef.current.find(clip => Math.abs(Number(clip.start) - candidate.start_seconds) < 0.005 && Math.abs(Number(clip.end) - candidate.end_seconds) < 0.005)?.id ?? crypto.randomUUID(),
      start: candidate.start_seconds.toFixed(2),
      end: candidate.end_seconds.toFixed(2),
      captionText: candidate.text,
      burnSubtitles: true,
      format: "vertical_9_16_blur", subtitleStyle: normalizeSubtitleStyle({ ...defaultSubtitleStyle, ...activeProfile.subtitleStyle, preset: "word_box" }),
      proposalSource: "local_timing", transcriptPath: path,
    }));
    setClipDrafts(drafts);
    setSelectedClipId(drafts[0]?.id ?? null);
    selectedClipIdRef.current = drafts[0]?.id ?? null;
    if (openedBatchJobId) updateBatchVideo(openedBatchJobId, { clips: drafts });
    return drafts;
  }

  const wordTimingTasks = useRef(new Map<string, Promise<string>>());
  async function ensureWordTiming(mediaPath: string, existingPath?: string | null): Promise<string> {
    const cached = wordTimingTasks.current.get(mediaPath);
    if (cached) return cached;
    const task = (async () => {
      if (existingPath) {
        try {
          const words = await request<{ cues: { text: string }[] }>(base, token, `/v1/transcripts/cues?path=${encodeURIComponent(existingPath)}`);
          if (words.cues.length) return existingPath;
        } catch { /* Regenerate missing saved timing locally. */ }
      }
      const parent = mediaPath.slice(0, mediaPath.lastIndexOf("/"));
      const generated = await request<{ job: Job }>(base, token, "/v1/transcripts/generate", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ media_path: mediaPath, output_path: `${parent}/transcript-${crypto.randomUUID()}-words.vtt`, word_timestamps: true }),
      });
      const path = (await waitForJob(generated.job.id)).result?.transcript_path;
      if (!path) throw new Error("Transcription completed without word timing.");
      return path;
    })();
    wordTimingTasks.current.set(mediaPath, task);
    try { return await task; }
    catch (error) { wordTimingTasks.current.delete(mediaPath); throw error; }
  }
  function saveWordTiming(mediaPath: string, path: string) {
    setBatchVideos(current => Object.fromEntries(Object.entries(current).map(([id, video]) => [id,
      jobs.find(item => item.jobId === id)?.job?.result?.media_path === mediaPath
        ? { ...video, clips: withWordTiming(video.clips, path) } : video])));
  }
  async function generateWordTiming() {
    if (!fileResult || wordTimingBusy) return;
    const version = mediaVersion.current;
    setWordTimingBusy(true); setWordTimingError("");
    try {
      wordTimingTasks.current.delete(fileResult.media_path);
      const path = await ensureWordTiming(fileResult.media_path);
      saveWordTiming(fileResult.media_path, path);
      if (version !== mediaVersion.current) return;
      setClipDrafts(current => current.map(item => ({ ...item, wordTranscriptPath: path, result: normalizeSubtitleStyle(item.subtitleStyle ?? activeProfile.subtitleStyle).preset === "word_box" ? undefined : item.result })));
    } catch (error) { if (version === mediaVersion.current) setWordTimingError(String(error)); }
    finally { setWordTimingBusy(false); }
  }

  async function acquireTranscript(mediaPath: string, sourceUrl?: string): Promise<string> {
      const parent = mediaPath.slice(0, mediaPath.lastIndexOf("/"));
      const output_path = `${parent}/transcript-${crypto.randomUUID()}.vtt`;
      let transcriptPath: string | null = null;
      if (sourceUrl) {
        try {
          const downloaded = await request<{ job: Job }>(base, token, "/v1/transcripts/download", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ url: sourceUrl, output_path }),
          });
          transcriptPath = (await waitForJob(downloaded.job.id)).result?.transcript_path ?? null;
        } catch {
          // A missing or unsupported caption track still allows local transcription.
        }
      }
      if (!transcriptPath) {
        const generated = await request<{ job: Job }>(base, token, "/v1/transcripts/generate", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ media_path: mediaPath, output_path }),
        });
        transcriptPath = (await waitForJob(generated.job.id)).result?.transcript_path ?? null;
      }
      if (!transcriptPath) throw new Error("Engine completed without a transcript file.");
      return transcriptPath;
  }

  async function prepareTranscript(mediaPath: string, sourceUrl?: string) {
    const version = mediaVersion.current;
    setTranscriptBusy(true);
    setTranscriptError("");
    try {
      const transcriptPath = await acquireTranscript(mediaPath, sourceUrl);
      if (version !== mediaVersion.current) return;
      setTranscript({ name: sourceUrl ? "Source captions or local transcript" : "Local transcript", transcript_id: "", transcript_path: transcriptPath, cue_count: 0, duration_seconds: 0 });
      await proposeClips(transcriptPath, clipCount, version);
    } catch (error) {
      if (version === mediaVersion.current) setTranscriptError(String(error));
    } finally {
      if (version === mediaVersion.current) setTranscriptBusy(false);
    }
  }

  async function upload(file: File) {
    setCreationStatus(""); setCreationError("");
    ++mediaVersion.current;
    setOpenedBatchJobId(null);
    setSelectedClipId(null);
    selectedClipIdRef.current = null;
    setFileBusy(true);
    setFileError("");
    setSourcePreviewUrl(null);
    setSourcePreviewError("");
    setFileResult(null);
    setTranscript(null);
    setCandidates([]);
    setClipDrafts([]);
    setLocalAiSuggestions([]);
    setLocalAiModel("");
    setLocalAiError("");
    setAiConsent(false);
    setSelectedCandidate(null);
    setRenderResult(null);
    setAsset(null);
    setCloudClip(null);
    setDraft(null);
    try {
      if (file.size > 1024 * 1024 * 1024)
        throw new Error("File exceeds the 1 GiB Engine upload limit.");
      const body = new FormData();
      body.append("file", file, file.name);
      const result = await request<{
        media_id: string;
        media_path: string;
        size_bytes: number;
      }>(base, token, "/v1/ingest/file", { method: "POST", body });
      try {
        const probe = await request<{ metadata: MediaMetadata }>(
          base,
          token,
          "/v1/media/probe",
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ path: result.media_path }),
          },
        );
        setFileResult({ name: file.name, ...result, metadata: probe.metadata });
        setPage("editor");
        setClipStart("0");
        setClipEnd(String(Math.min(30, probe.metadata.duration_seconds ?? 30)));
        void prepareTranscript(result.media_path);
      } catch (error) {
        setFileResult({
          name: file.name,
          ...result,
          probeError: String(error),
        });
        setPage("editor");
        void prepareTranscript(result.media_path);
      }
    } catch (error) {
      setFileError(String(error));
    } finally {
      setFileBusy(false);
    }
  }
  async function openDownloadedJob(job: Job, name: string, sourceUrl?: string, batchVideo?: BatchVideo, selectedResult?: RenderResult, selectedDraftId?: string) {
    const mediaPath = job.result?.media_path;
    if (job.status !== "succeeded" || !mediaPath) return;
    setFileBusy(true);
    setCreationStatus(""); setCreationError("");
    ++mediaVersion.current;
    setDownloadOpenError("");
    setSourcePreviewUrl(null);
    setSourcePreviewError("");
    try {
      const probe = await request<{ metadata: MediaMetadata }>(
        base,
        token,
        "/v1/media/probe",
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ path: mediaPath }),
        },
      );
      setFileResult({
        name,
        media_id: job.id,
        media_path: mediaPath,
        size_bytes: null,
        source_url: sourceUrl ?? job.result?.url ?? null,
        metadata: probe.metadata,
      });
      setTranscript(batchVideo?.transcriptPath ? { name: "Channel captions or local transcript", transcript_id: "", transcript_path: batchVideo.transcriptPath, cue_count: 0, duration_seconds: 0 } : null);
      setCandidates(batchVideo?.clips ?? []);
      setClipDrafts(batchVideo?.clips ?? []);
      if (batchVideo) setClipCount(batchVideo.count);
      setOpenedBatchJobId(jobs.some((item) => item.jobId === job.id) ? job.id : null);
      const initialClipId = selectedDraftId ?? batchVideo?.clips.find((clip) => clip.result?.media_id === selectedResult?.media_id)?.id ?? batchVideo?.clips[0]?.id ?? null;
      setSelectedClipId(initialClipId);
      selectedClipIdRef.current = initialClipId;
      setPreviewError("");
      setLocalAiSuggestions(batchVideo?.aiSuggestions ?? []);
      setLocalAiModel(batchVideo?.aiModel ?? "");
      setLocalAiError(batchVideo?.aiError ?? "");
      setAiConsent(false);
      setSelectedCandidate(null);
      setClipStart("0");
      setClipEnd(String(Math.min(30, probe.metadata.duration_seconds ?? 30)));
      setRenderResult(selectedResult ?? null);
      setAsset(null);
      setCloudClip(null);
      setDraft(null);
      setPage("editor");
        requestAnimationFrame(() => requestAnimationFrame(() => document.getElementById("clip-workspace")?.scrollIntoView({ block: "start" })));
      if (!batchVideo?.transcriptPath) void prepareTranscript(mediaPath, sourceUrl ?? job.result?.url);
    } catch (error) {
      setDownloadOpenError(String(error));
    } finally {
      setFileBusy(false);
    }
  }
  async function openLibraryVideo(video: LibraryVideo, selectedClipId?: string, destination: Page = "editor") {
    setFileBusy(true);
    setLibraryError("");
    setCreationStatus(""); setCreationError("");
    ++mediaVersion.current;
    try {
      const probe = await request<{ metadata: MediaMetadata }>(base, token, "/v1/media/probe", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ path: video.media_path }),
      });
      const drafts: ClipDraft[] = uniqueLibraryClips(video.clips).map((clip) => {
        const start = Number(clip.start), end = Number(clip.end);
        return { id: clip.id, remixSettings:clip.remix_settings, title: clip.title, postCopy: clip.post_copy?.source === "template" ? starterPostCopy(clip.title || video.title) : clip.post_copy ?? starterPostCopy(clip.title || video.title), start: clip.start, end: clip.end, start_seconds: start,
          end_seconds: end, text: clip.text || clip.caption_text, cue_count: clip.cue_count ?? 0,
          proposalSource: clip.proposal_source as ClipDraft["proposalSource"], captionText: clip.caption_text,
          burnSubtitles: clip.burn_subtitles, subtitleStyle: normalizeSubtitleStyle(clip.subtitle_style ?? activeProfile.subtitleStyle), subtitleLanguage: clip.subtitle_language ?? "original", originalTranscriptPath: clip.original_transcript_path, wordTranscriptPath: clip.word_transcript_path, format: clip.format as ClipDraft["format"],
          transcriptPath: clip.transcript_path ?? video.transcript_path,
          ...(clip.output_path ? { result: { output_path: clip.output_path,
            duration_seconds: outputFrames(end-start,clip.remix_settings?.plan)/30, start_seconds: start, end_seconds: end,
            caption_text: clip.caption_text } } : {}),
        };
      });
      const batch = jobs.find((item) => item.job?.result?.media_path === video.media_path);
      setOpenedBatchJobId(batch?.jobId ?? null);
      if (batch) updateBatchVideo(batch.jobId, { clips: drafts });
      setFileResult({ name: displayVideoTitle(video), media_id: batch?.jobId ?? video.media_path,
        media_path: video.media_path, size_bytes: video.size_bytes, source_url: video.source_url, metadata: probe.metadata });
      setTranscript(video.transcript_path ? { name: "Saved transcript", transcript_id: "",
        transcript_path: video.transcript_path, cue_count: 0, duration_seconds: 0 } : null);
      setClipDrafts(drafts);
      setClipCount(Math.max(1, activeProfile.defaultClipCount));
      const chosen = drafts.find((clip) => clip.id === selectedClipId) ?? drafts[0];
      setSelectedClipId(chosen?.id ?? null);
      selectedClipIdRef.current = chosen?.id ?? null;
      setRenderResult(chosen?.result ?? null);
      setPage(destination);

    } catch (error) { setQueuedCreatePath(null); setLibraryError(String(error)); }
    finally { setFileBusy(false); }
  }
  async function closeLibraryVideo() {
    if (fileResult) {
      const batch = openedBatchJobId ? jobs.find((item) => item.jobId === openedBatchJobId) : undefined;
      try {
        await saveLibraryVideo({ media_path: fileResult.media_path, title: fileResult.name,
          source_url: batch?.url ?? fileResult.source_url ?? null, duration_seconds: fileResult.metadata?.duration_seconds ?? null,
          size_bytes: fileResult.size_bytes, transcript_path: transcript?.transcript_path ?? null,
          clips: catalogClips(clipDrafts), recovered: false });
      } catch (error) { setLibraryError(String(error)); return; }
    }
    setFileResult(null);
    setPage("library");
  }
  async function importTranscript(file: File) {
    setCreationStatus(""); setCreationError("");
    ++mediaVersion.current;
    setTranscriptBusy(true);
    setTranscriptError("");
    setLocalAiSuggestions([]);
    setLocalAiModel("");
    setLocalAiError("");
    setAiConsent(false);
    setSelectedCandidate(null);
    setRenderResult(null);
    setPreviewUrl(null);
    setPreviewError("");
    try {
      if (!file.name.toLowerCase().endsWith(".vtt"))
        throw new Error("Select a WebVTT (.vtt) transcript.");
      if (file.size > 5 * 1024 * 1024)
        throw new Error("Transcript exceeds the 5 MiB Engine limit.");
      const body = new FormData();
      body.append("file", file, file.name);
      const imported = await request<Omit<TranscriptImport, "name">>(
        base,
        token,
        "/v1/transcripts/import",
        { method: "POST", body },
      );
      const version = mediaVersion.current;
      setTranscript({ name: file.name, ...imported });
      if (openedBatchJobId) updateBatchVideo(openedBatchJobId, { transcriptPath: imported.transcript_path });
      await proposeClips(imported.transcript_path, clipCount, version);
    } catch (error) {
      setTranscriptError(String(error));
    } finally {
      setTranscriptBusy(false);
    }
  }
  async function renderCandidate() {
    if (!fileResult) return;
    setRenderBusy(true);
    setRenderError("");
    setRenderResult(null);
    setAsset(null);
    setCloudClip(null);
    setDraft(null);
    try {
      const start = Number(clipStart);
      const end = Number(clipEnd);
      const duration = fileResult.metadata?.duration_seconds;
      if (
        !Number.isFinite(start) ||
        !Number.isFinite(end) ||
        start < 0 ||
        end <= start
      )
        throw new Error("Clip end must be after its non-negative start.");
      if (duration != null && end > duration)
        throw new Error("Clip end exceeds the video duration.");
      const parent = fileResult.media_path.slice(
        0,
        fileResult.media_path.lastIndexOf("/"),
      );
      const output_path = `${parent}/clip-${Date.now()}-${crypto.randomUUID()}.mp4`;
      const response = await request<{ result: RenderResult }>(
        base,
        token,
        "/v1/media/render-clip",
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            source_path: fileResult.media_path,
            output_path,
            start_seconds: start,
            end_seconds: end,
            ...(transcript
              ? { subtitle_path: transcript.transcript_path }
              : {}),
          }),
        },
      );
      setRenderResult({
        ...response.result,
        start_seconds: start,
        end_seconds: end,
        caption_text:
          selectedCandidate === null
            ? ""
            : (candidates[selectedCandidate]?.text ?? ""),
      });
    } catch (error) {
      setRenderError(String(error));
    } finally {
      setRenderBusy(false);
    }
  }
  function updateClip(id: string, patch: Partial<ClipDraft>) {
    const nextPatch = ("start" in patch || "end" in patch) ? { ...patch, postCopy: undefined } : patch;
    setClipDrafts((current) => current.map((clip) => clip.id === id ? { ...clip, ...nextPatch } : clip));
    if (openedBatchJobId) updateBatchClip(openedBatchJobId, id, nextPatch);
    if (activeClip?.id === id && ("start" in patch || "end" in patch || "captionText" in patch || "burnSubtitles" in patch || "subtitleStyle" in patch || "format" in patch || "result" in patch)) {
      setRenderResult(null);
      setPreviewError("");
      setAsset(null); setCloudClip(null); setDraft(null);
    }
  }
  function playSelectedRange(clip: ClipDraft) {
    const player = sourcePlayer.current;
    if (!player || !Number.isFinite(Number(clip.start)) || !Number.isFinite(Number(clip.end))) return;
    previewRangeEnd.current = Number(clip.end);
    player.currentTime = Number(clip.start);
    void player.play().catch(() => { previewRangeEnd.current = null; });
  }
  function selectClip(clip: ClipDraft) {
    setSelectedClipId(clip.id);
    selectedClipIdRef.current = clip.id;
    setRenderResult(clip.result ?? null);
    setPreviewError("");
    setAsset(null); setCloudClip(null); setDraft(null);
  }
  function seekSource(seconds: number) {
    previewRangeEnd.current = null;
    if (sourcePlayer.current) sourcePlayer.current.currentTime = seconds;
    setPlayhead(seconds);
  }
  function setClipRange(id: string, range: { start: number; end: number }) {
    if (creationLock.current) return;
    updateClip(id, { start: range.start.toFixed(2), end: range.end.toFixed(2), result: undefined });
  }
  async function renderClip(clip: ClipDraft, context?: { mediaPath: string; duration?: number | null; transcriptPath?: string }): Promise<RenderResult & { wordTranscriptPath?: string | null }> {
    const mediaPath = context?.mediaPath ?? fileResult?.media_path;
    if (!mediaPath) throw new Error("Import a video first.");
    const effectiveStyle = normalizeSubtitleStyle(clip.subtitleStyle ?? activeProfile.subtitleStyle);
    const start = Number(clip.start);
    const end = Number(clip.end);
    const duration = context ? context.duration : fileResult?.metadata?.duration_seconds;
    if (!Number.isFinite(start) || !Number.isFinite(end) || start < 0 || end <= start)
      throw new Error("End must be after a non-negative start.");
    if (duration != null && end > duration) throw new Error("End exceeds video duration.");
    const version = mediaVersion.current;
    let wordPath = clip.wordTranscriptPath;
    if (clip.burnSubtitles && effectiveStyle.preset === "word_box") {
      setWordTimingBusy(true); setWordTimingError("");
      try {
        wordPath = await ensureWordTiming(mediaPath, wordPath);
        if (!context && version === mediaVersion.current)
          setClipDrafts(current => withWordTiming(current, wordPath!));
        saveWordTiming(mediaPath, wordPath);
      } finally { setWordTimingBusy(false); }
    }
    if (clip.proposalSource?.startsWith("remix_")) {
      const response=await request<{result:RenderResult}>(base,token,"/v1/media/remix",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({source:mediaPath,word_path:wordPath,start,end,treatment:clip.remixSettings?.treatment??clip.proposalSource.slice(6),settings:clip.remixSettings})});
      return {...response.result,start_seconds:start,end_seconds:end,caption_text:clip.captionText,wordTranscriptPath:wordPath};
    }
    let subtitlePath = clip.burnSubtitles ? effectiveStyle.preset === "word_box" ? wordPath : clip.transcriptPath ?? context?.transcriptPath ?? transcript?.transcript_path : undefined;
    if (clip.burnSubtitles && effectiveStyle.preset !== "word_box" && clip.captionText !== clip.text) {
      const edited = clip.captionText.trim();
      if (!edited) throw new Error("Enter caption text or turn off Burn subtitles.");
      const toVttTime = (seconds: number) => {
        const millis = Math.round(seconds * 1000);
        const hours = Math.floor(millis / 3600000);
        const minutes = Math.floor(millis / 60000) % 60;
        const wholeSeconds = Math.floor(millis / 1000) % 60;
        return `${String(hours).padStart(2, "0")}:${String(minutes).padStart(2, "0")}:${String(wholeSeconds).padStart(2, "0")}.${String(millis % 1000).padStart(3, "0")}`;
      };
      const safeText = edited.replaceAll("-->", "→").replaceAll(/\s+/g, " ");
      const vtt = `WEBVTT\n\n${toVttTime(start)} --> ${toVttTime(end)}\n${safeText}\n`;
      const body = new FormData();
      body.append("file", new File([vtt], `clip-caption-${clip.id}.vtt`, { type: "text/vtt" }));
      const imported = await request<{ transcript_path: string }>(base, token, "/v1/transcripts/import", { method: "POST", body });
      subtitlePath = imported.transcript_path;
    }
    if (!context && version !== mediaVersion.current) throw new Error("Render cancelled: selected video changed.");
    if (clip.burnSubtitles && !subtitlePath) throw new Error("Generate a transcript before rendering Clean subtitles.");
    const parent = mediaPath.slice(0, mediaPath.lastIndexOf("/"));
    const response = await request<{ result: RenderResult }>(base, token, "/v1/media/render-clip", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        source_path: mediaPath,
        output_path: `${parent}/clip-${crypto.randomUUID()}.mp4`,
        start_seconds: start,
        end_seconds: end,
        format: clip.format ?? "source",
        ...(subtitlePath ? { subtitle_path: subtitlePath, subtitle_style: effectiveStyle } : {}),
      }),
    });
    return { ...response.result, wordTranscriptPath: wordPath, start_seconds: start, end_seconds: end, caption_text: clip.captionText };
  }
  async function renderDraft(clip: ClipDraft) {
    const version = mediaVersion.current;
    updateClip(clip.id, { rendering: true, error: "", result: undefined });
    try {
      const result = await renderClip(clip);
      if (version !== mediaVersion.current) return;
      updateClip(clip.id, { rendering: false, result });
      if (selectedClipIdRef.current === clip.id) setRenderResult(result);
      if (selectedClipIdRef.current === clip.id) setPreviewError("");
      const latestClip = clipDraftsRef.current.find(item => item.id === clip.id) ?? clip;
      if (accessToken && latestClip.postCopy?.source !== "edited" && !latestClip.postCopy?.youtube_description?.trim())
        return { rendered: true, copyReady: Boolean(await generatePostCopy({ ...latestClip, wordTranscriptPath: result.wordTranscriptPath ?? latestClip.wordTranscriptPath })) };
      return { rendered: true, copyReady: Boolean(latestClip.postCopy?.youtube_description?.trim()) };
    } catch (error) {
      if (version === mediaVersion.current) updateClip(clip.id, { rendering: false, error: String(error) });
      return { rendered: false, copyReady: false };
    }
  }
  async function renderBatch() {
    if (creationLock.current || batchRendering) return;
    creationLock.current = true; setBatchRendering(true);
    const version = mediaVersion.current;
    try {
      for (let index = 0; index < clipDrafts.length; index++) {
        if (version !== mediaVersion.current) break;
        const clip = clipDraftsRef.current.find(item => item.id === clipDrafts[index]!.id);
        if (!clip) continue;
        setCreationStatus(`Rendering clip ${index + 1} of ${clipDrafts.length}…`);
        await renderDraft(clip);
      }
      if (version === mediaVersion.current) setCreationStatus("Rendering finished. Review clip status below.");
    } finally { creationLock.current = false; setBatchRendering(false); }
  }
  async function createFullClips() {
    if (!fileResult || creationLock.current || batchRendering) return;
    creationLock.current = true; setBatchRendering(true); setCreationError("");
    const version = mediaVersion.current;
    try {
      setCreationStatus("Reading video transcript…");
      const path = transcript?.transcript_path ?? await acquireTranscript(fileResult.media_path, fileResult.source_url ?? undefined);
      if (version !== mediaVersion.current) return;
      setTranscript({ name: "Video transcript", transcript_id: "", transcript_path: path, cue_count: 0, duration_seconds: 0 });
      setCreationStatus("Finding clip ranges…");
      const proposals = await proposeClips(path, Math.max(1, Math.min(12, clipCount)), version);
      if (version !== mediaVersion.current) return;
      if (!proposals?.length) throw new Error("No clip ranges found. Check the transcript in Advanced tools.");
      const offset = Math.floor(Math.random() * subtitleColors.length);
      const drafts = proposals.map((clip, index) => ({ ...clip, subtitleStyle: colorForClip(clip.subtitleStyle, index + offset) }));
      setClipDrafts(drafts);
      if (openedBatchJobId) updateBatchVideo(openedBatchJobId, { clips: drafts });
      let rendered = 0; let written = 0;
      for (let index = 0; index < drafts.length; index++) {
        if (version !== mediaVersion.current) return;
        setCreationStatus(`Creating clip ${index + 1} of ${drafts.length} · subtitles, video and post text…`);
        const outcome = await renderDraft(drafts[index]!);
        if (outcome?.rendered) rendered++;
        if (outcome?.copyReady) written++;
      }
      setCreationStatus(`${rendered}/${drafts.length} clips rendered · ${written}/${drafts.length} post descriptions written. ${accessToken ? "Review results below." : "Sign in in Account to generate post text."}`);
      if (rendered < drafts.length || (accessToken && written < drafts.length)) setCreationError("Some clips need attention. Review the render or post copy errors below and retry.");
    } catch (error) { if (version === mediaVersion.current) setCreationError(String(error)); }
    finally { creationLock.current = false; setBatchRendering(false); }
  }
  const createFullClipsRef = useRef(createFullClips);
  createFullClipsRef.current = createFullClips;
  useEffect(() => {
    if (!queuedCreatePath || fileBusy || fileResult?.media_path !== queuedCreatePath) return;
    setQueuedCreatePath(null);
    void createFullClipsRef.current();
  }, [queuedCreatePath, fileBusy, fileResult]);
  function shuffleClipColors() {
    const currentIndex = subtitleColors.indexOf(normalizeSubtitleStyle(clipDrafts[0]?.subtitleStyle).highlight_color ?? "");
    const offset = (Math.max(0, currentIndex) + 1 + Math.floor(Math.random() * (subtitleColors.length - 1))) % subtitleColors.length;
    const drafts = clipDrafts.map((clip, index) => ({ ...clip, subtitleStyle: colorForClip(clip.subtitleStyle, index + offset), result: undefined }));
    setClipDrafts(drafts);
    if (openedBatchJobId) updateBatchVideo(openedBatchJobId, { clips: drafts });
    setRenderResult(null); setAsset(null); setCloudClip(null); setDraft(null);
    setCreationStatus("Colors shuffled. Render all clips to apply the new colors.");
  }
  function updateBatchVideo(jobId: string, patch: Partial<BatchVideo>) {
    if(cancelledChannelJobs.current.has(jobId))return;
    setBatchVideos((current) => ({ ...current, [jobId]: { ...current[jobId], ...patch } }));
  }
  function updateBatchClip(jobId: string, clipId: string, patch: Partial<ClipDraft>) {
    setBatchVideos(current=>patchBatchClip(current,jobId,clipId,patch,cancelledChannelJobs.current.has(jobId)));
  }

  async function renderBatchClip(item: BatchJob, clip: ClipDraft, transcriptPath: string) {
    if(cancelledChannelJobs.current.has(item.jobId))return;
    const mediaPath = item.job?.result?.media_path;
    if (!mediaPath) return;
    updateBatchClip(item.jobId, clip.id, { rendering: true, error: "", result: undefined });
    try {
      const result = await renderClip(clip, { mediaPath, transcriptPath });
      updateBatchClip(item.jobId, clip.id, { rendering: false, result });
      return true;
    } catch (error) {
      updateBatchClip(item.jobId, clip.id, { rendering: false, error: String(error) });
      return false;
    }
  }
  async function processBatchVideo(item: BatchJob, count: number) {
    if(cancelledChannelJobs.current.has(item.jobId))return;
    const mediaPath = item.job?.result?.media_path;
    if (!mediaPath) return;
    updateBatchVideo(item.jobId, { status: "Acquiring captions or transcribing locally…", count, clips: [] });
    try {
      const transcriptPath = await acquireTranscript(mediaPath, item.url);
      if(cancelledChannelJobs.current.has(item.jobId))return;
      updateBatchVideo(item.jobId, { status: "Proposing clip ranges…", transcriptPath });
      const timed = await request<{ cues: { start_seconds: number; end_seconds: number }[] }>(base, token, `/v1/transcripts/cues?path=${encodeURIComponent(transcriptPath)}`);
      const span = Math.max(0, ...timed.cues.map((cue) => cue.end_seconds)) - Math.min(...timed.cues.map((cue) => cue.start_seconds));
      const duration = Math.max(15, Math.min(90, span / count));
      const found = await request<{ candidates: Candidate[] }>(base, token, "/v1/transcripts/candidates", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ transcript_path: transcriptPath, max_candidates: count, max_duration_seconds: duration }),
      });
      if(cancelledChannelJobs.current.has(item.jobId))return;
      const clips: ClipDraft[] = found.candidates.map((candidate) => ({
        ...candidate, id: crypto.randomUUID(),
        start: candidate.start_seconds.toFixed(2), end: candidate.end_seconds.toFixed(2),
        captionText: candidate.text, burnSubtitles: true,
        format: "vertical_9_16_blur", subtitleStyle: normalizeSubtitleStyle({ ...defaultSubtitleStyle, ...activeProfile.subtitleStyle, preset: "word_box" }),
        proposalSource: "local_timing",
      }));
      updateBatchVideo(item.jobId, { status: `Preparing ${clips.length} clips…`, clips: clips.map((clip) => ({ ...clip })) });
      if (batchPostCopy && accessToken) {
        let delegated = false;
        try {
          const cloudToken = await backendRequest("/api/v1/cloud-ai/engine-token", accessToken, { method: "POST" });
          await request(base, token, "/v1/ai/cloud-token", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(cloudToken) });
          delegated = true;
          const full = await request<{ cues: { start_seconds: number; end_seconds: number; text: string }[] }>(base, token, `/v1/transcripts/cues?path=${encodeURIComponent(transcriptPath)}`);
          let mood: string | undefined;
          for (const clip of clips) {
            updateBatchVideo(item.jobId, { status: `Writing post copy for clip ${clips.indexOf(clip) + 1} of ${clips.length}…` });
            const spoken = full.cues.filter((cue) => cue.end_seconds > Number(clip.start) && cue.start_seconds < Number(clip.end)).map((cue) => cue.text).join(" ").slice(0, 12000);
            const result = await request<PostCopyResult>(base, token, "/v1/ai/post-copy", { method: "POST", headers: { "Content-Type": "application/json" },
              body: JSON.stringify({ source_title: item.title, clip_title: "Selected clip", transcript_text: spoken,
                video_context: full.cues.map((cue) => cue.text).join(" ").slice(0, 6000), video_mood: mood ?? null }) });
            clip.postCopy = { ...result.copy, source: "ai", model: result.model };
            clip.title = result.copy.youtube_title;
            mood = result.copy.mood ?? mood;
            updateBatchClip(item.jobId, clip.id, { postCopy: clip.postCopy, title: clip.title });
          }
        } catch (error) { updateBatchVideo(item.jobId, { aiError: `Post copy needs attention: ${String(error)}` }); }
        finally { if (delegated) await request(base, token, "/v1/ai/cloud-token", { method: "DELETE" }).catch(() => {}); }
      }
      updateBatchVideo(item.jobId, { status: `Rendering ${clips.length} clips locally…` });
      let ready = 0;
      for (const clip of clips) {if(cancelledChannelJobs.current.has(item.jobId))return;if(await renderBatchClip(item,clip,transcriptPath))ready+=1;}
      updateBatchVideo(item.jobId, { status: ready === clips.length && ready > 0 ? `Rendered ${ready} clips. Review and generate post copy.` : `Needs attention · ${ready} of ${clips.length} clips rendered`,
        ...(ready < clips.length ? { error: "Some renders failed. Review the clip errors before retrying." } : {}) });
    } catch (error) {
      updateBatchVideo(item.jobId, { status: "Needs attention", error: String(error) });
    }
  }
  async function rankTranscript(path: string, count: number, allowSignedIn = false): Promise<AiResult> {
    if (!aiConsent && !allowSignedIn) throw new Error("Confirm cloud transcript sharing first.");
    if (!accessToken) throw new Error("Sign in to use TV7 cloud AI.");
    const readiness = await backendRequest<LicenseReadiness>("/api/v1/auth/license", accessToken);
    setLicense(readiness);
    if (!readiness.can_request_engine_cloud_ai_token || !readiness.cloud_ai_available)
      throw new Error(`Cloud AI is unavailable: ${readiness.reason_code ?? readiness.license_status}. Local timing candidates remain available.`);
    const cues = await request<{ cues: { start_seconds: number; end_seconds: number; text: string }[] }>(
      base, token, `/v1/transcripts/cues?path=${encodeURIComponent(path)}`,
    );
    if (!cues.cues.length) throw new Error("The transcript has no timed cues for AI review.");
    let delegated = false;
    try {
      const cloudToken = await backendRequest<{ token: string; token_type: string; scope: string; expires_in_seconds: number; credits_remaining: number }>(
        "/api/v1/cloud-ai/engine-token", accessToken, { method: "POST" },
      );
      delegated = true;
      await request(base, token, "/v1/ai/cloud-token", {
        method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(cloudToken),
      });
      const result = await request<AiResult>(base, token, "/v1/ai/transcript-intelligence", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ transcript: cues.cues, clip_duration: "medium", timeline_target: "entire_video", max_suggestions: Math.max(1, Math.min(12, count)) }),
      });
      setAiUsage(result.usage);
      if (result.usage?.credits_remaining != null)
        setLicense((current) => current ? { ...current, cloud_ai_credits_remaining: result.usage!.credits_remaining! } : current);
      return result;
    } finally {
      if (delegated) await request(base, token, "/v1/ai/cloud-token", { method: "DELETE" }).catch(() => {});
    }
  }
  const [subtitleLanguage, setSubtitleLanguage] = useState("en");
  const [translationConsent, setTranslationConsent] = useState(false);
  const [translationBusy, setTranslationBusy] = useState(false);
  const [translationError, setTranslationError] = useState("");
  async function translateClipSubtitles(clip: ClipDraft) {
    if (!accessToken || !translationConsent || translationBusy) return;
    const original = clip.originalTranscriptPath ?? clip.transcriptPath ?? transcript?.transcript_path;
    if (!original) { setTranslationError("Acquire the source transcript first."); return; }
    setTranslationBusy(true); setTranslationError("");
    let delegated = false;
    try {
      const source = await request<{ cues: { start_seconds: number; end_seconds: number; text: string }[] }>(base, token, `/v1/transcripts/cues?path=${encodeURIComponent(original)}`);
      const cues = source.cues.filter((cue) => cue.end_seconds > Number(clip.start) && cue.start_seconds < Number(clip.end));
      if (!cues.length) throw new Error("No subtitles in this clip range.");
      const cloudToken = await backendRequest("/api/v1/cloud-ai/engine-token", accessToken, { method: "POST" });
      await request(base, token, "/v1/ai/cloud-token", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(cloudToken) }); delegated = true;
      const texts: string[] = [];
      for (let index = 0; index < cues.length; index += 40) {
        const result = await request<{ texts: string[] }>(base, token, "/v1/ai/subtitle-translation", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ language: subtitleLanguage, texts: cues.slice(index, index + 40).map((cue) => cue.text) }) });
        texts.push(...result.texts);
      }
      const timestamp = (seconds: number) => new Date(Math.round(seconds * 1000)).toISOString().slice(11, 23);
      const vtt = "WEBVTT\n\n" + cues.map((cue, index) => `${timestamp(cue.start_seconds)} --> ${timestamp(cue.end_seconds)}\n${texts[index]!.replaceAll("-->", "→").replaceAll(/\s+/g, " ")}\n`).join("\n");
      const body = new FormData(); body.append("file", new File([vtt], `translated-${clip.id}-${subtitleLanguage}.vtt`, { type: "text/vtt" }));
      const imported = await request<{ transcript_path: string }>(base, token, "/v1/transcripts/import", { method: "POST", body });
      updateClip(clip.id, { originalTranscriptPath: original, transcriptPath: imported.transcript_path, subtitleLanguage, captionText: clip.text, result: undefined });
    } catch (error) { setTranslationError(String(error)); }
    finally { if (delegated) await request(base, token, "/v1/ai/cloud-token", { method: "DELETE" }).catch(() => {}); setTranslationBusy(false); setTranslationConsent(false); }
  }
  async function directClip(clip:ClipDraft,context?:LibraryVideo){
    if(!accessToken)throw new Error("Sign in to TV7 in Account to use the AI director.");
    const mediaPath=context?.media_path??fileResult?.media_path;
    if(!mediaPath)throw new Error("Open a source video first.");
    const wordPath=await ensureWordTiming(mediaPath,clip.wordTranscriptPath);
    const cloudToken=await backendRequest("/api/v1/cloud-ai/engine-token",accessToken,{method:"POST"});
    await request(base,token,"/v1/ai/cloud-token",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(cloudToken)});
    try{
      const result=await request<{plan:RemixPlan;model:string}>(base,token,"/v1/ai/remix-plan",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({word_path:wordPath,start:Number(clip.start),end:Number(clip.end),source_title:(context?.title??fileResult?.name??"Source video").slice(0,200),direction:"Punchy Argentine comedy. Open at 0.0s with a scroll-stopping clickbait hook banner/freeze_banner, then accent the strongest setups, reversals and punchlines with a well-timed full-frame reaction cutaway, original reaction cards, short sound stings and camera accents. Leave clean breathing room between beats."})});
      return {...(clip.remixSettings??defaultRemixSettings()),plan:result.plan};
    }finally{await request(base,token,"/v1/ai/cloud-token",{method:"DELETE"}).catch(()=>{});}
  }
  const postCopyLock = useRef(false);
  async function generatePostCopy(clip: ClipDraft, context?: LibraryVideo) {
    const media = context ? { media_path: context.media_path, name: displayVideoTitle(context) } : fileResult;
    if (postCopyLock.current || !media) return;
    if (!accessToken) { setPostCopyError("Sign in to TV7 in Account to generate post copy."); return; }
    const version = mediaVersion.current;
    const initialCopy = JSON.stringify(clip.postCopy);
    postCopyLock.current = true;
    setPostCopyBusy(clip.id);
    setPostCopyError("");
    let delegated = false;
    try {
      const readiness = await backendRequest<LicenseReadiness>("/api/v1/auth/license", accessToken);
      if (!readiness.can_request_engine_cloud_ai_token || !readiness.cloud_ai_available)
        throw new Error(`Cloud AI is unavailable: ${readiness.reason_code ?? readiness.license_status}. You can edit the starter copy locally.`);
      let wordPath = clip.wordTranscriptPath;
      const savedTranscript = clip.originalTranscriptPath ?? clip.transcriptPath ?? (context ? context.transcript_path : transcript?.transcript_path) ?? wordPath;
      if (!savedTranscript) wordPath = await ensureWordTiming(media.media_path);
      const transcriptPath = savedTranscript ?? wordPath;
      if (wordPath) saveWordTiming(media.media_path, wordPath);
      const cues = transcriptPath ? await request<{ cues: { start_seconds: number; end_seconds: number; text: string }[] }>(
        base, token, `/v1/transcripts/cues?path=${encodeURIComponent(transcriptPath)}`) : { cues: [] };
      const spoken = cues.cues.filter((cue) => cue.end_seconds > Number(clip.start) && cue.start_seconds < Number(clip.end))
        .map((cue) => cue.text).join(" ").slice(0, 12000) || clip.text.slice(0, 12000);
      if (!spoken.trim()) throw new Error("This clip needs a transcript before AI can write accurate post copy.");
      const videoContext = cues.cues.map((cue) => cue.text).join(" ").slice(0, 6000);
      const establishedMood = (context ? context.clips.map(item => ({ id:item.id, postCopy:item.post_copy })) : clipDraftsRef.current).find((item) => item.id !== clip.id && item.postCopy?.source !== "template" && item.postCopy?.mood)?.postCopy?.mood;
      const cloudToken = await backendRequest<{ token: string; token_type: string; scope: string; expires_in_seconds: number; credits_remaining: number }>(
        "/api/v1/cloud-ai/engine-token", accessToken, { method: "POST" });
      delegated = true;
      await request(base, token, "/v1/ai/cloud-token", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(cloudToken) });
      const result = await request<PostCopyResult>(base, token, "/v1/ai/post-copy", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ source_title: media.name, clip_title: clip.title?.trim() || "Selected clip", transcript_text: spoken,
          video_context: videoContext, video_mood: establishedMood ?? null }),
      });
      if (!context && version !== mediaVersion.current) return;
      const latestClip = context ? clip : clipDraftsRef.current.find(item => item.id === clip.id);
      if (!latestClip || latestClip.start !== clip.start || latestClip.end !== clip.end || JSON.stringify(latestClip.postCopy) !== initialCopy) {
        setPostCopyError("Clip text changed while AI was writing. Your edits were kept; generate again when ready."); return;
      }
      if (!context) updateClip(clip.id, { ...(wordPath ? { wordTranscriptPath: wordPath } : {}), postCopy: { ...result.copy, source: "ai", model: result.model },
        ...(!latestClip.title?.trim() || /^Clip \d+$/i.test(latestClip.title.trim()) ? { title: result.copy.youtube_title } : {}) });
      setAiUsage(result.usage);
      return { ...result.copy, source: "ai" as const, model: result.model };
    } catch (error) { setPostCopyError(String(error)); return false; }
    finally {
      if (delegated) await request(base, token, "/v1/ai/cloud-token", { method: "DELETE" }).catch(() => {});
      postCopyLock.current = false;
      setPostCopyBusy(null);

    }
  }
  async function estimateAiCalls(path: string) {
    try {
      const result = await request<{ cues: { start_seconds: number; end_seconds: number; text: string }[] }>(base, token, `/v1/transcripts/cues?path=${encodeURIComponent(path)}`);
      setAiCueEstimates((current) => ({ ...current, [path]: { count: result.cues.length } }));
    } catch (error) {
      setAiCueEstimates((current) => ({ ...current, [path]: { count: 0, error: String(error) } }));
    }
  }
  async function rankLocalTranscript() {
    if (!transcript || aiBusy) return;
    setAiBusy(true); setLocalAiError("");
    try { const result = await rankTranscript(transcript.transcript_path, clipCount); setLocalAiSuggestions(result.clips); setLocalAiModel(`${result.provider} · ${result.model}`); }
    catch (error) { setLocalAiError(String(error)); }
    finally { setAiBusy(false); setAiConsent(false); }
  }
  async function rankBatchTranscript(jobId: string) {
    const video = batchVideos[jobId];
    if (!video?.transcriptPath || aiBusy) return;
    setAiBusy(true); updateBatchVideo(jobId, { aiError: "" });
    try {
      const result = await rankTranscript(video.transcriptPath, video.count);
      updateBatchVideo(jobId, { aiSuggestions: result.clips, aiUsage: result.usage, aiModel: `${result.provider} · ${result.model}` });
    } catch (error) { updateBatchVideo(jobId, { aiError: String(error) }); }
    finally { setAiBusy(false); setAiConsent(false); }
  }
  function draftFromSuggestion(suggestion: AiSuggestion): ClipDraft {
    return { id: crypto.randomUUID(), title: suggestion.title, proposalSource: "ai", start_seconds: suggestion.start_seconds, end_seconds: suggestion.end_seconds,
      start: suggestion.start_seconds.toFixed(2), end: suggestion.end_seconds.toFixed(2),
      text: "", captionText: "", cue_count: 0,
      burnSubtitles: true, subtitleStyle: normalizeSubtitleStyle({ ...defaultSubtitleStyle, ...activeProfile.subtitleStyle, preset: "word_box" }), format: "vertical_9_16_blur" };
  }
  function addLocalSuggestion(suggestion: AiSuggestion) {
    if (!Number.isFinite(suggestion.start_seconds) || !Number.isFinite(suggestion.end_seconds) || suggestion.start_seconds < 0 || suggestion.end_seconds <= suggestion.start_seconds) return;
    if (clipDrafts.length >= 12) return;
    const draft = draftFromSuggestion(suggestion);
    setClipDrafts((current) => current.length < 12 ? [...current, draft] : current);
    if (openedBatchJobId) addBatchSuggestion(openedBatchJobId, suggestion, draft);
    setSelectedClipId(draft.id);
    selectedClipIdRef.current = draft.id;
  }
  function replaceLocalWithSuggestion(suggestion: AiSuggestion) {
    if (!Number.isFinite(suggestion.start_seconds) || !Number.isFinite(suggestion.end_seconds) || suggestion.start_seconds < 0 || suggestion.end_seconds <= suggestion.start_seconds) return;
    const draft = draftFromSuggestion(suggestion);
    setClipDrafts([draft]);
    if (openedBatchJobId) updateBatchVideo(openedBatchJobId, { clips: [draft] });
    setSelectedClipId(draft.id);
    selectedClipIdRef.current = draft.id;
  }
  function addBatchSuggestion(jobId: string, suggestion: AiSuggestion, existingDraft?: ClipDraft) {
    if (!Number.isFinite(suggestion.start_seconds) || !Number.isFinite(suggestion.end_seconds) || suggestion.start_seconds < 0 || suggestion.end_seconds <= suggestion.start_seconds) return;
    setBatchVideos((current) => {
      const video = current[jobId];
      return video && video.clips.length < 12 ? { ...current, [jobId]: { ...video, clips: [...video.clips, existingDraft ?? draftFromSuggestion(suggestion)] } } : current;
    });
  }
  function replaceBatchWithSuggestion(jobId: string, suggestion: AiSuggestion) {
    if (!Number.isFinite(suggestion.start_seconds) || !Number.isFinite(suggestion.end_seconds) || suggestion.start_seconds < 0 || suggestion.end_seconds <= suggestion.start_seconds) return;
    setBatchVideos((current) => current[jobId] ? { ...current, [jobId]: { ...current[jobId], clips: [draftFromSuggestion(suggestion)] } } : current);
  }
  async function signIn() {
    setLoginBusy(true);
    setLoginError("");
    try {
      const result = await backendRequest<{ access_token: string; refresh_token: string }>(
        "/api/v1/auth/login",
        "",
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            email: accountEmail.trim(),
            password: accountPassword,
          }),
        },
      );
      saveSession({ accessToken: result.access_token, refreshToken: result.refresh_token, email: accountEmail.trim().toLowerCase() });
      accessTokenRef.current = result.access_token;
      setAccessToken(result.access_token);
      setSignedInEmail(accountEmail.trim().toLowerCase());
      setAccountPassword("");
      try {
        setLicense(
          await backendRequest<LicenseReadiness>(
            "/api/v1/auth/license",
            result.access_token,
          ),
        );
      } catch {
        setLicense(null);
      }
      try {
        await refreshPublishingTargets(result.access_token);
      } catch { setYoutubeConnection(null); setPublishingTargets([]); }
    } catch (error) {
      setAccountPassword("");
      setLoginError(String(error));
    } finally {
      setLoginBusy(false);
    }
  }
  async function refreshPublishingTargets(auth = accessToken, profileId = activeProfileId) {
    const [connections, targets, providers, social] = await Promise.all([
      backendRequest<YouTubeConnection[]>("/api/v1/youtube/connections", auth),
      backendRequest<PublishingTarget[]>(`/api/v1/publishing-targets?creator_profile_id=${encodeURIComponent(profileId)}`, auth),
      backendRequest<SocialProvider[]>("/api/v1/social/providers", auth),
      backendRequest<SocialConnection[]>(`/api/v1/social/connections?creator_profile_id=${encodeURIComponent(profileId)}`, auth),
    ]);
    if (profileId !== activeProfileIdRef.current || auth !== accessTokenRef.current) return;
    setSocialScope({ auth, profileId });
    setSocialProviders(providers);
    setSocialConnections(social);
    const youtube = connections.find((connection) => connection.creator_profile_id === profileId) ?? null;
    setYoutubeConnection(youtube);
    setPublishingTargets(targets);
    const first = targets[0];
    setTargetAccount(first?.account_ref ?? "");
    setDirectTarget(social.find((connection) => connection.platform === "youtube" && connection.creator_profile_id === profileId && connection.connected)?.account_ref ?? "");
    setPendingSocialLogin((pending) => pending && pending.profileId === profileId && !social.some((item) => item.platform === pending.platform && item.connected && !pending.priorVersions.includes(`${item.id}:${item.updated_at ?? ""}`)) ? pending : null);
    setConnectionError("");
  }
  function validateSocialLoginUrl(url: string) {
    const parsed = new URL(url);
    const paths: Record<string, string[]> = { "accounts.google.com": ["/o/oauth2/v2/auth", "/o/oauth2/auth"], "www.instagram.com": ["/oauth/authorize", "/oauth/authorize/"], "www.tiktok.com": ["/v2/auth/authorize", "/v2/auth/authorize/"] };
    if (!paths[parsed.hostname]?.includes(parsed.pathname) || parsed.hash || parsed.protocol !== "https:" || parsed.username || parsed.password || parsed.port || !["accounts.google.com", "www.instagram.com", "www.tiktok.com"].includes(parsed.hostname)) {
      throw new Error("Backend returned an unsupported provider login address.");
    }
    return parsed.href;
  }
  async function openSocialLogin(url: string) {
    const safeUrl = validateSocialLoginUrl(url);
    if (isTauri()) await invoke("open_social_login", { url: safeUrl });
    else {
      const opened = window.open(safeUrl, "_blank");
      if (!opened) throw new Error("Allow the provider login window, then choose Open login again.");
      opened.opener = null;
    }
  }
  async function beginSocialConnection(platform: string) {
    const auth = accessToken;
    const profileId = activeProfileId;
    // Reserve the browser window during the user gesture, before the API request.
    const loginWindow = !isTauri() ? window.open("about:blank", "_blank") : null;
    if (loginWindow) loginWindow.opener = null;
    setConnectionError("");
    setConnectionBusy(platform);
    try {
      const result = await backendRequest<{ authorization_url: string }>(`/api/v1/social/${platform}/connect`, accessToken, {
        method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ creator_profile_id: profileId }),
      });
      if (profileId !== activeProfileIdRef.current || auth !== accessTokenRef.current) { loginWindow?.close(); return; }
      const safeUrl = validateSocialLoginUrl(result.authorization_url);
      setPendingSocialLogin({ platform, url: safeUrl, profileId, priorVersions: socialConnections.map((item) => `${item.id}:${item.updated_at ?? ""}`) });
      if (loginWindow) loginWindow.location.replace(safeUrl);
      else await openSocialLogin(safeUrl);
    } catch (error) { loginWindow?.close(); setConnectionError(String(error)); }
    finally { setConnectionBusy(""); }
  }
  async function disconnectSocialAccount(connection: SocialConnection) {
    setConnectionBusy(connection.id);
    setConnectionError("");
    try {
      await backendRequest(`/api/v1/social/connections/${encodeURIComponent(connection.id)}`, accessToken, { method: "DELETE" });
      await refreshPublishingTargets();
    } catch (error) { setConnectionError(String(error)); }
    finally { setConnectionBusy(""); }
  }
  async function checkSocialConnections() {
    setConnectionBusy("refresh");
    try { await refreshPublishingTargets(); }
    catch (error) { setConnectionError(String(error)); }
    finally { setConnectionBusy(""); }
  }
  async function refreshAiReadiness() {
    if (!accessToken) return;
    try { setLicense(await backendRequest<LicenseReadiness>("/api/v1/auth/license", accessToken)); }
    catch (error) { setLocalAiError(String(error)); }
  }
  function signOut() {
    saveSession(null);
    if (base) void request(base, token, "/v1/ai/cloud-token", { method: "DELETE" }).catch(() => {});
    accessTokenRef.current = "";
    setAccessToken("");
    setSignedInEmail("");
    setYoutubeConnection(null);
    setPublishingTargets([]);
    setSocialConnections([]);
    setSocialProviders([]);
    setPendingSocialLogin(null);
    setLicense(null);
    setAsset(null);
    setCloudClip(null);
    setDraft(null);
    setQueue([]);
  }
  useEffect(() => {
    const changed = (event: Event) => {
      const value = (event as CustomEvent<AccountSession | null>).detail;
      if (!value) { signOut(); return; }
      accessTokenRef.current = value.accessToken;
      setAccessToken(value.accessToken);
      setSignedInEmail(value.email);
    };
    const expired = () => setLoginError("Your TV7 session expired. Sign in again to access connected accounts.");
    window.addEventListener(sessionChanged, changed);
    window.addEventListener("tv7-session-expired", expired);
    return () => {
      window.removeEventListener(sessionChanged, changed);
      window.removeEventListener("tv7-session-expired", expired);
    };
  });

  function buildSchedulePlan() {
    setPlanError("");
    if (schedulePlan) { setPlanError("Archive the current local plan before creating another. Backend drafts already created by it remain in the queue."); return; }
    const start = new Date(planStart);
    if (!Number.isFinite(start.getTime()) || start.getTime() <= Date.now()) { setPlanError("Choose a future start date and time."); return; }
    if (planCadence === "custom" && (!Number.isInteger(planSpacing) || planSpacing < 1 || planSpacing > 30)) { setPlanError("Spacing must be 1–30 days."); return; }
    const destinations = publishingTargets.filter((target) =>
      (planDestination === "all" || planDestination === `${target.platform}|${target.account_ref}`));
    if (!destinations.length) { setPlanError("Connect a destination in Account before creating a local plan."); return; }
    const rendered = readyLibraryClips.filter((item) => planIncluded[item.id] !== false);
    if (!rendered.length) { setPlanError("Select at least one rendered clip."); return; }
    if (rendered.length > 50) { setPlanError("Select at most 50 clips for one schedule plan."); return; }
    if (rendered.some(({ clip }) => destinations.some((target) => !hasPostCopyForPlatform(clip.post_copy, target.platform)))) {
      setPlanError("Write or generate post copy for each selected clip in Clip editor before creating a plan."); return;
    }
    if (new Date(releaseSlot(start, 0, planCadence, planSpacing)).getTime() <= Date.now()) { setPlanError("Choose a day whose first release slot is still in the future."); return; }
    const items: PlanItem[] = rendered.flatMap(({ id, video, clip, title, sourceTitle }, index) => destinations.map((target) => ({
      id: `${id}|${target.platform}|${target.account_ref}`, jobId: id, platform: target.platform, target: target.account_ref,
      sourcePath: video.media_path, sourceTitle, title,
      render: { output_path: clip.output_path!, duration_seconds: outputFrames(Number(clip.end)-Number(clip.start),clip.remix_settings?.plan)/30,
        start_seconds: Number(clip.start), end_seconds: Number(clip.end), caption_text: clip.caption_text },
      caption: platformCaption(clip.post_copy!, target.platform),
      scheduledAt: releaseSlot(start, index, planCadence, planSpacing),
      idempotencyKey: crypto.randomUUID(), status: "pending",
    })));
    setSchedulePlan({ ownerEmail: signedInEmail, profileId: activeProfileId, platform: planDestination === "all" ? "all" : destinations[0]!.platform,
      target: planDestination === "all" ? "all" : destinations[0]!.account_ref, items, approvalStarted: false });
  }
  function updatePlanItem(id: string, patch: Partial<PlanItem>) {
    setSchedulePlan((current) => current ? { ...current, items: current.items.map((item) => item.id === id ? { ...item, ...patch } : patch.scheduledAt && item.jobId === current.items.find((selected) => selected.id === id)?.jobId ? { ...item, scheduledAt: patch.scheduledAt } : item) } : null);
  }
  function planUpload(item: PlanItem): BackendDirectUpload | undefined {
    if (!schedulePlan || schedulePlan.ownerEmail !== signedInEmail || schedulePlan.profileId !== activeProfileId) return;
    const receipt = directReceipts.find((receipt) => receipt.ownerEmail === signedInEmail && receipt.review.profileId === activeProfileId && receipt.review.clipId === item.jobId && receipt.review.destinationRef === (item.target ?? schedulePlan.target) && receipt.review.outputPath === item.render.output_path);
    return backendDirectUploads.find((upload) => upload.creator_profile_id === activeProfileId && upload.target_account_ref === (item.target ?? schedulePlan.target) && (upload.idempotency_key === item.idempotencyKey || upload.upload_id === receipt?.uploadId));
  }
  async function approveLocalYouTubePlan() {
    if (!schedulePlan || !accessToken || planBusy || schedulePlan.profileId !== activeProfileId || schedulePlan.ownerEmail !== signedInEmail) return;
    if (schedulePlan.items.some((item) => (item.platform ?? schedulePlan.platform) !== "youtube_shorts" || !directYouTubeTargets.some((target) => target.account_ref === (item.target ?? schedulePlan.target) && target.publishing_ready))) { setPlanError("YouTube public scheduling requires publishing readiness. The local plan is saved; no media was uploaded."); return; }
    setPlanBusy(true); setPlanError("");
    setSchedulePlan((current) => current ? { ...current, approvalStarted: true } : null);
    try {
      for (const item of schedulePlan.items) {
        if (item.status === "draft_ready" || planUpload(item)?.status === "scheduled") continue;
        const chosen = readyLibraryClips.find((clip) => clip.id === item.jobId);
        const target = directYouTubeTargets.find((target) => target.account_ref === (item.target ?? schedulePlan.target));
        if (!chosen || !target) throw new Error("Clip or destination changed. Review the local plan again.");
        const receipt = await approveDirectYouTubeUpload({ profileId: activeProfileId, clipId: chosen.id, localClipId: chosen.clip.id,
          outputPath: item.render.output_path, destinationRef: target.account_ref, destinationName: target.display_name, channelId: target.account_ref.slice(8),
          title: item.title, description: item.caption, mode: "publish_later", publishAt: item.scheduledAt, idempotencyKey: item.idempotencyKey }, false, true);
        updatePlanItem(item.id, { status: receipt?.status === "verified" && receipt.providerStatus === "scheduled" ? "draft_ready" : "error", error: receipt?.status === "processing" ? "Uploaded; YouTube is processing. Verify the receipt before retrying." : receipt?.error ?? "Provider verification is incomplete." });
        if (receipt?.status === "error") break;
      }
    } catch (error) { setPlanError(String(error)); }
    finally { setPlanBusy(false); }
  }
  async function approveSchedulePlan() {
    if (!schedulePlan || !accessToken || approvalInFlight.current) return;
    if (schedulePlan.ownerEmail && schedulePlan.ownerEmail !== signedInEmail) { setPlanError("Sign in with the account that approved this plan to retry it."); return; }
    if (schedulePlan.profileId !== activeProfileId) { setPlanError("Switch to the creator profile that owns this plan."); return; }
    if (!schedulePlan.items.length) return;
    for (const item of schedulePlan.items) {
      const platform = item.platform ?? schedulePlan.platform;
      const target = item.target ?? schedulePlan.target;
      const prefix = `${platform === "youtube_shorts" ? "youtube" : platform}:`;
      if (!target.startsWith(prefix) || target.length <= prefix.length) {
        setPlanError(`Target account reference must start with ${prefix} and include an account ID.`); return;
      }
    }
    approvalInFlight.current = true;
    setPlanBusy(true);
    setPlanError("");
    setSchedulePlan((current) => current ? { ...current, ownerEmail: current.ownerEmail || signedInEmail, approvalStarted: true } : null);
    const sharedAssets = new Map<string, BackendAsset>();
    const sharedClips = new Map<string, number>();
    for (const existing of schedulePlan.items) {
      if (existing.asset) sharedAssets.set(existing.render.output_path, existing.asset);
      if (existing.clipId) sharedClips.set(existing.render.output_path, existing.clipId);
    }
    for (const original of schedulePlan.items) {
      if (original.status === "draft_ready") continue;
      let item = original;
      const save = (patch: Partial<PlanItem>) => { item = { ...item, ...patch }; updatePlanItem(item.id, patch); };
      try {
        if (!item.asset && sharedAssets.has(item.render.output_path)) save({ asset: sharedAssets.get(item.render.output_path), status: "asset_ready" });
        if (!item.clipId && sharedClips.has(item.render.output_path)) save({ clipId: sharedClips.get(item.render.output_path), status: "clip_ready" });
        if (!item.render.media_id || (item.sourcePath && !item.asset)) {
          const registered = await request<{ media_id: string }>(base, token, "/v1/media/register-export", {
            method: "POST", headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ output_path: item.render.output_path }),
          });
          save({ render: { ...item.render, media_id: registered.media_id } });
        }
        if (!item.asset) {
          save({ status: "uploading", error: "" });
          const headers = new Headers();
          if (token) headers.set("Authorization", `Bearer ${token}`);
          const response = await fetch(`${base}/v1/media/assets/${encodeURIComponent(item.render.media_id!)}`, { headers });
          if (!response.ok) throw new Error(`Engine export unavailable (HTTP ${response.status}). Rerender this clip in Library, then retry.`);
          if (!response.headers.get("Content-Type")?.startsWith("video/mp4")) throw new Error("Engine did not return an MP4 clip.");
          const body = new FormData();
          body.append("file", await response.blob(), `tv7-clip-${item.idempotencyKey}.mp4`);
          const uploaded = await backendRequest<BackendAsset>("/api/v1/uploads/assets", accessToken, { method: "POST", body });
          save({ asset: uploaded, status: "asset_ready" });
          sharedAssets.set(item.render.output_path, uploaded);
        }
        if (!item.clipId) {
          const source = item.sourcePath ? { title: item.sourceTitle ?? item.title } : jobs.find((job) => job.jobId === item.jobId);
          if (!source) throw new Error("Source video metadata is unavailable.");
          const sourceId = item.sourcePath
            ? Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(item.sourcePath))))
              .map((byte) => byte.toString(16).padStart(2, "0")).join("")
            : item.jobId;
          const video = await backendRequest<CloudVideo>("/api/v1/videos/local", accessToken, {
            method: "POST", headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ source_url: `local://${sourceId}`, title: source.title, original_filename: source.title }),
          });
          const existing = video.clips.find((clip) => clip.asset_url === item.asset!.asset_url);
          const created = existing ?? await backendRequest<CloudClip>(`/api/v1/videos/${video.id}/clips`, accessToken, {
            method: "POST", headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ start_sec: item.render.start_seconds, end_sec: item.render.end_seconds,
              asset_url: item.asset!.asset_url, asset_checksum: item.asset!.asset_checksum,
              asset_size_bytes: item.asset!.asset_size_bytes, ready_local_only: false,
              caption_text: item.caption, status: "ready" }),
          });
          save({ clipId: created.id, status: "clip_ready" });
          sharedClips.set(item.render.output_path, created.id);
        }
        const draft = await backendRequest<ScheduleDraft>(`/api/v1/clips/${item.clipId}/schedule-drafts`, accessToken, {
          method: "POST", headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ platform: item.platform ?? schedulePlan.platform, target_account_ref: item.target ?? schedulePlan.target, creator_profile_id: schedulePlan.profileId,
            scheduled_at: item.scheduledAt, caption: item.caption, asset_id: item.asset!.asset_id,
            idempotency_key: item.idempotencyKey }),
        });
        save({ draftId: draft.id, status: "draft_ready", error: "" });
      } catch (error) { save({ status: "error", error: String(error) }); }
    }
    setPlanBusy(false);
    approvalInFlight.current = false;
    void loadQueue();
  }
  async function changeQueueJob(id: number, action: "cancel" | "reschedule") {
    if (!accessToken) return;
    setQueueBusy(true);
    setQueueError("");
    try {
      const scheduled = new Date(queueDates[id]);
      if (action === "reschedule" && (!Number.isFinite(scheduled.getTime()) || scheduled.getTime() <= Date.now())) throw new Error("Choose a future date and time.");
      const updated = await backendRequest<QueueJob>(`/api/v1/schedule-jobs/${id}${action === "cancel" ? "/cancel" : ""}`, accessToken, {
        method: action === "cancel" ? "POST" : "PATCH",
        ...(action === "reschedule" ? { headers: { "Content-Type": "application/json" }, body: JSON.stringify({ scheduled_at: scheduled.toISOString() }) } : {}),
      });
      setQueue((current) => current.map((job) => job.id === id ? updated : job));
    } catch (error) { setQueueError(String(error)); }
    finally { setQueueBusy(false); }
  }
  function prepareDirectYouTubeReview() {
    setDirectError("");
    const chosen = readyLibraryClips.find((item) => item.id === directClipId);
    const target = directYouTubeTargets.find((item) => item.account_ref === directTarget);
    if (!accessToken || !chosen?.clip.output_path) { setDirectError("Sign in and select a rendered local clip."); return; }
    if (!target || !directTarget.startsWith("youtube:")) { setDirectError("Choose a connected YouTube destination for this creator profile."); return; }
    if (directMode === "publish_later" && !target.publishing_ready) { setDirectError("Scheduled publication requires a publishing-ready YouTube destination. Private test uploads remain available."); return; }
    const title = directTitle.trim();
    if (!title || title.length > 100 || /[<>]/.test(title)) { setDirectError("Enter a YouTube title of 1–100 characters without angle brackets."); return; }
    const description = directDescription.trim();
    if (!description || description.length > 5000) { setDirectError("Enter a YouTube description of 1–5000 characters."); return; }
    let publishAt: string | null = null;
    if (directMode === "publish_later") {
      const date = new Date(directPublishAt);
      if (!Number.isFinite(date.getTime()) || date.getTime() <= Date.now()) { setDirectError("Choose a future publish date and time."); return; }
      publishAt = date.toISOString();
    }
    setDirectConfirmed(false);
    setDirectReview({ profileId: activeProfileId, clipId: chosen.id, localClipId: chosen.clip.id, outputPath: chosen.clip.output_path,
      destinationRef: target.account_ref, destinationName: target.display_name, channelId: target.account_ref.slice("youtube:".length),
      title, description,
      mode: directMode, publishAt, idempotencyKey: crypto.randomUUID() });
  }
  async function changeYouTubeRelease(uploadId: number) {
    if (!accessToken || directBusy) return;
    const date = new Date(directReleaseDates[uploadId] ?? "");
    if (!Number.isFinite(date.getTime()) || date.getTime() <= Date.now()) { setDirectError("Choose a future release date."); return; }
    setDirectBusy(true); setDirectError("");
    try {
      const updated = await backendRequest<BackendDirectUpload>(`/api/v1/youtube/local-uploads/${uploadId}/schedule`, accessToken, { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ scheduled_at: date.toISOString() }) });
      setBackendDirectUploads((current) => current.map((item) => item.upload_id === uploadId ? updated : item));
      setDirectReleaseDates((current) => { const next = { ...current }; delete next[uploadId]; return next; });
      setDirectReceipts((current) => current.map((receipt) => receipt.uploadId === uploadId ? { ...receipt, providerStatus: updated.status, status: "verified", review: { ...receipt.review, mode: "publish_later", publishAt: updated.scheduled_at } } : receipt));
      const receipt = directReceipts.find((item) => item.uploadId === uploadId);
      if (receipt && updated.scheduled_at) setSchedulePlan((current) => current && current.ownerEmail === signedInEmail && current.profileId === receipt.review.profileId ? { ...current, items: current.items.map((item) => item.jobId === receipt.review.clipId ? { ...item, scheduledAt: updated.scheduled_at!, status: "draft_ready" } : item) } : current);
    } catch (error) { setDirectError(String(error)); }
    finally { setDirectBusy(false); }
  }
  async function verifyDirectUpload(uploadId: number, remoteVideoId?: string) {
    if (!accessToken || directInFlight.current) return;
    setDirectBusy(true);
    directInFlight.current = true;
    try {
      const result = await backendRequest<{ status: string; remote_video_id?: string }>(
        `/api/v1/youtube/local-uploads/${uploadId}/verify`, accessToken,
        { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ remote_video_id: remoteVideoId }) });
      setDirectReceipts((current) => current.map((receipt) => receipt.uploadId === uploadId ? {
        ...receipt, remoteVideoId: result.remote_video_id || receipt.remoteVideoId,
        providerStatus: result.status, status: result.status === "processing" ? "processing" :
          ["private_uploaded", "scheduled"].includes(result.status) ? "verified" : "error",
        error: ["processing", "private_uploaded", "scheduled"].includes(result.status) ? "" : `Backend status: ${result.status}`,
      } : receipt));
      setBackendDirectUploads((current) => current.map((item) => item.upload_id === uploadId ? {
        ...item, status: result.status, remote_video_id: result.remote_video_id || item.remote_video_id,
      } : item));
    } catch (error) { setDirectError(String(error)); }
    finally { directInFlight.current = false; setDirectBusy(false); }
  }
  async function approveDirectYouTubeUpload(reviewOverride?: DirectYouTubeReview, batchApproved = false, planApproved = false) {
    const review = reviewOverride ?? directReview;
    if (!review || !accessToken || !(planApproved || (batchApproved ? directBatchConfirmed : reviewOverride ? directRetryConfirmed[review.idempotencyKey] : directConfirmed)) || directInFlight.current) return;
    const existingReceipt = directReceipts.find((item) => item.review.idempotencyKey === review.idempotencyKey) ?? directReceipts.find((item) => item.ownerEmail === signedInEmail && item.review.profileId === review.profileId && item.review.localClipId === review.localClipId && item.review.outputPath === review.outputPath && item.review.destinationRef === review.destinationRef && item.uploadId);
    if (review.profileId !== activeProfileId || (existingReceipt?.ownerEmail && existingReceipt.ownerEmail !== signedInEmail)) {
      setDirectError("Switch to the creator profile and TV7 account that prepared this upload."); return;
    }
    const target = directYouTubeTargets.find((item) => item.account_ref === review.destinationRef && item.display_name === review.destinationName);
    if (!target || review.channelId !== review.destinationRef.slice("youtube:".length)) {
      setDirectError("The verified destination changed. Review the exact channel again."); return;
    }
    if (review.mode === "publish_later" && !target.publishing_ready) {
      setDirectError("Scheduled publication requires a publishing-ready YouTube destination."); return;
    }
    directInFlight.current = true;
    setDirectBusy(true);
    setDirectError("");
    let receipt: DirectUploadReceipt = existingReceipt ?? { ownerEmail: signedInEmail, review, status: "ready" };
    const save = (patch: Partial<DirectUploadReceipt>) => {
      receipt = { ...receipt, ...patch };
      setDirectReceipts((current) => [receipt, ...current.filter((item) => item.review.idempotencyKey !== receipt.review.idempotencyKey && (!receipt.uploadId || item.uploadId !== receipt.uploadId))]);
    };
    try {
      if (receipt.uploadId) {
        const existing = await backendRequest<{ status: string; remote_video_id?: string }>(
          `/api/v1/youtube/local-uploads/${encodeURIComponent(receipt.uploadId)}`, accessToken);
        if (["private_uploaded", "scheduled"].includes(existing.status)) {
          if (review.mode === "publish_later" && review.publishAt && review.publishAt !== receipt.review.publishAt) {
            const changed = await backendRequest<BackendDirectUpload>(`/api/v1/youtube/local-uploads/${receipt.uploadId}/schedule`, accessToken, { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ scheduled_at: review.publishAt }) });
            save({ review: { ...review, idempotencyKey: receipt.review.idempotencyKey }, remoteVideoId: changed.remote_video_id ?? undefined, providerStatus: changed.status, status: "verified", error: "" });
            return receipt;
          }
          save({ remoteVideoId: existing.remote_video_id, providerStatus: existing.status, status: "verified", error: "" });
          return receipt;
        }
        if (existing.status === "processing") {
          const verified = await backendRequest<{ status: string; remote_video_id?: string }>(
            `/api/v1/youtube/local-uploads/${receipt.uploadId}/verify`, accessToken,
            { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ remote_video_id: existing.remote_video_id }) });
          if (!(verified.status === "processing" || ["private_uploaded", "scheduled"].includes(verified.status))) throw new Error(`Backend verification returned ${verified.status}.`);
          save({ remoteVideoId: verified.remote_video_id || existing.remote_video_id, providerStatus: verified.status,
            status: verified.status === "processing" ? "processing" : "verified", error: "" });
          return receipt;
        }
      }
      if (receipt.uploadId && receipt.remoteVideoId) {
        save({ status: "verifying", error: "" });
        const verified = await backendRequest<{ status: string; remote_video_id?: string }>(
          `/api/v1/youtube/local-uploads/${encodeURIComponent(receipt.uploadId)}/verify`, accessToken,
          { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ remote_video_id: receipt.remoteVideoId }) });
        if (!(verified.status === "processing" || ["private_uploaded", "scheduled"].includes(verified.status))) throw new Error(`Backend has not verified the upload (${verified.status}).`);
        save({ remoteVideoId: verified.remote_video_id || receipt.remoteVideoId, providerStatus: verified.status, status: verified.status === "processing" ? "processing" : "verified" });
        return receipt;
      }
      const registered = await request<{ media_id: string }>(base, token, "/v1/media/register-export", {
        method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ output_path: review.outputPath }),
      });
      const media = await request<{ size_bytes: number; checksum_sha256: string; content_type: string }>(
        base, token, `/v1/media/${encodeURIComponent(registered.media_id)}/transfer-metadata`);
      if (!Number.isSafeInteger(media.size_bytes) || media.size_bytes <= 0 || !/^[a-f0-9]{64}$/i.test(media.checksum_sha256) || media.content_type !== "video/mp4")
        throw new Error("Engine transfer metadata is invalid. Rerender this clip and retry.");
      save({ status: "creating", error: "" });
      type UploadSession = { upload_id: number; status: string; upload_url?: string; upload_headers?: Record<string, string>; size_bytes: number; checksum_sha256: string; idempotency_key: string; remote_video_id?: string; scheduled_at: string | null; title: string; description: string };
      let session: UploadSession;
      if (receipt.uploadId) {
        session = await backendRequest<UploadSession>(`/api/v1/youtube/local-uploads/${encodeURIComponent(receipt.uploadId)}/transfer`, accessToken, { method: "POST" });
      } else {
        session = await backendRequest<UploadSession>("/api/v1/youtube/local-uploads", accessToken, {
          method: "POST", headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ creator_profile_id: review.profileId, target_account_ref: review.destinationRef,
            idempotency_key: review.idempotencyKey, local_clip_id: review.localClipId, title: review.title,
            description: review.description, size_bytes: media.size_bytes, checksum_sha256: media.checksum_sha256,
            content_type: media.content_type, ...(review.publishAt ? { scheduled_at: review.publishAt } : {}) }),
        });
      }
      if (!Number.isSafeInteger(session.upload_id) || session.size_bytes !== media.size_bytes || session.checksum_sha256 !== media.checksum_sha256)
        throw new Error("Backend upload record does not match the rendered clip.");
      save({ uploadId: session.upload_id, review: { ...review, idempotencyKey: session.idempotency_key, title: session.title, description: session.description,
        publishAt: session.scheduled_at, mode: session.scheduled_at ? "publish_later" : "private_now" } });
      if (["private_uploaded", "scheduled", "processing"].includes(session.status)) {
        if (!session.remote_video_id) throw new Error("Existing upload has no YouTube video ID. Reconcile this receipt before retrying.");
        if (review.mode === "publish_later" && review.publishAt && review.publishAt !== session.scheduled_at) {
          const changed = await backendRequest<BackendDirectUpload>(`/api/v1/youtube/local-uploads/${session.upload_id}/schedule`, accessToken,
            { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ scheduled_at: review.publishAt }) });
          save({ providerStatus: changed.status, remoteVideoId: changed.remote_video_id ?? session.remote_video_id, status: "verified",
            review: { ...receipt.review, mode: "publish_later", publishAt: changed.scheduled_at }, error: "" });
        } else {
          save({ providerStatus: session.status, remoteVideoId: session.remote_video_id, status: session.status === "processing" ? "processing" : "verified", error: "" });
        }
        return receipt;
      }
      if (!session.upload_url || !session.upload_headers?.Authorization)
        throw new Error("Backend did not return a usable short-lived YouTube transfer capability.");
      save({ uploadId: session.upload_id, status: "transferring" });
      const transferred = await request<{ remote_video_id: string }>(base, token, "/v1/transfers/youtube", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ media_id: registered.media_id, upload_url: session.upload_url, upload_headers: session.upload_headers,
          size_bytes: session.size_bytes, checksum_sha256: session.checksum_sha256 }),
      });
      save({ remoteVideoId: transferred.remote_video_id, status: "verifying" });
      const verified = await backendRequest<{ upload_id: number; status: string; remote_video_id?: string }>(
        `/api/v1/youtube/local-uploads/${encodeURIComponent(session.upload_id)}/verify`, accessToken,
        { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ remote_video_id: transferred.remote_video_id }) });
      if (!(verified.status === "processing" || ["private_uploaded", "scheduled"].includes(verified.status))) throw new Error(`Backend has not verified the upload (${verified.status}).`);
      save({ remoteVideoId: verified.remote_video_id || transferred.remote_video_id, providerStatus: verified.status, status: verified.status === "processing" ? "processing" : "verified" });
    } catch (error) { save({ status: "error", error: String(error) }); setDirectError(String(error)); }
    finally {
      directInFlight.current = false; setDirectBusy(false);
      void backendRequest<BackendDirectUpload[]>(`/api/v1/youtube/local-uploads?creator_profile_id=${encodeURIComponent(review.profileId)}`, accessToken)
        .then((items) => { if (review.profileId === activeProfileIdRef.current && accessToken === accessTokenRef.current) setBackendDirectUploads(items); })
        .catch(() => {});
    }
    return receipt;
  }
  function prepareDirectPrivateBatch() {
    setDirectError("");
    const target = directYouTubeTargets.find((item) => item.account_ref === directTarget);
    const selected = readyLibraryClips.filter((item) => directBatchIncluded[item.id] !== false);
    if (!accessToken || !target) { setDirectError("Sign in and choose a connected YouTube channel for this creator profile."); return; }
    if (!selected.length || selected.length > 25) { setDirectError("Select 1–25 rendered clips for this private test batch."); return; }
    const reviews = selected.map((item): DirectYouTubeReview => ({
      profileId: activeProfileId, clipId: item.id, localClipId: item.clip.id, outputPath: item.clip.output_path!,
      destinationRef: target.account_ref, destinationName: target.display_name,
      channelId: target.account_ref.slice("youtube:".length),
      title: (item.clip.post_copy?.youtube_title || item.title).replace(/[<>]/g, "").trim().slice(0, 100) || "TV7 clip",
      description: (item.clip.post_copy?.youtube_description || "").slice(0, 5000),
      mode: "private_now", publishAt: null, idempotencyKey: crypto.randomUUID(),
    }));
    setDirectBatchConfirmed(false);
    setDirectBatch({ ownerEmail: signedInEmail, reviews });
  }
  async function approveDirectPrivateBatch() {
    if (!directBatch || !directBatchConfirmed || directBatchInFlight.current || !accessToken || directBatch.ownerEmail !== signedInEmail ||
      directBatch.reviews.some((review) => review.profileId !== activeProfileId || review.destinationRef !== directTarget)) return;
    directBatchInFlight.current = true;
    setDirectBatchBusy(true);
    try {
      for (const review of directBatch.reviews) {
        const receipt = directReceipts.find((item) => item.review.idempotencyKey === review.idempotencyKey);
        if (receipt?.status === "verified" || receipt?.status === "processing") continue;
        await approveDirectYouTubeUpload(review, true);
      }
    } finally {
      directBatchInFlight.current = false;
      setDirectBatchBusy(false);
    }
  }
  async function approveCloudHandoff() {
    if (!renderResult?.media_id || !fileResult || !accessToken) return;
    setHandoffBusy(true);
    setHandoffError("");
    try {
      let uploaded = asset;
      if (!uploaded) {
        const headers = new Headers();
        if (token) headers.set("Authorization", `Bearer ${token}`);
        const response = await fetch(
          `${base}/v1/media/assets/${encodeURIComponent(renderResult.media_id)}`,
          { headers },
        );
        if (!response.ok)
          throw new Error(`Engine export failed: HTTP ${response.status}`);
        if (!response.headers.get("Content-Type")?.startsWith("video/mp4"))
          throw new Error("Engine did not return an MP4 clip.");
        const body = new FormData();
        body.append("file", await response.blob(), "tv7-rendered-clip.mp4");
        uploaded = await backendRequest<BackendAsset>(
          "/api/v1/uploads/assets",
          accessToken,
          { method: "POST", body },
        );
        setAsset(uploaded);
      }
      const video = await backendRequest<CloudVideo>(
        "/api/v1/videos/local",
        accessToken,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            source_url: `local://${fileResult.media_id}`,
            title: fileResult.name,
            original_filename: fileResult.name,
            duration_seconds: Math.ceil(
              fileResult.metadata?.duration_seconds ?? 0,
            ),
            file_size_bytes: fileResult.size_bytes,
          }),
        },
      );
      const existing = video.clips.find(
        (clip) => clip.asset_url === uploaded.asset_url,
      );
      const clip =
        existing ??
        (await backendRequest<CloudClip>(
          `/api/v1/videos/${video.id}/clips`,
          accessToken,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              start_sec: renderResult.start_seconds,
              end_sec: renderResult.end_seconds,
              asset_url: uploaded.asset_url,
              asset_checksum: uploaded.asset_checksum,
              asset_size_bytes: uploaded.asset_size_bytes,
              ready_local_only: false,
              caption_text: renderResult.caption_text,
              status: "ready",
            }),
          },
        ));
      setCloudClip({ id: clip.id, video_id: video.id });
    } catch (error) {
      setHandoffError(String(error));
    } finally {
      setHandoffBusy(false);
    }
  }
  async function createScheduleDraft() {
    if (
      !cloudClip ||
      !asset ||
      !accessToken ||
      !scheduleAt ||
      !publishingTargets.some((target) => target.platform === "youtube_shorts" && target.account_ref === targetAccount)
    )
      return;
    setDraftBusy(true);
    setDraftError("");
    try {
      const scheduled = new Date(scheduleAt);
      if (
        !Number.isFinite(scheduled.getTime()) ||
        scheduled.getTime() <= Date.now()
      )
        throw new Error("Choose a future date and time.");
      const created = await backendRequest<ScheduleDraft>(
        `/api/v1/clips/${cloudClip.id}/schedule-drafts`,
        accessToken,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            platform: "youtube_shorts",
            target_account_ref: targetAccount.trim(),
            creator_profile_id: activeProfileId,
            scheduled_at: scheduled.toISOString(),
            caption: scheduleCaption,
            asset_id: asset.asset_id,
            idempotency_key: crypto.randomUUID(),
          }),
        },
      );
      setDraft(created);
    } catch (error) {
      setDraftError(String(error));
    } finally {
      setDraftBusy(false);
    }
  }
  async function refreshScheduleDraft() {
    if (!cloudClip || !draft || !accessToken) return;
    setDraftBusy(true);
    setDraftError("");
    try {
      const jobs = await backendRequest<ScheduleDraft[]>(
        `/api/v1/clips/${cloudClip.id}/publish`,
        accessToken,
      );
      const current = jobs.find((item) => item.id === draft.id);
      if (current) setDraft(current);
      else throw new Error("Draft was not found for this account.");
    } catch (error) {
      setDraftError(String(error));
    } finally {
      setDraftBusy(false);
    }
  }
  async function ingestSingleUrl() {
    if (!singleUrl.trim()) return;
    setSingleBusy(true);
    setSingleError("");
    setSingleJob(null);
    try {
      const started = await request<{ job: Job }>(
        base,
        token,
        "/v1/ingest/url",
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ url: singleUrl.trim() }),
        },
      );
      setSingleJob(started.job);
    } catch (error) {
      setSingleError(String(error));
    } finally {
      setSingleBusy(false);
    }
  }
  async function discover(cursor?: string) {
    if (!channelUrl.trim()) return;
    setDiscoverBusy(true);
    setDiscoverError("");
    if (!cursor) {
      setDiscovery(null);
      setSelection({});
      setConfirming(false);
    }
    try {
      const next = await request<Discovery>(
        base,
        token,
        "/v1/channels/discover",
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            url: channelUrl.trim(),
            ...(cursor ? { cursor } : {}),
          }),
        },
      );
      setDiscovery((previous) =>
        cursor && previous
          ? { ...next, videos: [...previous.videos, ...next.videos] }
          : next,
      );
    } catch (error) {
      setDiscoverError(String(error));
    } finally {
      setDiscoverBusy(false);
    }
  }
  function toggle(video: Video) {
    setConfirming(false);
    setSelection((previous) => {
      const next = { ...previous };
      if (next[video.id]) delete next[video.id];
      else next[video.id] = video;
      return next;
    });
  }
  async function startBatch() {
    if (!selected.length || selected.length > 25) return;
    setBatchBusy(true);
    setBatchError("");
    try {
      const result = await request<{
        jobs: { video_id: string; job_id: string }[];
      }>(base, token, "/v1/ingest/selected", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          videos: selected.map(({ id, url }) => ({ id, url })),
        }),
      });
      setJobs((current) => [...current,
        ...result.jobs.map((item) => ({
          title:
            selected.find((video) => video.id === item.video_id)?.title ??
            item.video_id,
          url: selected.find((video) => video.id === item.video_id)?.url ?? "",
          jobId: item.job_id,
        })),
      ]);
      setSelection({});
      setConfirming(false);
    } catch (error) {
      setBatchError(String(error));
    } finally {
      setBatchBusy(false);
    }
  }
  const ready = Boolean(base) && health === "ok";
  const libraryGroups = useMemo(() => groupLibrary(library), [library]);
  useEffect(() => {
    if (!libraryGroups.length || !workspaceLoaded) return;
    queueMicrotask(() => setProjectAssignments((current) => {
      const next = { ...current };
      let changed = false;
      for (const group of libraryGroups) {
        if (!next[group.key]) { next[group.key] = "personal"; changed = true; }
      }
      return changed ? next : current;
    }));
  }, [libraryGroups, workspaceLoaded]);
  useEffect(() => {
    queueMicrotask(() => setLibraryDefaults((current) => {
      const next = { ...current };
      let changed = false;
      for (const group of libraryGroups) {
        if (!next[group.key] || !group.copies.some((copy) => copy.media_path === next[group.key])) {
          next[group.key] = group.primary.media_path;
          changed = true;
        }
      }
      return changed ? next : current;
    }));
  }, [libraryGroups]);
  useEffect(() => { window.localStorage.setItem(libraryDefaultsStorageKey, JSON.stringify(libraryDefaults)); }, [libraryDefaults]);
  const profileLibraryGroups = libraryGroups.filter((group) => (projectAssignments[group.key] ?? "personal") === activeProfileId);
  const readyLibraryClips = profileLibraryGroups.flatMap((group) => group.copies.flatMap((video) =>
    uniqueLibraryClips(video.clips).filter((clip) => clip.output_path).map((clip, index) => ({
      id: `${video.media_path}:${clip.id}`, video, clip,
      title: clip.title?.trim() || `${group.title} · clip ${index + 1}`, sourceTitle: group.title,
    }))));
  const directYouTubeTargets = socialConnections.filter((connection) => connection.platform === "youtube" &&
    connection.creator_profile_id === activeProfileId && connection.connected && /^youtube:[A-Za-z0-9_-]+$/.test(connection.account_ref))
    .map((connection) => ({ account_ref: connection.account_ref, display_name: connection.display_name,
      publishing_ready: connection.publishing_ready }));
  const currentDirectReceipt = directReceipts.find((item) => item.review.idempotencyKey === directReview?.idempotencyKey);
  const activeLibraryGroups = profileLibraryGroups.filter((group) => group.clipCount > 0 || group.copies.some((copy) => !isTechnicalTitle(copy.title) || youtubeId(copy)));
  const recoveredLibraryGroups = profileLibraryGroups.filter((group) => !activeLibraryGroups.includes(group));
  async function renameProject(group: LibraryGroup) {
    const title = titleDraft.trim();
    if (!title || isTechnicalTitle(title)) { setLibraryError("Enter a descriptive video title."); return; }
    await saveLibraryVideo({ ...group.primary, title });
    setEditingTitleKey(null);
    setTitleDraft("");
  }
  function smartScheduleClips(selections: { video: LibraryVideo; clip: LibraryVideo["clips"][number] }[], regenerate = false, uploads = backendDirectUploads, scheduledJobs = queue) {
    setLibraryScheduleNotice("");
    if (planBusy || directBatchBusy || approvalInFlight.current) return;
    if (!publishingTargets.length) { setLibraryScheduleNotice("Connect an account in Account before adding clips to the schedule."); return; }
    if (schedulePlan && (schedulePlan.profileId !== activeProfileId || schedulePlan.ownerEmail !== signedInEmail)) {
      setLibraryScheduleNotice("Review the existing plan in Schedule before adding more clips."); return;
    }
    const existing = regenerate ? (schedulePlan?.items.filter(item => item.status !== "pending" || planUpload(item)?.remote_video_id) ?? []) : schedulePlan?.items ?? [];
    const seen = new Set<string>();
    const available = selections.filter(({ video, clip }) => {
      const id = `${video.media_path}:${clip.id}`;
      if (seen.has(id) || existing.some(item => item.jobId === id) || uploads.some(item => item.creator_profile_id === activeProfileId && item.local_clip_id === clip.id && item.status !== "failed") || directReceipts.some(item => item.review.profileId === activeProfileId && item.review.clipId === id && item.status !== "error")) return false;
      seen.add(id);
      return clip.output_path && publishingTargets.every(target => hasPostCopyForPlatform(clip.post_copy, target.platform));
    });
    const eligible = shuffledUniqueClips(available, ({video}) => video.content_hash || video.source_url || video.media_path, ({video,clip}) => `${video.content_hash || video.source_url || video.media_path}:${Number(clip.start).toFixed(2)}:${Number(clip.end).toFixed(2)}:${clip.proposal_source?.startsWith("remix_") ? clip.proposal_source+":"+JSON.stringify(clip.remix_settings??null) : "original"}`);
    if (!eligible.length) { setLibraryScheduleNotice("No new ready clips to add. Clips need a render and post text, and must not already be scheduled."); return; }

    const occupied = existing.map(item => item.scheduledAt).concat(scheduledJobs.filter(item => item.creator_profile_id === activeProfileId && item.status !== "cancelled").flatMap(item => item.scheduled_at ? [item.scheduled_at] : []), uploads.filter(item => item.creator_profile_id === activeProfileId && item.status !== "failed").flatMap(item => item.scheduled_at ? [item.scheduled_at] : []), directReceipts.filter(item => item.review.profileId === activeProfileId && item.status !== "error").flatMap(item => item.review.publishAt ? [item.review.publishAt] : []));
    const slots = nextFreeSlots(new Date(Date.now() + 30 * 60 * 1000), occupied, eligible.length);
    const items: PlanItem[] = eligible.flatMap(({ video, clip }, index) => publishingTargets.map(target => {
      const id = `${video.media_path}:${clip.id}`;
      return { id: `${id}|${target.platform}|${target.account_ref}`, jobId: id, platform: target.platform, target: target.account_ref,
        sourcePath: video.media_path, sourceTitle: displayVideoTitle(video), title: clip.title?.trim() || displayVideoTitle(video),
        render: { output_path: clip.output_path!, duration_seconds: outputFrames(Number(clip.end)-Number(clip.start),clip.remix_settings?.plan)/30, start_seconds: Number(clip.start), end_seconds: Number(clip.end), caption_text: clip.caption_text },
        caption: platformCaption(clip.post_copy!, target.platform), scheduledAt: slots[index]!, idempotencyKey: crypto.randomUUID(), status: "pending" };
    }));
    setScheduleUndo({ previous: schedulePlan, addedIds: items.map(item => item.id), regenerate });
    setSchedulePlan({ ownerEmail: signedInEmail, profileId: activeProfileId, platform: "all", target: "all", items: [...existing, ...items], approvalStarted: schedulePlan?.approvalStarted ?? false });
    setScheduleMonth(monthKey(new Date(slots[0]!)));
    setLibraryScheduleNotice(`${eligible.length} unique clip${eligible.length === 1 ? "" : "s"} mixed into the Medium local plan, starting ${new Date(slots[0]!).toLocaleString()}. Review in Schedule to upload.`);
  }
  async function buildSmartSchedule() {
    if (smartScheduleBusy || planBusy || batchRendering) return;
    setSmartScheduleBusy(true); setLibraryScheduleNotice("Preparing unique clips and post text…");
    const videos = new Map<string, LibraryVideo>();
    const selections = [];
    try {
      if (!accessToken || !publishingTargets.length) throw new Error("Connect an account in Account first.");
      const uploads = await backendRequest<BackendDirectUpload[]>(`/api/v1/youtube/local-uploads?creator_profile_id=${encodeURIComponent(activeProfileId)}`, accessToken);
      const scheduledJobs: QueueJob[] = [];
      for (let offset = 0; ; offset += 100) {
        const page = await backendRequest<QueueJob[]>(`/api/v1/schedule-jobs?limit=100&offset=${offset}&creator_profile_id=${encodeURIComponent(activeProfileId)}`, accessToken);
        scheduledJobs.push(...page); if (page.length < 100) break;
      }
      setBackendDirectUploads(uploads); setQueue(scheduledJobs);
      const uploadedHashes = new Set(uploads.filter(item => item.status !== "failed").map(item => item.checksum_sha256).filter(Boolean));
      for (const candidate of readyLibraryClips) {
        if (uploads.some(item => item.local_clip_id === candidate.clip.id && item.status !== "failed")) continue;
        const registered = await request<{ media_id:string }>(base, token, "/v1/media/register-export", { method:"POST", headers:{"Content-Type":"application/json"}, body:JSON.stringify({output_path:candidate.clip.output_path}) });
        const fingerprint = await request<{checksum_sha256:string}>(base, token, `/v1/media/${encodeURIComponent(registered.media_id)}/transfer-metadata`);
        if (uploadedHashes.has(fingerprint.checksum_sha256)) continue;
        let video = videos.get(candidate.video.media_path) ?? candidate.video;
        let clip = video.clips.find(item => item.id === candidate.clip.id)!;
        if (!publishingTargets.every(target => hasPostCopyForPlatform(clip.post_copy, target.platform))) {
          const draft: ClipDraft = { id:clip.id, title:clip.title, start:clip.start, end:clip.end, start_seconds:Number(clip.start), end_seconds:Number(clip.end), text:clip.text, captionText:clip.caption_text, cue_count:clip.cue_count, burnSubtitles:clip.burn_subtitles, transcriptPath:clip.transcript_path ?? video.transcript_path, originalTranscriptPath:clip.original_transcript_path, wordTranscriptPath:clip.word_transcript_path, postCopy:clip.post_copy ?? undefined };
          setLibraryScheduleNotice(`Writing post text for ${clip.title || displayVideoTitle(video)}…`);
          const copy = await generatePostCopy(draft, video);
          if (!copy) throw new Error("Post text generation failed. Sign in and check AI availability before retrying.");
          clip = {...clip, post_copy:copy, title:!clip.title || /^Clip \d+$/i.test(clip.title) ? copy.youtube_title : clip.title};
          video = {...video, clips:video.clips.map(item => item.id === clip.id ? clip : item)};
          await saveLibraryVideo(video);
        }
        videos.set(video.media_path,video); selections.push({video,clip});
      }
      smartScheduleClips(selections,true,uploads,scheduledJobs);
    } catch(error) {setLibraryScheduleNotice(`Smart schedule needs attention: ${String(error)}`);}
    finally {setSmartScheduleBusy(false);}
  }
  async function clearLibraryClips(restore=false) {
    if(libraryArtBusy||creationLock.current)return;
    cancelBackgroundChannelWork();setLibraryArtBusy(true);creationLock.current=true;
    try{
      const fresh=await request<LibraryVideo[]>(base,token,"/v1/library/videos");
      if(!restore){localStorage.setItem("tv7-clips-recovery-v1",JSON.stringify(fresh));setClipRecovery(fresh);}
      for(const video of fresh){
        const recovered=restore?clipRecovery?.find(v=>v.media_path===video.media_path):undefined;
        await request(base,token,"/v1/library/videos",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({...video,clips:restore?(recovered?.clips??video.clips):[]})});
      }
      mediaVersion.current++;setFileResult(null);setClipDrafts([]);setBatchVideos({});setSelectedClipId(null);
      if(!restore){setSchedulePlan(null);setDirectBatch(null);setDirectReview(null);setScheduleUndo(null);}
      await refreshLibrary();setLibraryArtStatus(restore?"Clip snapshot restored.":"All local clip entries cleared. Sources and exported files retained; Undo clear restores the snapshot.");return true;
    }catch(e){setLibraryArtStatus(`Clear needs attention: ${String(e)}. Recovery snapshot retained.`);return false;}
    finally{setLibraryArtBusy(false);creationLock.current=false;}
  }
  async function shuffleAllLibrary(resume=false){
    if(libraryArtBusy||creationLock.current||batchRendering)return;
    cancelBackgroundChannelWork();setLibraryArtBusy(true);creationLock.current=true;setBatchRendering(true);libraryArtStop.current=false;
    setLibraryArtStarted(Date.now());setLibraryArtElapsed(0);setLibraryError("");setLibraryArtErrors({});
    mediaVersion.current++;setFileResult(null);setClipDrafts([]);setBatchVideos({});
    const offset=Math.floor(Math.random()*5);let ordinal=0,rendered=0,reused=0,skipped=0;const errors:string[]=[];
    const phase=(message:string)=>{setLibraryArtStatus(message);setLibraryRenderProgress(null);setLibraryArtStarted(Date.now());setLibraryArtElapsed(0);};
    try{
      const fresh=await request<LibraryVideo[]>(base,token,"/v1/library/videos");
      const groups=groupLibrary(fresh).filter(g=>(projectAssignments[g.key]??"personal")===activeProfileId&&(!sampleSource||g.primary.media_path===sampleSource));
      for(let n=0;n<groups.length;n++){
        if(libraryArtStop.current)break;
        const group=groups[n]!;let video=group.primary;
        try{
          phase(`Video ${n+1}/${groups.length}: checking ${group.title}…`);
          const probe=await request<{metadata:{duration_seconds?:number}}>(base,token,"/v1/media/probe",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({path:video.media_path})});
          const duration=probe.metadata.duration_seconds;
          if(!duration||duration<=3){const reason=`Too short for speech clips (${duration??0}s).`;skipped++;setLibraryArtErrors(current=>({...current,[group.key]:reason}));continue;}
          let path=video.transcript_path;
          if(path){try{await request(base,token,`/v1/transcripts/cues?path=${encodeURIComponent(path)}`);}catch{path=null;}}
          phase(`Video ${n+1}/${groups.length}: preparing transcript for ${group.title}…`);
          path=path??await acquireTranscript(video.media_path,video.source_url??undefined);
          const wordPath=await ensureWordTiming(video.media_path,video.clips.find(c=>c.word_transcript_path)?.word_transcript_path??clipRecovery?.find(v=>v.media_path===video.media_path)?.clips.find(c=>c.word_transcript_path)?.word_transcript_path);
          let drafts:ClipDraft[]=uniqueLibraryClips(video.clips).map(c=>({id:c.id,title:c.title,start:c.start,end:c.end,start_seconds:Number(c.start),end_seconds:Number(c.end),text:c.text,captionText:c.caption_text,cue_count:c.cue_count,burnSubtitles:true,postCopy:c.post_copy??undefined,proposalSource:c.proposal_source as ClipDraft["proposalSource"],remixSettings:c.remix_settings,...(c.output_path?{result:{output_path:c.output_path,duration_seconds:outputFrames(Number(c.end)-Number(c.start),c.remix_settings?.plan)/30,start_seconds:Number(c.start),end_seconds:Number(c.end),caption_text:c.caption_text}}:{})}));
          if(!drafts.length){
            const maxClips=sampleSource?3:activeProfile.defaultClipCount;
            if(accessToken){
              try{
                phase(`Video ${n+1}/${groups.length}: selecting best clips with AI for ${group.title}…`);
                const [ranked,cues]=await Promise.all([rankTranscript(path,maxClips,true),request<{cues:{start_seconds:number;end_seconds:number;text:string}[]}>(base,token,`/v1/transcripts/cues?path=${encodeURIComponent(path)}`)]);
                drafts=ranked.clips.slice(0,maxClips).map(s=>{const span=cues.cues.filter(c=>c.end_seconds>s.start_seconds&&c.start_seconds<s.end_seconds);const text=span.map(c=>c.text).join(" ").trim()||s.reason;return {id:crypto.randomUUID(),title:s.title,start:s.start_seconds.toFixed(2),end:s.end_seconds.toFixed(2),start_seconds:s.start_seconds,end_seconds:s.end_seconds,text,captionText:text,cue_count:Math.max(1,span.length),burnSubtitles:true,proposalSource:"ai" as const};});
              }catch{drafts=[];}
            }
            if(!drafts.length){
              const found=await request<{candidates:Candidate[]}>(base,token,"/v1/transcripts/candidates",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({transcript_path:path,max_candidates:maxClips,max_duration_seconds:45})});
              drafts=found.candidates.map(c=>({...c,id:crypto.randomUUID(),start:c.start_seconds.toFixed(2),end:c.end_seconds.toFixed(2),captionText:c.text,burnSubtitles:true}));
            }
          }
          if(!drafts.length)throw new Error("No speech ranges found.");
          drafts=drafts.map(c=>{const generated=shuffledRecipe(ordinal++,offset);const keep=resume&&c.proposalSource?.startsWith("remix_")&&c.remixSettings;const settings=keep?c.remixSettings!:generated;return {...c,result:keep?c.result:undefined,remixSettings:settings,proposalSource:`remix_${settings.treatment}`,subtitleStyle:normalizeSubtitleStyle({...defaultSubtitleStyle,...activeProfile.subtitleStyle,preset:"word_box"}),wordTranscriptPath:wordPath,transcriptPath:path,originalTranscriptPath:path,format:"vertical_9_16_blur"};});
          for(const clip of drafts){if(clip.result){try{await request(base,token,"/v1/media/probe",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({path:clip.result.output_path})});}catch{clip.result=undefined;}}}
          video={...video,duration_seconds:duration,transcript_path:path,clips:catalogClips(drafts)};await saveLibraryVideo(video);
          for(let i=0;i<drafts.length;i++){
            if(libraryArtStop.current)break;
            const clip=drafts[i]!;
            try{
              if(!clip.result){
                if(accessToken&&!clip.remixSettings?.plan){phase(`Directing ${group.title} · clip ${i+1}/${drafts.length} with AI…`);try{clip.remixSettings=await directClip(clip,video);video={...video,clips:catalogClips(drafts)};await saveLibraryVideo(video);}catch(e){setLibraryArtErrors(current=>({...current,[clip.id]:`AI director fallback: ${String(e)}`}));}}
                phase(`Video ${n+1}/${groups.length}: rendering ${group.title} · clip ${i+1}/${drafts.length} · ${clip.remixSettings?.artPack}. This renders locally; long clips may take several minutes.`);
                clip.result=await renderClip(clip,{mediaPath:video.media_path,duration,transcriptPath:path});rendered++;
              }else reused++;
              phase(`Video ${n+1}/${groups.length}: writing post text · ${group.title} · clip ${i+1}/${drafts.length}…`);
              if(!clip.postCopy?.youtube_description){const copy=await generatePostCopy(clip,video);if(copy){clip.postCopy=copy;clip.title=copy.youtube_title;}else{errors.push(`${group.title}, clip ${i+1}: post text needs attention.`);setLibraryArtErrors(current=>({...current,[clip.id]:"Video rendered; post text generation failed. Generate post copy in the editor."}));}}
              video={...video,clips:catalogClips(drafts)};await saveLibraryVideo(video);
            }catch(e){const message=String(e);errors.push(`${group.title}, clip ${i+1}: ${message}`);setLibraryArtErrors(current=>({...current,[clip.id]:message}));}
          }
        }catch(e){errors.push(`${group.title}: ${String(e)}`);setLibraryArtErrors(current=>({...current,[group.key]:String(e)}));}
      }
      phase(`${libraryArtStop.current?"Shuffle stopped after the current clip":"Shuffle finished"}: ${rendered} rendered, ${reused} existing renders retained. Word box on every prepared clip.${skipped?` ${skipped} short sources skipped.`:""}${errors.length?` ${errors.length} items need attention: Details are shown on the source and clip cards. Resume shuffle retries missing outputs.`:" All sources completed; review before scheduling."}`);
    }catch(e){phase(`Shuffle interrupted: ${String(e)}. Saved clips are retained. Use Resume shuffle.`);}
    finally{setLibraryArtBusy(false);setBatchRendering(false);creationLock.current=false;await refreshLibrary();}
  }
  async function clearEverySchedule() {
    if (smartScheduleBusy || !accessToken) return;
    setSmartScheduleBusy(true); setLibraryScheduleNotice("");
    try {
      const result = await backendRequest<{ cleared_upload_ids: number[]; cancelled_job_ids: number[]; errors: {message:string}[] }>("/api/v1/youtube/local-uploads/clear-schedule", accessToken, { method: "POST", headers: {"Content-Type":"application/json"}, body: JSON.stringify({creator_profile_id:activeProfileId}) });
      setBackendDirectUploads(current => current.map(item => result.cleared_upload_ids.includes(item.upload_id) ? {...item, scheduled_at:null, status:"private_uploaded"} : item));
      setDirectReceipts(current => current.map(item => item.uploadId && result.cleared_upload_ids.includes(item.uploadId) ? {...item, providerStatus:"private_uploaded", review:{...item.review, mode:"private_now", publishAt:null}} : item));
      setQueue(current => current.map(item => result.cancelled_job_ids.includes(item.id) ? {...item,status:"cancelled"} : item));
      if (result.errors.length) { setClearSchedulePrompt(false); setLibraryScheduleNotice(`Schedule partially cleared. ${result.errors.length} releases or Backend jobs could not be confirmed; retry Clear schedule. Local plan retained for recovery.`); return; }
      setSchedulePlan(current => current?.profileId === activeProfileId ? null : current);
      setDirectBatch(current => current ? {...current, reviews:current.reviews.filter(item => item.profileId !== activeProfileId)} : null);
      if (directReview?.profileId === activeProfileId) setDirectReview(null);
      setScheduleUndo(null); setClearSchedulePrompt(false);
      setLibraryScheduleNotice(`Schedule cleared for ${activeProfile.name}: local plan removed, ${result.cancelled_job_ids.length} Backend drafts cancelled, ${result.cleared_upload_ids.length} future YouTube releases cancelled. Uploaded videos are retained.`);
    } catch(error) { setLibraryScheduleNotice(`Clear schedule failed: ${String(error)}. Local plan retained for recovery.`); }
    finally {setSmartScheduleBusy(false);}
  }
  const renderLibraryGroup = (group: LibraryGroup) => {
    const master = group.copies.find((copy) => copy.media_path === libraryDefaults[group.key]) ?? group.primary;
    const seen = new Set<string>();
    const clips = group.copies.flatMap((video) => uniqueLibraryClips(video.clips).map((clip) => ({ video, clip })))
      .filter(({ clip }) => { const key = clipEditKey(clip); if (seen.has(key) && !clip.output_path) return false; seen.add(key); return true; });
    return <article className="project-card" key={group.key}>
      {libraryArtErrors[group.key]&&<p className={libraryArtErrors[group.key].startsWith("Too short")?"note":"error"}>{libraryArtErrors[group.key]}</p>}
      <div className="project-card-heading">
        <button type="button" className="project-open" onClick={() => void openLibraryVideo(master)} disabled={fileBusy||libraryArtBusy}>
          <strong>{group.title}</strong>
          <span>{master.duration_seconds != null ? `${Math.round(master.duration_seconds)}s` : "Duration unavailable"} · {master.size_bytes != null ? formatSize(master.size_bytes) : "Size unavailable"}</span>
          <small>{clips.length} {clips.length === 1 ? "clip" : "clips"}</small>
        </button>
        <button type="button" className="icon-button" disabled={fileBusy || batchRendering || !ready} aria-label={`${clips.length ? "Regenerate" : "Create"} clips for ${group.title}`} title={clips.length ? "Regenerate full clips" : "Create full clips"} onClick={() => {
          setQueuedCreatePath(master.media_path); void openLibraryVideo(master);
        }}><LibraryIcon kind="regenerate" /></button>
        <button type="button" className="icon-button" onClick={() => smartScheduleClips(clips)} disabled={planBusy || batchRendering || !clips.some(({clip}) => clip.output_path)} aria-label={`Add ready clips from ${group.title} to schedule`} title="Add ready clips to next free schedule slots"><LibraryIcon kind="calendar" /></button>
        <button type="button" className="icon-button" onClick={() => { setEditingTitleKey(group.key); setTitleDraft(group.title === "Needs title" ? "" : group.title); }} aria-label={`Edit title for ${group.title}`} title="Edit video title"><LibraryIcon kind="edit" /></button>
      </div>
      {editingTitleKey === group.key && <form className="project-rename" onSubmit={(event) => { event.preventDefault(); void renameProject(group).catch((error) => setLibraryError(String(error))); }}>
        <label>Video title<input autoFocus value={titleDraft} onChange={(event) => setTitleDraft(event.target.value)} placeholder="Enter the source video title" /></label>
        <button className="primary">Save title</button><button type="button" className="secondary" onClick={() => setEditingTitleKey(null)}>Cancel</button>
      </form>}
      <div className="project-clips" aria-label={`${group.title} clips`}>
        {clips.length === 0 ? <p className="note">Create clips to get started.</p> : clips.map(({ video, clip }, index) => {
          const id = `${video.media_path}:${clip.id}`;
          const planned = schedulePlan?.profileId === activeProfileId ? schedulePlan.items.find(item => item.jobId === id) : undefined;
          const uploaded = backendDirectUploads.find(item => item.creator_profile_id === activeProfileId && item.local_clip_id === clip.id && item.remote_video_id);
          return <div className="library-clip-card" key={id}>
            <button type="button" className="library-clip-open" onClick={() => void openLibraryVideo(video, clip.id)} disabled={fileBusy||libraryArtBusy}>
              <strong>{clip.title?.trim() || `Clip ${index + 1}`}</strong><small>{clip.start}–{clip.end}s</small>
            </button>
            <div className="library-clip-actions"><span className="clip-status-icon" role="img" aria-label={clip.output_path ? "Clip ready" : "Draft clip"} title={clip.output_path ? "Clip ready" : "Draft clip"}><LibraryIcon kind={clip.output_path ? "ready" : "draft"} /></span>
              <button className="icon-button" type="button" disabled={planBusy || batchRendering || !clip.output_path || Boolean(planned) || Boolean(uploaded)} onClick={() => smartScheduleClips([{video, clip}])} aria-label={uploaded ? `${clip.title || `Clip ${index + 1}`} is already uploaded` : planned ? `${clip.title || `Clip ${index + 1}`} is in schedule` : `Add ${clip.title || `Clip ${index + 1}`} to schedule`} title={uploaded ? "Already uploaded; excluded from Smart schedule" : planned ? "Already in schedule" : !clip.output_path ? "Create this clip before scheduling" : "Add to next free schedule slot"}><LibraryIcon kind="calendar" /></button>
            </div>
            {libraryArtErrors[clip.id]&&<small className="error">{shuffleErrorSummary(libraryArtErrors[clip.id]!)}</small>}{planned && <small className="clip-plan-date">{planned.status === "draft_ready" ? "Scheduled" : "Local plan"} · {new Date(planned.scheduledAt).toLocaleString([], { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })}</small>}
          </div>;
        })}
      </div>
      {profiles.length > 1 && <label className="project-profile">Creator profile <select disabled={!workspaceLoaded||libraryArtBusy} value={projectAssignments[group.key] ?? "personal"}
        onChange={(event) => setProjectAssignments((current) => ({ ...current, [group.key]: event.target.value }))}>
        {profiles.map((profile) => <option key={profile.id} value={profile.id}>{profile.name}</option>)}
      </select></label>}
    </article>;
  };
  const channelToolsReady = diagnostics?.capabilities?.some(
    (capability) => capability.name === "url_ingest" && capability.status === "ready",
  ) ?? false;
  const missingChannelTools = diagnostics?.tools?.filter(
    (tool) => tool.required_for?.includes("url_ingest") && tool.available !== true,
  ) ?? [];
  return (
    <div className="shell">
      <header className="topbar">
        <div className="brand">
          <b>
            TV<span>7</span>
          </b>
          <small>TV7 STUDIO</small>
        </div>
        <div className="topbar-actions">
          <label className="topbar-profile">Creator profile <select disabled={!workspaceLoaded || smartScheduleBusy || libraryArtBusy || batchRendering} aria-label="Active creator profile" value={activeProfileId} onChange={(event) => { const selected = profiles.find((profile) => profile.id === event.target.value); setActiveProfileId(event.target.value); if (selected) { setChannelUrl(selected.channelUrl); setClipCount(selected.defaultClipCount); setPlanSpacing(selected.daysBetweenPosts); } setPage("library"); }}>
            {profiles.map((profile) => <option key={profile.id} value={profile.id}>{profile.name}</option>)}
          </select></label>
          <div role="status" className={"connection " + (ready ? "ready" : "")}>
            ● Engine {ready ? "connected" : "unavailable"}
          </div>
        </div>
      </header>
      <div className="layout">
        <nav className="sidebar" aria-label="Studio sections">
          <span className="kicker">WORKSPACE</span>
          <button
            className={page === "overview" ? "active" : ""}
            onClick={() => setPage("overview")}
          >
            Overview
          </button>
          <button className={page === "ingest" ? "active" : ""} onClick={() => { setPage("ingest"); setChannelUrl(activeProfile.channelUrl); }}>Ingest</button>
          <button className={page === "library" ? "active" : ""} onClick={() => setPage("library")}>Library</button>
          {fileResult && <button className={page === "editor" ? "active" : ""} onClick={() => setPage("editor")}>Clip editor</button>}
          <button className={page === "schedule" ? "active" : ""} onClick={() => setPage("schedule")}>Schedule</button>
          <button className={page === "profile" ? "active" : ""} onClick={() => setPage("profile")}>Account</button>
          <p>
            Media work runs on this computer. Schedule drafts use TV7 Backend.
          </p>
        </nav>
        <main className={page === "editor" ? "studio-edit-main" : ""}>
          {page === "overview" && (
            <>
              <span className="kicker">LOCAL WORKSPACE</span>
              <h1>Your channel. Your clip library.</h1>
              <p className="lead">
                Import your videos, review local clip renders, and prepare a posting schedule from one creator profile.
              </p>
              <div className="actions">
                <button onClick={() => setPage("ingest")}>
                  <span className="glyph">↗</span>
                  <strong>Open a local video</strong>
                  <span>Select a file and hand it to Engine.</span>
                  <em>Get started →</em>
                </button>
                <button onClick={() => setPage("ingest")}>
                  <span className="glyph">▦</span>
                  <strong>Explore a channel</strong>
                  <span>Review discovered videos before download.</span>
                  <em>Discover videos →</em>
                </button>
              </div>
              <section className="panel">
                <div className="heading">
                  <div>
                    <span className="kicker">SYSTEM</span>
                    <h2>Engine connection</h2>
                  </div>
                  <button className="secondary" onClick={() => void refresh()}>
                    Refresh status
                  </button>
                </div>
                <code>{base || "Starting packaged Engine…"}</code>
                {engineStartError && (
                  <p role="alert" className="error">
                    {engineStartError}
                  </p>
                )}
                {healthError ? (
                  <p role="alert" className="error">
                    {healthError}
                  </p>
                ) : (
                  <>
                    <p className="success">
                      Health: {health ?? "checking"} · Diagnostics:{" "}
                      {diagnostics?.status ?? "checking"}
                    </p>
                    <div className="capabilities">
                      {diagnostics?.capabilities?.map((item) => (
                        <span key={item.name}>
                          {item.name}: {item.status}
                        </span>
                      ))}
                    </div>
                  </>
                )}
              </section>
            </>
          )}
          {page === "library" && <>
            <span className="kicker">LOCAL WORKSPACE</span><h1>Projects</h1>
            <p className="lead">Choose a video or clip to edit, create clips, or add ready clips to your schedule.</p>
            <section className="panel local-library" aria-label="Video projects">
              <div className="library-heading"><div><h2>{sampleSource?"Sample video":"Videos"} <span>{sampleSource?1:profileLibraryGroups.length}</span></h2><p className="note">Media and rendered clips stay on this computer.</p></div><button className="secondary" onClick={() => void refreshLibrary()} disabled={libraryBusy}>{libraryBusy ? "Refreshing…" : "Refresh"}</button></div>
              {libraryError && <p role="alert" className="error">{libraryError}</p>}
              {profileLibraryGroups.length === 0 && !libraryBusy && <p className="note">No videos in this profile. <button className="secondary" onClick={() => setPage("ingest")}>Import a video</button></p>}
              <section className="sample-lab"><h3>One-video remix lab</h3><p>Focus on one source. Rebuild clears all local clip entries with Undo recovery, then directs and renders fresh sample clips. Source files are retained.</p><label>Sample video<select aria-label="Remix sample video" disabled={libraryArtBusy||batchRendering} value={sampleSource} onChange={e=>setSampleSource(e.target.value)}><option value="">Full Library</option>{profileLibraryGroups.map(g=><option key={g.key} value={g.primary.media_path}>{g.title}</option>)}</select></label>{sampleSource&&<button className="primary" disabled={libraryArtBusy||batchRendering||!accessToken||!ready} onClick={async()=>{if(await clearLibraryClips())await shuffleAllLibrary();}}>Rebuild sample with AI</button>}</section>
              <div className="library-schedule-toolbar"><button className="primary" disabled={libraryArtBusy||batchRendering||!ready} onClick={()=>void shuffleAllLibrary()}>{libraryArtBusy?"Working…":sampleSource?"Remix sample":"Shuffle all"}</button><button className="secondary" disabled={libraryArtBusy||batchRendering||!ready} onClick={()=>void shuffleAllLibrary(true)}>Resume shuffle</button>{libraryArtBusy&&<button className="secondary" onClick={()=>{libraryArtStop.current=true;setLibraryArtStatus(current=>current+" Stop requested; finishing current clip.");}}>Stop after clip</button>}<button className="secondary" disabled={libraryArtBusy||batchRendering} onClick={()=>void clearLibraryClips()}>Clear clips</button>{clipRecovery&&<button className="secondary" disabled={libraryArtBusy||batchRendering} onClick={()=>void clearLibraryClips(true)}>Undo clear</button>}<span>Medium · 2 posts daily · 12:00 / 19:00</span><button className="primary" disabled={smartScheduleBusy || batchRendering || !readyLibraryClips.length} onClick={() => void buildSmartSchedule()}>{smartScheduleBusy ? "Preparing…" : "Smart schedule"}</button><button className="secondary" disabled={smartScheduleBusy || batchRendering || !readyLibraryClips.length} onClick={() => void buildSmartSchedule()}>Regenerate schedule</button><button className="secondary" disabled={smartScheduleBusy || planBusy || !accessToken} onClick={() => setClearSchedulePrompt(true)}>Clear schedule</button></div>
              {libraryArtStatus&&<p role="status">{libraryArtStatus}{libraryArtBusy?` · ${libraryArtElapsed}s in this step${libraryRenderProgress!==null?` · ${libraryRenderProgress}% rendered`:""}`:""}</p>}
              {clearSchedulePrompt && <section className="library-schedule-notice" role="alertdialog" aria-label="Clear schedule confirmation"><p>Cancel all future releases for {activeProfile.name} in this app, Backend and connected accounts? Uploaded videos stay available; published posts remain live.</p><button className="primary" disabled={smartScheduleBusy} onClick={() => void clearEverySchedule()}>{smartScheduleBusy ? "Clearing…" : "Clear all future releases"}</button><button className="secondary" disabled={smartScheduleBusy} onClick={() => setClearSchedulePrompt(false)}>Keep schedule</button></section>}
              {libraryScheduleNotice && <div className="library-schedule-notice" role="status">{libraryScheduleNotice} {scheduleUndo && !planBusy && <button className="secondary" onClick={() => { if (scheduleUndo.addedIds.some(id => schedulePlan?.items.find(item => item.id === id)?.status !== "pending")) return; setSchedulePlan(current => { if (!current || current.profileId !== activeProfileId) return current; if (scheduleUndo.regenerate) return scheduleUndo.previous; const items = current.items.filter(item => !scheduleUndo.addedIds.includes(item.id)); return items.length ? { ...current, items } : scheduleUndo.previous; }); setScheduleUndo(null); setLibraryScheduleNotice("Removed the last addition from the local plan."); }}>Undo</button>} <button className="secondary" onClick={() => setPage("schedule")}>View schedule</button></div>}
              <div className="library-list">{activeLibraryGroups.filter(g=>!sampleSource||g.primary.media_path===sampleSource).map(renderLibraryGroup)}</div>
            </section>
          </>}
          {(page === "ingest" || page === "editor" || page === "schedule") && <>
            {page === "ingest" && <><span className="kicker">INGEST</span><h1>Bring in media</h1><p className="lead">Choose a local file, import one URL, or discover videos from {activeProfile.name}’s channel.</p></>}
            {page === "editor" && <div className="workspace-title"><button className="secondary" onClick={() => void closeLibraryVideo()}>← Projects</button><h1>Clip editor</h1><span title={fileResult?.name}>{fileResult?.name ?? "Choose a project"}</span></div>}
            {page === "schedule" && <><span className="kicker">RELEASE QUEUE</span><h1>Schedule</h1><p className="lead">Review rendered clips and prepare posting drafts for {activeProfile.name}.</p>
          </>}
            {page === "ingest" &&               <section className="panel">
                <details className="file-chooser" open>
                  <summary>{fileResult ? "Choose a different video file" : "Choose a video file"}</summary>
                <label className="file-zone">
                  <span className="glyph">↑</span>
                  <strong>
                    {fileBusy
                      ? "Handing file to Engine…"
                      : "Choose a video file"}
                  </strong>
                  <span>Maximum 1 GiB</span>
                  <input
                    type="file"
                    accept="video/*"
                    disabled={fileBusy || !ready}
                    onChange={(event) => {
                      const file = event.target.files?.[0];
                      if (file) void upload(file);
                      event.currentTarget.value = "";
                    }}
                  />
                </label>
                </details>
                {fileError && (
                  <p role="alert" className="error">
                    {fileError}
                  </p>
                )}
                {fileResult && (
                  <div role="status" className="result">
                    <strong>{fileResult.name} is ready in Engine</strong>
                    {fileResult.size_bytes != null && (
                      <span>{formatSize(fileResult.size_bytes)}</span>
                    )}
                    {fileResult.metadata && (
                      <span>
                        {fileResult.metadata.format} ·{" "}
                        {fileResult.metadata.duration_seconds?.toFixed(1) ??
                          "unknown"}{" "}
                        seconds · {fileResult.metadata.width ?? "?"} ×{" "}
                        {fileResult.metadata.height ?? "?"}
                      </span>
                    )}
                    {fileResult.probeError && (
                      <span>Probe unavailable: {fileResult.probeError}</span>
                    )}
                    <details>
                      <summary>Technical details</summary>
                      <code>{fileResult.media_path}</code>
                    </details>
                  </div>
                )}
              </section>}
              {page === "editor" && fileResult && <section className="panel workspace-panel" id="clip-workspace">
                <div className="creation-toolbar"><div><h2>{clipDrafts.length ? "Your clips" : "Create clips from this video"}</h2><p className="note">One action finds ranges, burns subtitles, renders videos and writes post text. Regenerating replaces this project’s current clip selection.</p></div>
                  <div className="creation-actions"><label>Up to<input aria-label="Maximum clips" type="number" min="1" max="12" value={clipCount} disabled={batchRendering} onChange={event => setClipCount(Math.max(1, Math.min(12, Number(event.target.value) || 1)))} /></label>
                  <button type="button" className="primary" disabled={batchRendering || transcriptBusy || !ready} onClick={() => void createFullClips()}>{batchRendering ? "Creating clips…" : clipDrafts.length ? "Regenerate clips" : "Create clips"}</button>
                  <button type="button" className="secondary" disabled={batchRendering || !clipDrafts.length} onClick={shuffleClipColors}>Shuffle colors</button></div></div>
                {creationStatus && <p role="status" className="note">{creationStatus}</p>}
                {creationError && <p role="alert" className="error">{creationError}</p>}
                <div className="heading"><h3>Timeline</h3>
                  <span className="count">{clipDrafts.length} clips · {clipDrafts.filter((clip) => clip.result).length} ready</span></div>
                <details className="workspace-tools"><summary>Advanced tools · transcript and clip ranges</summary>
                <p className="note">
                  Studio automatically looks for source captions, then asks Engine
                  to transcribe locally. The proposed ranges are timing candidates,
                  not quality scores. Edit each clip before rendering.
                </p>
                <label htmlFor="transcript-file">Import a WebVTT transcript instead</label>
                <input
                  id="transcript-file"
                  type="file"
                  accept=".vtt,text/vtt"
                  disabled={!ready || transcriptBusy || !fileResult}
                  onChange={(event) => {
                    const file = event.target.files?.[0];
                    if (file) void importTranscript(file);
                    event.currentTarget.value = "";
                  }}
                />
                {!fileResult && (
                  <p className="note">Import a local video first.</p>
                )}
                {transcriptBusy && <p role="status">Acquiring transcript and proposing clips…</p>}
                {transcriptError && (
                  <p role="alert" className="error">
                    {transcriptError}
                  </p>
                )}
                {transcript && (
                  <p className="success" role="status">
                    Transcript ready: {transcript.name}
                  </p>
                )}
                {fileResult && !transcriptBusy && !transcript && transcriptError && (
                  <p className="note">Automatic transcription requires Engine's local runtime and model. You can import a WebVTT file above, or render a clip manually without subtitles below.</p>
                )}
                <label htmlFor="clip-count">Proposed clip count (1–12)</label>
                <input id="clip-count" type="number" min="1" max="12" value={clipCount}
                  onChange={(event) => setClipCount(Math.max(1, Math.min(12, Number(event.target.value) || 1)))} />
                {transcript && <button type="button" className="secondary" disabled={transcriptBusy}
                  onClick={() => void proposeClips(transcript.transcript_path, clipCount, mediaVersion.current).catch((error: unknown) => setTranscriptError(String(error)))}>
                  Refresh proposals
                </button>}
                {transcript && <details className="optional-tools"><summary>Optional AI clip suggestions</summary><div className="clip-editor">
                  <p className="note">With your consent, timed transcript text leaves this device through Engine and TV7 Backend for DeepSeek analysis. Video pixels stay local. Backend credits may be charged per provider call; long transcripts may need several calls. Scores are review suggestions, not view predictions or viral guarantees. Local timing candidates stay available.</p>
                  <button type="button" className="secondary" onClick={() => void estimateAiCalls(transcript.transcript_path)}>Estimate cloud AI calls</button>
                  {aiCueEstimates[transcript.transcript_path]?.count > 0 && <p className="note">{aiCueEstimates[transcript.transcript_path].count} timed cues · at least {Math.ceil(aiCueEstimates[transcript.transcript_path].count / 400)} provider call(s). The 24,000-character cap can increase that count and credit use.</p>}
                  {aiCueEstimates[transcript.transcript_path]?.error && <p role="alert" className="error">{aiCueEstimates[transcript.transcript_path].error}</p>}
                  <label className="checkbox"><input type="checkbox" checked={aiConsent}
                    onChange={(event) => setAiConsent(event.target.checked)} /> I agree to send this transcript to TV7 cloud AI for this request</label>
                  {!accessToken && <form onSubmit={(event) => { event.preventDefault(); void signIn(); }}>
                    <label>TV7 account email<input type="email" required value={accountEmail} onChange={(event) => setAccountEmail(event.target.value)} /></label>
                    <label>Password<input type="password" required value={accountPassword} onChange={(event) => setAccountPassword(event.target.value)} /></label>
                    <button className="secondary" disabled={loginBusy}>{loginBusy ? "Signing in…" : "Sign in for optional AI"}</button>
                  </form>}
                  {accessToken && <p className="note">Cloud AI: {license?.reason_code ?? "checking readiness"} · credits remaining: {license?.cloud_ai_credits_remaining ?? "unknown"}</p>}
                  {accessToken && license?.cloud_ai_available === false && <p className="note">TV7 cloud AI is unavailable for this account ({license.reason_code ?? "not ready"}). Local timing candidates and rendering still work.</p>}
                  {accessToken && <button type="button" className="secondary" onClick={() => void refreshAiReadiness()}>Refresh AI readiness</button>}
                  <button type="button" className="secondary" disabled={!aiConsent || !accessToken || aiBusy || license?.cloud_ai_available === false}
                    onClick={() => void rankLocalTranscript()}>{aiBusy ? "Requesting suggestions…" : "Request AI suggestions"}</button>
                  {localAiError && <p role="alert" className="error">{localAiError}</p>}
                  {localAiModel && <p className="note">Suggestions from {localAiModel}.</p>}
                  {localAiSuggestions.length > 0 && <p className="note">Add a suggestion to keep current drafts, or replace the visible draft cards. Existing saved Backend drafts are unaffected.</p>}
                  {aiUsage?.credits_charged != null && <p className="note">Last AI request charged {aiUsage.credits_charged} credit(s); {aiUsage.credits_remaining ?? "unknown"} remain.</p>}
                  {localAiSuggestions.map((suggestion, index) => <div className="candidate-row" key={`${suggestion.start_seconds}-${index}`}>
                    <strong>{suggestion.title} · {suggestion.start_seconds.toFixed(1)}–{suggestion.end_seconds.toFixed(1)} s</strong>
                    <span>{suggestion.reason}</span><small>AI suggestion score: {suggestion.score.toFixed(2)}</small>
                    <button type="button" className="secondary" disabled={clipDrafts.length >= 12} onClick={() => addLocalSuggestion(suggestion)}>Add alongside local drafts</button>
                    <button type="button" className="secondary" onClick={() => replaceLocalWithSuggestion(suggestion)}>Replace visible drafts with this</button>
                  </div>)}
                </div></details>}
                {transcript && candidates.length === 0 && (
                  <p className="note">
                    No candidate ranges found in this transcript.
                  </p>
                )}
                </details>
                <div className="workspace-columns">
                  <div className="workspace-stage">
                    <div className="stage-heading"><strong>Source video</strong><span>{fileResult?.metadata?.duration_seconds?.toFixed(1) ?? "—"}s total</span></div>
                    {fileResult && (sourceDisplayUrl ? <div className={`subtitle-preview-frame ${activeClip?.format !== "source" ? "vertical" : ""} ${activeClip?.format === "vertical_9_16_crop" ? "cropped" : ""}`}>
                      {activeClip?.format === "vertical_9_16_blur" && <video ref={blurPlayer} muted playsInline src={sourceDisplayUrl} className="blur-preview" aria-hidden="true" tabIndex={-1} />}
                      <video ref={sourcePlayer} controls src={sourceDisplayUrl} onPlay={() => { if (blurPlayer.current && sourcePlayer.current) { blurPlayer.current.currentTime = sourcePlayer.current.currentTime; void blurPlayer.current.play().catch(() => {}); } }} onPause={() => blurPlayer.current?.pause()}
                      onLoadedMetadata={(event) => { if (activeClip && fileResult) { event.currentTarget.currentTime = Number(activeClip.start) || 0; setPlayhead(Number(activeClip.start) || 0); autoSeekedClip.current = `${fileResult.media_path}:${activeClip.id}`; } }}
                      onTimeUpdate={(event) => { setPlayhead(event.currentTarget.currentTime); if (blurPlayer.current && Math.abs(blurPlayer.current.currentTime - event.currentTarget.currentTime) > 0.25) blurPlayer.current.currentTime = event.currentTarget.currentTime; if (previewRangeEnd.current !== null && event.currentTarget.currentTime >= previewRangeEnd.current) { event.currentTarget.pause(); previewRangeEnd.current = null; } }}
                      aria-label="Source video preview" className="workspace-video" />
                      {previewText && <div className={`subtitle-preview ${previewStyle.preset === "boxed" ? "boxed" : ""}`} style={{ bottom: `${previewStyle.bottom_margin / 288 * 100}%`, fontFamily: previewStyle.font_name, color: previewStyle.color, fontWeight: previewStyle.bold ? 700 : 400, fontSize: activeClip?.format === "source" ? `calc(100cqh * ${previewStyle.font_size} / 288)` : `calc(100cqw * ${previewStyle.font_size} / 384)`, WebkitTextStroke: `${(previewStyle.outline ?? 2) / 2}px black` }}>
                        {wordBox ? previewWordGroup?.map((cue, index) => <span key={index} style={{ backgroundColor: playhead >= cue.start_seconds && playhead < cue.end_seconds ? previewStyle.highlight_color : "transparent", color: playhead >= cue.start_seconds && playhead < cue.end_seconds ? "#101518" : previewStyle.color, borderRadius: "0.08em", padding: "0.07em 0.10em", WebkitTextStroke: "0" }}>{cue.text.trim()}{" "}</span>) : previewText.split(/(\s+)/).map((word, index) => <span key={index} style={{ color: previewStyle.preset === "highlight" && previewHighlights.has(word.replace(/^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$/gu, "").toLowerCase()) ? previewStyle.highlight_color : undefined }}>{word}</span>)}
                      </div>}
                    </div> :
                      <div className="video-placeholder">{sourceTooLarge ? "Source preview is limited to 250 MiB in the desktop app. Timeline edits and rendering still work." : "Loading source preview…"}</div>)}
                    {sourceDisplayUrl && <div className="preview-transport"><button type="button" className="secondary" onClick={() => seekSource(Math.max(Number(activeClip?.start) || 0, (sourcePlayer.current?.currentTime ?? 0) - 3))}>↶ 3 seconds</button><small>Style preview · render to check final appearance</small></div>}
                    {sourcePreviewError && <p role="alert" className="error">{sourcePreviewError}</p>}
                    {fileResult?.metadata?.duration_seconds && <MultiClipTimeline clips={clipDrafts} duration={fileResult.metadata.duration_seconds}
                      selectedId={activeClip?.id ?? null} playhead={playhead}
                      onSelect={(id) => { const clip = clipDrafts.find((item) => item.id === id); if (clip) selectClip(clip); }}
                      onSeek={seekSource} onChange={setClipRange} />}
                    <div className="stage-actions"><span>{activeClip ? `Clip ${clipDrafts.findIndex((clip) => clip.id === activeClip.id) + 1} · ${activeClip.start}–${activeClip.end}s` : "Watch the source, then select a clip to edit"}</span>
                      {clipDrafts.length > 0 && <button type="button" className="secondary" disabled={batchRendering || !ready}
                        onClick={() => void renderBatch()}>{batchRendering ? "Rendering batch…" : `Render all ${clipDrafts.length}`}</button>}</div>
                  </div>
                  <div className="workspace-inspector">
                {clipDrafts.length > 0 && <>
                  <div className="clip-picker" role="group" aria-label="Choose a clip to edit">
                    {clipDrafts.map((clip, index) => <button key={clip.id} type="button" className={activeClip?.id === clip.id ? "clip-choice active" : "clip-choice"}
                      aria-pressed={activeClip?.id === clip.id}
                      onClick={() => { selectClip(clip); seekSource(Number(clip.start) || 0); }}>
                      <strong>{clip.title?.trim() || `Clip ${index + 1}`}</strong><span>{clip.start}–{clip.end} s</span><small>{clip.rendering ? "Rendering" : clip.result ? "Ready" : "Needs render"}</small>
                    </button>)}
                  </div>
                  <div className="video-list" aria-label="Clip drafts">
                    {clipDrafts.filter((clip) => clip.id === activeClip?.id).map((clip) => {
                      return <div className="clip-editor" key={clip.id}>
                      <h3>Clip {clipDrafts.findIndex((item) => item.id === clip.id) + 1}{clip.proposalSource === "ai" ? " · AI suggested range" : " · local timing range"}</h3>
                      <details className="clip-advanced"><summary>Edit clip · timing, subtitles and framing</summary><fieldset className="clip-edit-fields" disabled={batchRendering}>
                      <label>Clip title<input type="text" maxLength={160} value={clip.title ?? ""} placeholder={`Clip ${clipDrafts.findIndex((item) => item.id === clip.id) + 1}`}
                        onChange={(event) => updateClip(clip.id, { title: event.target.value })} /></label>
                      <p className="note">{clip.burnSubtitles ? (clip.captionText === clip.text ? "Timed source subtitles will be burned into this clip." : "Your custom line will replace the timed subtitles for this clip.") : "Subtitles will not be burned."}</p>
                      {clip.subtitleStyle?.preset !== "word_box" && <details className="optional-tools"><summary>Replace timed subtitles with one line</summary>
                        <p className="note">Use this only for a short on-screen line. A custom line stays visible for the whole clip.</p>
                        <label>Custom subtitle line
                          <textarea value={clip.captionText === clip.text ? "" : clip.captionText} rows={2} placeholder="Leave blank to keep timed source subtitles"
                            onChange={(event) => updateClip(clip.id, { captionText: event.target.value || clip.text, result: undefined })} />
                        </label>
                        {clip.captionText !== clip.text && <button type="button" className="secondary" onClick={() => updateClip(clip.id, { captionText: clip.text, result: undefined })}>Restore timed subtitles</button>}
                      </details>}
                      <button type="button" className="secondary" disabled={!sourceDisplayUrl}
                        onClick={() => playSelectedRange(clip)}>
                        Play selected range
                      </button>
                      <div className="form-row">
                        <label>Start (seconds)<input type="number" min="0" step="0.01" value={clip.start}
                          onChange={(event) => updateClip(clip.id, { start: event.target.value, result: undefined })} /></label>
                        <label>End (seconds)<input type="number" min="0" step="0.01" value={clip.end}
                          onChange={(event) => updateClip(clip.id, { end: event.target.value, result: undefined })} /></label>
                      </div>
                      <div className="form-row">
                        <button type="button" className="secondary" disabled={!sourceDisplayUrl}
                          onClick={() => updateClip(clip.id, { start: (sourcePlayer.current?.currentTime ?? 0).toFixed(2), result: undefined })}>Set start at playhead</button>
                        <button type="button" className="secondary" disabled={!sourceDisplayUrl}
                          onClick={() => updateClip(clip.id, { end: (sourcePlayer.current?.currentTime ?? 0).toFixed(2), result: undefined })}>Set end at playhead</button>
                      </div>
                      <label className="checkbox"><input type="checkbox" checked={clip.burnSubtitles}
                        onChange={(event) => updateClip(clip.id, { burnSubtitles: event.target.checked, result: undefined })} /> Burn subtitles</label>
                      {clip.burnSubtitles && <SubtitleControls value={clip.subtitleStyle ?? defaultSubtitleStyle}
                        onChange={(subtitleStyle) => updateClip(clip.id, { subtitleStyle, result: undefined })}
                        isProfileDefault={JSON.stringify(activeProfile.subtitleStyle) === JSON.stringify(clip.subtitleStyle ?? defaultSubtitleStyle)} onSaveDefault={() => updateProfile({ subtitleStyle: clip.subtitleStyle ?? defaultSubtitleStyle })} />}
                      {clip.burnSubtitles && clip.subtitleStyle?.preset === "word_box" && <div className="word-timing-tools">
                        <p className="note">A short phrase stays visible; the box follows each spoken word. Local speech recognition may need correction. Word box uses the original spoken language and ignores custom subtitle lines.</p>
                        <button type="button" className="secondary" disabled={wordTimingBusy} onClick={() => void generateWordTiming()}>{wordTimingBusy ? "Listening locally…" : clip.wordTranscriptPath ? "Regenerate word timing" : "Generate word timing"}</button>
                        {clip.wordTranscriptPath && <p className="note">Word timing ready · saved locally</p>}
                        {wordTimingError && <p role="alert" className="error">{wordTimingError}</p>}
                      </div>}
                      {clip.burnSubtitles && clip.subtitleStyle?.preset !== "word_box" && <details><summary>Subtitle language · {clip.subtitleLanguage ?? "original"}</summary>
                        <label>Translate to<select value={subtitleLanguage} onChange={(event) => setSubtitleLanguage(event.target.value)}><option value="en">English</option><option value="es">Spanish</option><option value="pt">Portuguese</option><option value="fr">French</option><option value="de">German</option><option value="it">Italian</option></select></label>
                        <label><input type="checkbox" checked={translationConsent} onChange={(event) => setTranslationConsent(event.target.checked)} />Send this clip’s subtitle text to TV7 cloud AI for translation</label>
                        <button type="button" disabled={!accessToken || !translationConsent || translationBusy} onClick={() => void translateClipSubtitles(clip)}>{translationBusy ? "Translating…" : "Translate subtitles"}</button>
                        {clip.originalTranscriptPath && <button type="button" className="secondary" onClick={() => updateClip(clip.id, { transcriptPath: clip.originalTranscriptPath, subtitleLanguage: "original", result: undefined })}>Restore original language</button>}
                        {translationError && <p role="alert" className="error">{translationError}</p>}
                      </details>}
                      <label>Video format<select value={clip.format ?? "source"}
                        onChange={(event) => updateClip(clip.id, { format: event.target.value as ClipDraft["format"], result: undefined })}>
                        <option value="source">Original source framing</option>
                        <option value="vertical_9_16">Fit · black bars (9:16)</option>
                        <option value="vertical_9_16_blur">Blur background (9:16)</option>
                        <option value="vertical_9_16_crop">Fill · center crop (9:16)</option>
                      </select></label>
                      {clip.format === "vertical_9_16_crop" && <p className="note">Center crop removes left and right content. Render and preview this clip before any cloud handoff.</p>}
                      <button type="button" className="primary" disabled={clip.rendering || batchRendering || !ready}
                        onClick={() => void renderDraft(clip)}>{clip.rendering ? "Rendering…" : clip.result ? "Retry render" : "Render clip"}</button>
                      </fieldset>
                      </details>
                      {clip.error && <p role="alert" className="error">{clip.error}</p>}
                    </div>})}
                  </div>
                </>}
                {fileResult && clipDrafts.length === 0 && <p className="note">No proposed clips yet. Use the transcript tools above, or set a manual clip below.</p>}
                  </div>
                </div>
                {activeClip && (() => {
                  const clip = activeClip;
                  const copy = clip.postCopy?.source === "template" ? starterPostCopy(clip.title || fileResult.name)
                    : clip.postCopy ?? starterPostCopy(clip.title || fileResult.name);
                  const editCopy = (patch: Partial<PostCopy>) => updateClip(clip.id, { postCopy: { ...copy, ...patch, source: "edited" } });
                  return <section className="render-review" aria-label="Selected clip review">
                    <div className="render-review-heading"><div><span className="kicker">CLIP REVIEW</span><h3>{clip.title?.trim() || "Selected clip"}</h3></div>
                      <span className="count">{clip.result ? `Rendered · ${clip.result.duration_seconds.toFixed(1)}s` : "Render pending"}</span></div>
                    <div className="render-review-grid">
                      <div className="render-review-player">
                        {clip.result && previewUrl && renderResult?.output_path === clip.result.output_path
                          ? <video controls src={previewUrl} aria-label="Selected rendered clip preview" className="clip-preview" />
                          : <div className="video-placeholder">{clip.result ? "Loading rendered preview…" : "Render this clip to review the finished video."}</div>}
                        {clip.result && <button type="button" className="secondary" disabled={copy.source === "template" || !copy.youtube_description.trim()} title={copy.source === "template" ? "Generate or write post copy first" : undefined} onClick={() => { setRenderResult(clip.result ?? null); setAsset(null); setCloudClip(null); setDraft(null); setPage("schedule"); }}>Prepare schedule →</button>}
                      </div>
                      <div className="render-review-copy">
                        <div className="render-review-copy-heading"><h4>Post copy</h4><span>{copy.source === "template" ? "Needs writing" : copy.source === "ai" ? `AI draft · ${copy.model ?? "provider"}` : "Edited"}</span></div>
                        <p className="note">A post should sell the moment, not repeat the subtitles. AI uses the video's mood and this clip's spoken content; review the result before scheduling.</p>
                        {copy.source !== "template" && <div className="copy-direction"><label>Video mood<input maxLength={120} value={copy.mood} onChange={(event) => editCopy({ mood: event.target.value })} /></label>
                          <label>Clip hook<input maxLength={120} value={copy.hook} onChange={(event) => editCopy({ hook: event.target.value })} /></label></div>}
                        <label>YouTube Short title<input maxLength={100} value={copy.youtube_title} onChange={(event) => editCopy({ youtube_title: event.target.value })} /></label>
                        <label>YouTube description<textarea maxLength={4500} rows={3} value={copy.youtube_description} placeholder="Write a description or generate one with AI" onChange={(event) => editCopy({ youtube_description: event.target.value })} /></label>
                        <label>Instagram caption<textarea maxLength={2000} rows={3} value={copy.instagram_caption} placeholder="Write a caption or generate one with AI" onChange={(event) => editCopy({ instagram_caption: event.target.value })} /></label>
                        <label>TikTok caption<textarea maxLength={2000} rows={3} value={copy.tiktok_caption} placeholder="Write a caption or generate one with AI" onChange={(event) => editCopy({ tiktok_caption: event.target.value })} /></label>
                        <label>Hashtags<input value={copy.hashtags.join(" ")} placeholder="#topic #series" onChange={(event) => editCopy({ hashtags: event.target.value.split(/\s+/).filter(Boolean).slice(0, 5).map((tag) => tag.startsWith("#") ? tag : `#${tag}`) })} /></label>
                        <div className="copy-actions"><p className="note">AI writes original post text using this clip’s transcript and the video’s mood. Transcript text is sent to TV7 cloud AI.</p>
                          <button type="button" className="primary" disabled={Boolean(postCopyBusy) || batchRendering} onClick={() => void generatePostCopy(clip)}>{postCopyBusy === clip.id ? "Writing…" : copy.source === "ai" ? "Regenerate with AI" : "Generate post copy with AI"}</button></div>
                        {!accessToken && <p className="note">Sign in to TV7 in Account to use AI. Manual writing stays available offline.</p>}
                        {postCopyError && <p role="alert" className="error">{postCopyError}</p>}
                      </div>
                    </div>
                  </section>;
                })()}
                {activeClip && sourceDisplayUrl && fileResult && <Suspense fallback={<p>Loading remix studio…</p>}><RemixStudio key={activeClip.id} assetLibrary={<><MemeLibrary assets={memeMedia} disabled={batchRendering||remixBusy} upload={async(file,fields)=>{const form=new FormData();form.append("file",file);for(const [key,value]of Object.entries(fields))form.append(key,value);await request(base,token,"/v1/remix/assets",{method:"POST",body:form});setMemeRevision(v=>v+1);}}/>{memeError&&<p role="alert" className="error">{memeError}</p>}</>} busy={remixBusy||wordTimingBusy||batchRendering||libraryArtBusy} direct={async()=>{setRemixBusy(true);const version=mediaVersion.current;try{const settings=await directClip(activeClip);if(version===mediaVersion.current&&clipDraftsRef.current.some(c=>c.id===activeClip.id&&c.start===activeClip.start&&c.end===activeClip.end))updateClip(activeClip.id,{remixSettings:settings,proposalSource:`remix_${settings.treatment}`,result:undefined});}finally{setRemixBusy(false);}}} apply={async()=>{setBatchRendering(true);try{updateClip(activeClip.id,{proposalSource:`remix_${activeClip.remixSettings?.treatment??"comedy"}`,burnSubtitles:true,subtitleStyle:normalizeSubtitleStyle({...defaultSubtitleStyle,...activeClip.subtitleStyle,preset:"word_box"})});const outcome=await renderDraft({...activeClip,proposalSource:`remix_${activeClip.remixSettings?.treatment??"comedy"}`,burnSubtitles:true,subtitleStyle:normalizeSubtitleStyle({...defaultSubtitleStyle,...activeClip.subtitleStyle,preset:"word_box"})});if(!outcome?.rendered)throw new Error("Render failed; review the clip error.");}finally{setBatchRendering(false);}}} prepare={generateWordTiming} change={settings=>updateClip(activeClip.id,{remixSettings:settings,result:undefined})} input={{cutaways:memeMedia,src:sourceDisplayUrl,start:Number(activeClip.start),duration:Number(activeClip.end)-Number(activeClip.start),words:remixCues,treatment:activeClip.remixSettings?.treatment??(activeClip.proposalSource?.startsWith("remix_")?activeClip.proposalSource.slice(6) as "comedy"|"editorial"|"retro":"comedy"),settings:activeClip.remixSettings??undefined}} create={async(treatment,settings)=>{
                  setRemixBusy(true); setBatchRendering(true); creationLock.current=true; setRenderError("");
                  try {
                    const parent=activeClip; const version=mediaVersion.current;
                    const wordPath=await ensureWordTiming(fileResult.media_path, parent.wordTranscriptPath);
                    const response=await request<{result:RenderResult}>(base,token,"/v1/media/remix",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({source:fileResult.media_path,word_path:wordPath,start:Number(parent.start),end:Number(parent.end),treatment,settings})});
                    const variant:ClipDraft={...parent,id:crypto.randomUUID(),title:`${parent.title||"Clip"} · ${settings.effect === "none" ? treatment : settings.effect+" remix"}`,proposalSource:`remix_${treatment}`,burnSubtitles:true,subtitleStyle:{...defaultSubtitleStyle,...parent.subtitleStyle,preset:"word_box"},remixSettings:settings,wordTranscriptPath:wordPath,result:{...response.result,start_seconds:Number(parent.start),end_seconds:Number(parent.end),caption_text:parent.captionText},rendering:false,error:undefined};
                    if(version!==mediaVersion.current) {
                      const videos=await request<LibraryVideo[]>(base,token,"/v1/library/videos");
                      const video=videos.find(item=>item.media_path===fileResult.media_path);
                      if(!video)throw new Error("The source project is no longer available to save this remix.");
                      await saveLibraryVideo({...video,clips:[...video.clips,...catalogClips([variant])]});
                      return;
                    }
                    setClipDrafts(current=>[...current,variant]);
                    const context=library.find(video=>video.media_path===fileResult.media_path);
                    const copy=context ? await generatePostCopy(variant,context) : undefined;
                    if(copy) updateClip(variant.id,{postCopy:copy});
                  } catch(error) {setRenderError(error instanceof Error ? error.message : String(error));throw error;} finally {setRemixBusy(false); setBatchRendering(false); creationLock.current=false;}
                }}/></Suspense>}
                {fileResult && (
                  <details className="manual-clip"><summary>Manual clip fallback</summary>
                  <div className="clip-editor">
                    <h3>
                      {selectedCandidate === null
                        ? "Set clip timing"
                        : "Review clip timing"}
                    </h3>
                    <div className="form-row">
                      <label htmlFor="clip-start">
                        Start (seconds)
                        <input
                          id="clip-start"
                          type="number"
                          min="0"
                          step="0.01"
                          value={clipStart}
                          onChange={(event) => setClipStart(event.target.value)}
                        />
                      </label>
                      <label htmlFor="clip-end">
                        End (seconds)
                        <input
                          id="clip-end"
                          type="number"
                          min="0"
                          step="0.01"
                          value={clipEnd}
                          onChange={(event) => setClipEnd(event.target.value)}
                        />
                      </label>
                    </div>
                    <button
                      type="button"
                      className="primary"
                      disabled={!ready || renderBusy || !fileResult}
                      onClick={() => void renderCandidate()}
                    >
                      {renderBusy ? "Rendering clip…" : "Render clip"}
                    </button>
                  </div></details>
                )}
                {renderError && (
                  <p role="alert" className="error">
                    {renderError}
                  </p>
                )}
                {renderResult && renderResult.output_path !== activeClip?.result?.output_path && (
                  <div className="result" role="status">
                    <strong>Clip rendered</strong>
                    <span>
                      {renderResult.duration_seconds.toFixed(1)} seconds · saved
                      in Engine workspace
                    </span>
                    <details>
                      <summary>Technical details</summary>
                      <code>{renderResult.output_path}</code>
                    </details>
                    {previewUrl && (
                      <video
                        controls
                        src={previewUrl}
                        aria-label="Rendered clip preview"
                        className="clip-preview"
                      />
                    )}
                    {previewError && <span>{previewError}</span>}
                  </div>
                )}
              </section>}
              {page === "schedule" && fileResult && renderResult && asset && (
                <details className="panel workspace-drawer">
                  <summary>Existing Backend asset draft</summary>
                  <span className="kicker">SELECTED CLIP</span>
                  <h2>Prepare a private schedule draft</h2>
                  <p className="note">
                    Your render stays on this computer until you approve an
                    upload. The Backend stores an owner-only asset and a
                    schedule draft. A draft is not a live post or a guarantee of
                    future posting.
                  </p>
                  <p className="note">
                    Backend: <code>{backendBase}</code>
                  </p>
                  {!accessToken && <p className="note">Sign in once in the account section below to prepare this private draft.</p>}
                  {accessToken && <p className="note">Signed in as {signedInEmail}.</p>}
                  {accessToken && youtubeConnection && (
                    <p className="note">
                      YouTube:{" "}
                      {youtubeConnection.connected
                        ? `connected to ${youtubeConnection.channel_title ?? youtubeConnection.channel_id}`
                        : "disconnected"}
                      .{" "}
                      {youtubeConnection.connected
                        ? "This UI records a draft; check its Backend status before treating it as a post."
                        : "A disconnected draft is non-executable while publishing is disabled."}
                    </p>
                  )}
                  {accessToken && license && (
                    <p className="note">
                      Cloud AI license: {license.license_status}; credits:{" "}
                      {license.cloud_ai_credits_remaining}. Local rendering does
                      not use these credits.
                    </p>
                  )}
                  {loginError && (
                    <p role="alert" className="error">
                      {loginError}
                    </p>
                  )}
                  {accessToken && !renderResult.media_id && (
                    <p className="note">
                      This Engine build does not offer approved clip export yet.
                    </p>
                  )}
                  {accessToken && renderResult.media_id && !cloudClip && (
                    <div className="approval-box">
                      <p>
                        {asset
                          ? "The private asset is uploaded. Finish creating its owner-scoped clip record?"
                          : "Approve sending this rendered MP4 to your private TV7 Backend asset storage?"}
                      </p>
                      <button
                        className="primary"
                        type="button"
                        disabled={handoffBusy}
                        onClick={() => void approveCloudHandoff()}
                      >
                        {handoffBusy
                          ? "Preparing cloud draft…"
                          : asset
                            ? "Finish clip record"
                            : "Approve private clip upload"}
                      </button>
                    </div>
                  )}
                  {handoffError && (
                    <p role="alert" className="error">
                      {handoffError}
                    </p>
                  )}
                  {asset && (
                    <p role="status" className="success">
                      Private asset uploaded:{" "}
                      {formatSize(asset.asset_size_bytes)}. Clip record{" "}
                      {cloudClip ? "ready" : "being prepared"}.
                    </p>
                  )}
                  {cloudClip && !draft && (
                    <form
                      className="draft-form"
                      onSubmit={(event) => {
                        event.preventDefault();
                        void createScheduleDraft();
                      }}
                    >
                      <h3>Create a schedule draft</h3>
                      <p className="note">
                        This records a draft request. It does not send a live
                        post.
                      </p>
                      <label htmlFor="target-account">Connected YouTube account</label>
                      <select id="target-account" required value={targetAccount} onChange={(event) => setTargetAccount(event.target.value)}>
                        <option value="">Choose an account</option>
                        {publishingTargets.filter((target) => target.platform === "youtube_shorts").map((target) =>
                          <option key={target.account_ref} value={target.account_ref}>{target.display_name}</option>)}
                      </select>
                      <label htmlFor="schedule-at">
                        Requested local date and time
                      </label>
                      <input
                        id="schedule-at"
                        type="datetime-local"
                        required
                        value={scheduleAt}
                        onChange={(event) => setScheduleAt(event.target.value)}
                      />
                      <label htmlFor="schedule-caption">Caption</label>
                      <textarea
                        id="schedule-caption"
                        maxLength={5000}
                        value={scheduleCaption}
                        onChange={(event) =>
                          setScheduleCaption(event.target.value)
                        }
                      />
                      <button className="primary" disabled={draftBusy}>
                        {draftBusy ? "Saving draft…" : "Create schedule draft"}
                      </button>
                    </form>
                  )}
                  {draftError && (
                    <p role="alert" className="error">
                      {draftError}
                    </p>
                  )}
                  {draft && (
                    <div className="result" role="status">
                      <strong>Schedule draft #{draft.id}</strong>
                      <span>
                        Status: {draft.status} · requested{" "}
                        {draft.scheduled_at
                          ? new Date(draft.scheduled_at).toLocaleString()
                          : "time unavailable"}
                      </span>
                      <span>
                        {draft.published_at && draft.remote_post_id
                          ? "Backend reports a published post."
                          : "No live post has been confirmed."}
                      </span>
                      {draft.error_message && (
                        <span>{draft.error_message}</span>
                      )}
                      <button
                        className="secondary"
                        type="button"
                        disabled={draftBusy}
                        onClick={() => void refreshScheduleDraft()}
                      >
                        Refresh draft status
                      </button>
                    </div>
                  )}
                </details>
              )}
              {page === "ingest" && <details className="panel workspace-drawer" open>
                <summary>Import a video from one URL</summary>
                <span className="kicker">SINGLE URL</span>
                <h2>Import one video</h2>
                <p className="note">
                  Paste a video URL to start one Engine download job. This does
                  not scan or download the rest of its channel. Import only
                  media you have rights to use; source sites may reject
                  downloads.
                </p>
                <form
                  onSubmit={(event) => {
                    event.preventDefault();
                    void ingestSingleUrl();
                  }}
                >
                  <label htmlFor="single-url">Video URL</label>
                  <div className="form-row">
                    <input
                      id="single-url"
                      type="url"
                      required
                      placeholder="https://www.youtube.com/watch?v=..."
                      value={singleUrl}
                      onChange={(event) => setSingleUrl(event.target.value)}
                    />
                    <button className="primary" disabled={!ready || singleBusy}>
                      {singleBusy ? "Starting…" : "Import video"}
                    </button>
                  </div>
                </form>
                {singleError && (
                  <p className="error" role="alert">
                    {singleError}
                  </p>
                )}
                {downloadOpenError && (
                  <p className="error" role="alert">
                    {downloadOpenError}
                  </p>
                )}
                {singleJob && (
                  <div className="job" role="status">
                    <strong>Video import</strong>
                    <span>{jobStatus(singleJob)}</span>
                    {singleJob.error && <small>{singleJob.error}</small>}
                    {singleJob.status === "succeeded" &&
                    singleJob.result?.media_path ? (
                      <button
                        type="button"
                        className="primary"
                        disabled={fileBusy}
                        onClick={() =>
                          void openDownloadedJob(
                            singleJob,
                            singleJob.result?.media_path?.split("/").pop() ??
                              "Downloaded video",
                            singleUrl,
                          )
                        }
                      >
                        Open in clip workspace
                      </button>
                    ) : singleJob.status === "succeeded" ? (
                      <small>
                        Download completed without a usable media file.
                      </small>
                    ) : null}
                  </div>
                )}
              </details>}
              {page === "editor" && <p className="note">Clip proposals come from transcript timing. Review ranges on the timeline before rendering.</p>}
            </>}
          {page === "profile" && <>
            <span className="kicker">TV7 ACCOUNT</span><h1>Account</h1>
            <p className="lead">One TV7 account can run several creator profiles. Each profile owns its source videos, release plan, and connected destinations.</p>
            {workspaceError && <p role="alert" className="error">Profile storage: {workspaceError}</p>}
            <section className="panel profile-panel">
              <div className="heading"><div><h2>{signedInEmail || "TV7 account"}</h2><p className="note">Your TV7 account owns cloud assets, connections, and schedule drafts.</p></div>
                {accessToken && <button type="button" className="secondary" onClick={signOut}>Sign out</button>}</div>
              {!accessToken && <form onSubmit={(event) => { event.preventDefault(); void signIn(); }}>
                <label>TV7 account email<input type="email" required autoComplete="username" value={accountEmail} onChange={(event) => setAccountEmail(event.target.value)} /></label>
                <label>Password<input type="password" required autoComplete="current-password" value={accountPassword} onChange={(event) => setAccountPassword(event.target.value)} /></label>
                <button className="secondary" disabled={loginBusy}>{loginBusy ? "Signing in…" : "Sign in"}</button>
              </form>}
              {loginError && <p role="alert" className="error">{loginError}</p>}
              {loginError && accountEmail.trim().toLowerCase() === "tv7-automation@example.com" &&
                ["127.0.0.1", "localhost"].includes(window.location.hostname) &&
                <p className="note">This disposable local test account uses the current password in <code>tv7-core/docs/.tmp/dev-browser-stack/automation-password</code>. Browser autofill may have an older password. Use a separate TV7 account for real social connections.</p>}
            </section>
            <section className="panel profile-panel">
              <div className="heading"><div><h2>Creator profiles</h2><p className="note">Choose a profile to edit its channel, clips, and publishing accounts.</p></div><button className="secondary" type="button" disabled={!workspaceLoaded} onClick={addProfile}>New profile</button></div>
              <div className="account-profile-list">{profiles.map((profile) => <button type="button" key={profile.id} className={profile.id === activeProfileId ? "account-profile active" : "account-profile"} onClick={() => { setActiveProfileId(profile.id); setChannelUrl(profile.channelUrl); setClipCount(profile.defaultClipCount); setPlanSpacing(profile.daysBetweenPosts); }}>
                <strong>{profile.name}</strong><span>{profile.channelUrl || "No source channel"}</span></button>)}</div>
              <h3>{activeProfile.name} settings</h3>
              <label>Profile name<input disabled={!workspaceLoaded} value={activeProfile.name} onChange={(event) => updateProfile({ name: event.target.value })} /></label>
              <label>YouTube source channel<input disabled={!workspaceLoaded} type="url" placeholder="https://www.youtube.com/@yourchannel" value={activeProfile.channelUrl} onChange={(event) => updateProfile({ channelUrl: event.target.value })} /></label>
              <div className="form-row">
                <label>Clips per video<input disabled={!workspaceLoaded} type="number" min="1" max="12" value={activeProfile.defaultClipCount} onChange={(event) => updateProfile({ defaultClipCount: Math.max(1, Math.min(12, Number(event.target.value) || 1)) })} /></label>
                <label>Days between posts<input disabled={!workspaceLoaded} type="number" min="1" max="30" value={activeProfile.daysBetweenPosts} onChange={(event) => updateProfile({ daysBetweenPosts: Math.max(1, Math.min(30, Number(event.target.value) || 1)) })} /></label>
              </div>
              <button className="primary" type="button" onClick={() => { setChannelUrl(activeProfile.channelUrl); setClipCount(activeProfile.defaultClipCount); setPage("ingest"); }}>Discover channel videos →</button>
            </section>
            {accessToken ? <SocialConnections profileName={activeProfile.name} providers={socialScope.auth === accessToken ? socialProviders : []} connections={socialScope.auth === accessToken && socialScope.profileId === activeProfileId ? socialConnections : []}
              busy={connectionBusy} pending={pendingSocialLogin?.profileId === activeProfileId ? pendingSocialLogin : null} error={connectionError}
              onConnect={(platform) => void beginSocialConnection(platform)} onDisconnect={(connection) => void disconnectSocialAccount(connection)}
              onRefresh={() => void checkSocialConnections()} onCancelLogin={() => setPendingSocialLogin(null)} onOpenLogin={() => { if (pendingSocialLogin) void beginSocialConnection(pendingSocialLogin.platform); }} />
              : <section className="panel"><h2>Destinations for {activeProfile.name}</h2><p className="note">Sign in above to connect YouTube, Instagram, and TikTok accounts.</p></section>}
            <section className="panel"><h2>Local storage</h2>
              <p className="note">{library.length} catalog records · {libraryGroups.length} source projects. Consolidation retains every saved clip and removes only byte-identical extra source files.</p>
              <button type="button" className="secondary" disabled={consolidateBusy || !ready} onClick={async () => { setConsolidateBusy(true); setConsolidateMessage(""); try { const result = await request<{ projects_updated: number; duplicate_sources_removed: number; clips_preserved: number }>(base, token, "/v1/library/consolidate", { method: "POST" }); setConsolidateMessage(`Updated ${result.projects_updated} projects, removed ${result.duplicate_sources_removed} exact source copies, and kept ${result.clips_preserved} clips.`); await refreshLibrary(); } catch (error) { setConsolidateMessage(String(error)); } finally { setConsolidateBusy(false); } }}>
                {consolidateBusy ? "Consolidating…" : "Consolidate exact copies"}
              </button>
              {consolidateMessage && <p role="status" className="note">{consolidateMessage}</p>}
              {recoveredLibraryGroups.length > 0 && <details className="unlinked-list"><summary>{recoveredLibraryGroups.length} projects need a title</summary><div className="library-list">{recoveredLibraryGroups.map(renderLibraryGroup)}</div></details>}
              {unlinkedClips.length > 0 && <details className="unlinked-list"><summary>{unlinkedClips.length} older clips without a saved project</summary>
                <p className="note">Their source cannot be reliably identified. These files remain on disk.</p>
                {unlinkedClips.map((clip) => <div key={clip.path} className="unlinked-row"><span>{clip.name} · {formatSize(clip.size_bytes)}</span><button className="secondary" onClick={() => { setUnlinkedSelected(clip.path); setRenderResult({ output_path: clip.path, duration_seconds: 0, start_seconds: 0, end_seconds: 0, caption_text: "" }); }}>Preview</button></div>)}
                {unlinkedSelected && previewUrl && <video controls src={previewUrl} aria-label="Older rendered clip preview" className="clip-preview" />}
                {unlinkedSelected && previewError && <p role="alert" className="error">{previewError}</p>}
              </details>}
            </section>
          </>}
          {page === "ingest" && (
            <>
              <span className="kicker">CHANNEL DISCOVERY</span>
              <h2>Channel batch</h2>
              <p className="lead">
                Discover a channel, review its videos, and explicitly choose
                which ones Engine may download. Choose only media you have
                rights to use; download failures are shown per job.
              </p>
              {ready && !channelToolsReady && <p role="alert" className="error">
                Channel discovery needs yt-dlp and a supported JavaScript runtime (Node or Deno).
                {missingChannelTools.length > 0 && <> Missing: {missingChannelTools.map((tool) => tool.name).join(", ")}.</>}
                {" "}Install the missing tools, restart TV7 Studio, then try again.
              </p>}
              <section className="panel">
                <form
                  onSubmit={(event) => {
                    event.preventDefault();
                    void discover();
                  }}
                >
                  <label htmlFor="channel-url">Channel URL</label>
                  <div className="form-row">
                    <input
                      id="channel-url"
                      type="url"
                      placeholder="https://www.youtube.com/@channel"
                      value={channelUrl}
                      onChange={(event) => {
                        setChannelUrl(event.target.value);
                        setDiscovery(null);
                        setSelection({});
                        setConfirming(false);
                      }}
                      required
                    />
                    <button
                      className="primary"
                      disabled={!ready || !channelToolsReady || discoverBusy}
                    >
                      {discoverBusy ? "Discovering…" : "Discover videos"}
                    </button>
                  </div>
                </form>
                {discoverError && (
                  <p role="alert" className="error">
                    {discoverError}
                  </p>
                )}
              </section>
              {discovery && (
                <section className="panel">
                  <div className="heading">
                    <div>
                      <span className="kicker">REVIEW</span>
                      <h2>Discovered videos</h2>
                    </div>
                    <span className="count">{selected.length} selected</span>
                  </div>
                  <p className="note">
                    Discovery downloads nothing. Select up to 25 videos, then
                    review the batch.
                  </p>
                  <div className="video-list">
                    {discovery.videos.map((video) => (
                      <label className="video-row" key={video.id}>
                        <input
                          type="checkbox"
                          checked={Boolean(selection[video.id])}
                          disabled={
                            !selection[video.id] && selected.length >= 25
                          }
                          onChange={() => toggle(video)}
                        />
                        <span>
                          <strong>{video.title}</strong>
                          <small>
                            {video.duration_seconds == null
                              ? "Duration unknown"
                              : Math.floor(video.duration_seconds / 60) +
                                ":" +
                                String(
                                  Math.floor(video.duration_seconds % 60),
                                ).padStart(2, "0")}{" "}
                            · {video.url}
                          </small>
                        </span>
                      </label>
                    ))}
                  </div>
                  {discovery.next_cursor && (
                    <button
                      className="secondary"
                      disabled={discoverBusy}
                      onClick={() => void discover(discovery.next_cursor!)}
                    >
                      Load more videos
                    </button>
                  )}
                  <div className="footer">
                    <button
                      className="primary"
                      disabled={!selected.length || batchBusy}
                      onClick={() => setConfirming(true)}
                    >
                      Review selected ({selected.length})
                    </button>
                  </div>
                </section>
              )}
              {batchError && (
                <p role="alert" className="error">
                  {batchError}
                </p>
              )}
              {downloadOpenError && (
                <p role="alert" className="error">
                  {downloadOpenError}
                </p>
              )}
              {jobs.length > 0 && (
                <section className="panel">
                  <span className="kicker">ENGINE JOBS</span>
                  <h2>Batch progress</h2>
                  <p className="note">Confirmed videos automatically acquire captions or a local transcript, propose clips, then render them on this computer. Adjust the count per video and regenerate if needed.</p>
                  <p className="note">Optional DeepSeek suggestions send a selected video’s timed transcript text through Engine to TV7 Backend. Video pixels stay local. Backend credits may be charged per provider call; long transcripts may take several calls. Scores help review clips; they do not predict views. Local timing drafts remain available.</p>
                  <label className="checkbox"><input type="checkbox" checked={aiConsent}
                    onChange={(event) => setAiConsent(event.target.checked)} /> I agree to send a selected transcript to TV7 cloud AI when I request suggestions</label>
                  {accessToken && <p className="note">Cloud AI: {license?.reason_code ?? "checking readiness"} · credits remaining: {license?.cloud_ai_credits_remaining ?? "unknown"}</p>}
                  {accessToken && license?.cloud_ai_available === false && <p className="note">TV7 cloud AI is unavailable for this account ({license.reason_code ?? "not ready"}). Local timing drafts remain available.</p>}
                  {accessToken && <button type="button" className="secondary" onClick={() => void refreshAiReadiness()}>Refresh AI readiness</button>}
                  {jobs.map((item) => (
                    <div className="job" key={item.jobId}>
                      <strong>{item.title}</strong>
                      <span>{jobStatus(item.job)}</span>
                      {item.job?.error && <small>{item.job.error}</small>}
                      {batchVideos[item.jobId] && <>
                        <span>{batchVideos[item.jobId].status}</span>
                        {batchVideos[item.jobId].error && <p role="alert" className="error">{batchVideos[item.jobId].error}</p>}
                        {batchVideos[item.jobId].transcriptPath && <>
                          <button type="button" className="secondary" onClick={() => void estimateAiCalls(batchVideos[item.jobId].transcriptPath!)}>Estimate cloud AI calls</button>
                          {aiCueEstimates[batchVideos[item.jobId].transcriptPath!]?.count > 0 && <p className="note">{aiCueEstimates[batchVideos[item.jobId].transcriptPath!].count} timed cues · at least {Math.ceil(aiCueEstimates[batchVideos[item.jobId].transcriptPath!].count / 400)} provider call(s). The 24,000-character cap can increase the count and credit use.</p>}
                          {aiCueEstimates[batchVideos[item.jobId].transcriptPath!]?.error && <p role="alert" className="error">{aiCueEstimates[batchVideos[item.jobId].transcriptPath!].error}</p>}
                          <button type="button" className="secondary" disabled={!aiConsent || !accessToken || aiBusy || license?.cloud_ai_available === false}
                            onClick={() => void rankBatchTranscript(item.jobId)}>{aiBusy ? "Requesting AI suggestions…" : "Request AI suggestions for this video"}</button>
                          {batchVideos[item.jobId].aiError && <p role="alert" className="error">{batchVideos[item.jobId].aiError}</p>}
                          {batchVideos[item.jobId].aiModel && <p className="note">Suggestions from {batchVideos[item.jobId].aiModel}.</p>}
                          {(batchVideos[item.jobId].aiSuggestions?.length ?? 0) > 0 && <p className="note">Add a suggestion to keep current drafts, or replace this video’s visible draft cards. Existing saved Backend drafts are unaffected.</p>}
                          {batchVideos[item.jobId].aiUsage?.credits_charged != null && <p className="note">AI request charged {batchVideos[item.jobId].aiUsage?.credits_charged} credit(s); {batchVideos[item.jobId].aiUsage?.credits_remaining ?? "unknown"} remain.</p>}
                          {batchVideos[item.jobId].aiSuggestions?.map((suggestion, index) => <div className="candidate-row" key={`${item.jobId}-ai-${index}`}>
                            <strong>{suggestion.title} · {suggestion.start_seconds.toFixed(1)}–{suggestion.end_seconds.toFixed(1)} s</strong>
                            <span>{suggestion.reason}</span><small>AI suggestion score: {suggestion.score.toFixed(2)}</small>
                            <button type="button" className="secondary" disabled={batchVideos[item.jobId].clips.length >= 12}
                              onClick={() => addBatchSuggestion(item.jobId, suggestion)}>Add alongside local drafts</button>
                            <button type="button" className="secondary" onClick={() => replaceBatchWithSuggestion(item.jobId, suggestion)}>Replace visible drafts with this</button>
                          </div>)}
                        </>}
                        <label>Clips for this video (1–12)
                          <input type="number" min="1" max="12" value={batchVideos[item.jobId].count}
                            onChange={(event) => updateBatchVideo(item.jobId, { count: Math.max(1, Math.min(12, Number(event.target.value) || 1)) })} />
                        </label>
                        {item.job?.result?.media_path && <button type="button" className="secondary"
                          onClick={() => { batchQueue.current = batchQueue.current.then(() => processBatchVideo(item, batchVideos[item.jobId].count)); }}>
                          Retry or regenerate this video
                        </button>}
                        {batchVideos[item.jobId].clips.length > 0 && <div className="clip-picker" aria-label={`${item.title} clips`}>
                          {batchVideos[item.jobId].clips.map((clip, index) => <div className="clip-choice" key={clip.id}>
                            <strong>Clip {index + 1}</strong>
                            <span>{clip.start}–{clip.end} s · {clip.rendering ? "Rendering…" : clip.result ? "Ready" : clip.error ? "Needs retry" : "Needs render"}</span>
                            {clip.error && <small className="error">{clip.error}</small>}
                            <button type="button" className="secondary" disabled={fileBusy || !item.job?.result?.media_path}
                              onClick={() => void openDownloadedJob(item.job!, item.title, item.url, batchVideos[item.jobId], clip.result, clip.id)}>
                              {clip.result ? "Review / edit" : "Edit / render"}
                            </button>
                          </div>)}
                        </div>}
                      </>}
                      {item.job?.status === "succeeded" &&
                      item.job.result?.media_path ? (
                        <button
                          type="button"
                          className="primary"
                          disabled={fileBusy}
                          onClick={() =>
                            void openDownloadedJob(item.job!, item.title, item.url, batchVideos[item.jobId])
                          }
                        >
                          Open in clip workspace
                        </button>
                      ) : item.job?.status === "succeeded" ? (
                        <small>
                          Download completed without a usable media file.
                        </small>
                      ) : null}
                    </div>
                  ))}
                </section>
              )}
            </>
          )}
          {page === "schedule" && (<div className="schedule-content">
              <section className="panel" id="account-queue">
                <span className="kicker">LOCAL SCHEDULE</span>
                <div className="heading"><div><h2>{activeProfile.name} calendar</h2><p className="note">Timezone: {Intl.DateTimeFormat().resolvedOptions().timeZone} · Destinations: {publishingTargets.map((target) => target.display_name).join(", ") || "none connected"}</p><p className="note">Local release plan and confirmed YouTube releases, grouped by month.</p></div>
                  <input type="month" aria-label="Schedule month" value={scheduleMonth} onChange={(event) => setScheduleMonth(event.target.value)} /></div>
                <div className="schedule-filters" aria-label="Schedule platform filter">{["all", "instagram", "tiktok", "youtube_shorts"].map((platform) =>
                  <button type="button" key={platform} className={scheduleFilter === platform ? "active" : "secondary"} onClick={() => setScheduleFilter(platform)}>{platform === "all" ? "All" : platformName(platform)}</button>)}</div>
                <ScheduleCalendar month={scheduleMonth} uploads={scheduleFilter === "all" || scheduleFilter === "youtube_shorts" ? directReceipts.filter((receipt) => receipt.ownerEmail === signedInEmail && receipt.review.profileId === activeProfileId && receipt.status === "verified" && receipt.providerStatus === "scheduled" && receipt.review.publishAt).map((receipt) => ({ id: String(receipt.uploadId), title: receipt.review.title, scheduledAt: receipt.review.publishAt!, status: "scheduled", idempotencyKey: receipt.review.idempotencyKey, clipId: receipt.review.clipId })).concat(backendDirectUploads.filter((item) => item.creator_profile_id === activeProfileId && item.status === "scheduled" && item.scheduled_at && !directReceipts.some((receipt) => receipt.uploadId === item.upload_id)).map((item) => ({ id: String(item.upload_id), title: item.title, scheduledAt: item.scheduled_at!, status: "scheduled", idempotencyKey: item.idempotency_key, clipId: "" }))) : []} jobs={queue.filter((job) => scheduleFilter === "all" || job.platform === scheduleFilter)}
                  plan={schedulePlan && schedulePlan.profileId === activeProfileId ? { ...schedulePlan, items: schedulePlan.items.filter((item) => scheduleFilter === "all" || (item.platform ?? schedulePlan.platform) === scheduleFilter) } : null} />
                {queueHasMore && <p className="note">More older schedule jobs are available. Load more below to complete this calendar.</p>}
                <p className="note">Local review dates are plans. A confirmed YouTube release means the date is saved on YouTube.</p>
                {!accessToken ? <button type="button" className="secondary" onClick={() => setPage("profile")}>Sign in from Account to view the queue →</button>
                  : <p className="note">Signed in as {signedInEmail}. Manage connections in Account.</p>}
                {accessToken && youtubeConnection && <p className="note">YouTube account: {youtubeConnection.connected ? youtubeConnection.channel_title ?? youtubeConnection.channel_id : "not connected"}.</p>}
                {accessToken && <>
                  <button type="button" className="secondary" disabled={queueBusy} onClick={() => void loadQueue()}>Refresh queue</button>
                  {queueError && <p role="alert" className="error">{queueError}</p>}

                  {queue.filter((job) => (scheduleFilter === "all" || job.platform === scheduleFilter) &&
                    (!job.scheduled_at || monthKey(new Date(job.scheduled_at)) === scheduleMonth)).map((job) => <div className="job" key={job.id}>
                    <strong>Draft #{job.id} · clip #{job.clip_id}</strong>
                    <span>{job.platform} · {job.status} · {job.target_account_ref ?? "target unavailable"}</span>
                    <span>{job.scheduled_at ? new Date(job.scheduled_at).toLocaleString() : "No requested time"}</span>
                    {job.caption && <small>{job.caption}</small>}
                    {job.error_message && <p className="error">{job.error_message}</p>}
                    {job.status === "pending" && job.attempt_count === 0 && <>
                      <label>New local date and time<input type="datetime-local" value={queueDates[job.id] ?? ""}
                        onChange={(event) => setQueueDates((current) => ({ ...current, [job.id]: event.target.value }))} /></label>
                      <button type="button" className="secondary" disabled={queueBusy}
                        onClick={() => void changeQueueJob(job.id, "reschedule")}>Reschedule</button>
                      <button type="button" className="secondary" disabled={queueBusy}
                        onClick={() => void changeQueueJob(job.id, "cancel")}>Cancel draft</button>
                    </>}
                  </div>)}
                  {queueHasMore && <button type="button" className="secondary" disabled={queueBusy}
                    onClick={() => void loadQueue(queue.length)}>Load more</button>}
                </>}
              </section>
              <details className="panel"><summary>YouTube uploads and receipts</summary>
                <span className="kicker">DIRECT YOUTUBE / LOCAL MEDIA</span>
                <h2>Prepare a private YouTube upload</h2>
                <p className="note">Choose one finished local clip and confirm the destination channel. Review uploads no video to TV7 Backend. YouTube may keep uploads private until its API project passes an audit.</p>
                <label>Rendered clip<select value={directClipId} onChange={(event) => {
                  const chosen = readyLibraryClips.find((item) => item.id === event.target.value);
                  setDirectClipId(event.target.value); setDirectReview(null);
                  setDirectTitle(chosen?.clip.post_copy?.youtube_title || chosen?.title || "");
                  setDirectDescription(chosen?.clip.post_copy?.youtube_description || "");
                }}><option value="">Choose a rendered clip</option>
                  {readyLibraryClips.map((item) => <option key={item.id} value={item.id}>{item.title} · {item.clip.start}–{item.clip.end}s</option>)}
                </select></label>
                <label>Destination YouTube channel<select value={directTarget} onChange={(event) => { setDirectTarget(event.target.value); setDirectReview(null); }}>
                  <option value="">Choose a connected channel</option>
                  {directYouTubeTargets.map((target) => <option key={target.account_ref} value={target.account_ref}>{target.display_name} · {target.account_ref}{target.publishing_ready ? " · scheduling ready" : " · private test only"}</option>)}
                </select></label>
                {directTarget && <p className="note">Destination channel ID: <code>{directTarget.slice("youtube:".length)}</code>. Verify this exact account before approving any upload.</p>}
                {!directYouTubeTargets.length && <p className="note">No connected YouTube channel is linked to this creator profile. Connect one in Account first.</p>}
                {directMode === "publish_later" && directTarget && !directYouTubeTargets.find((target) => target.account_ref === directTarget)?.publishing_ready && <p className="note">This channel permits private tests only. Scheduling also requires publishing readiness and Backend audit approval.</p>}
                <label>YouTube title<input maxLength={100} value={directTitle} onChange={(event) => { setDirectTitle(event.target.value); setDirectReview(null); }} /></label>
                <label>Description<textarea maxLength={5000} rows={4} value={directDescription} onChange={(event) => { setDirectDescription(event.target.value); setDirectReview(null); }} /></label>
                <fieldset><legend>Upload intent</legend>
                  <label><input type="radio" name="direct-youtube-mode" checked={directMode === "private_now"} onChange={() => { setDirectMode("private_now"); setDirectReview(null); }} /> Private test upload now</label>
                  <label><input type="radio" name="direct-youtube-mode" checked={directMode === "publish_later"} onChange={() => { setDirectMode("publish_later"); setDirectReview(null); }} /> Private upload with future publish time</label>
                </fieldset>
                {directMode === "publish_later" && <label>Future local publish time<input type="datetime-local" value={directPublishAt} onChange={(event) => { setDirectPublishAt(event.target.value); setDirectReview(null); }} /></label>}
                <button type="button" className="secondary" disabled={!accessToken || !workspaceLoaded || !directYouTubeTargets.length} onClick={prepareDirectYouTubeReview}>Review destination and upload details</button>
                {directError && <p role="alert" className="error">{directError}</p>}
                {directReview && <div className="approval-box" role="status">
                  <strong>Direct upload review</strong>
                  <p>Creator profile: {activeProfile.name}. Source clip: {readyLibraryClips.find((item) => item.id === directReview.clipId)?.title ?? "Local clip"}.</p>
                  <p>Destination: {directReview.destinationName} · YouTube channel ID <code>{directReview.channelId}</code>.</p>
                  <p>Title: {directReview.title}. Description: {directReview.description}.</p>
                  <p>{directReview.mode === "private_now" ? "Private test upload. No public release requested." : `Upload privately, then request YouTube publication at ${new Date(directReview.publishAt!).toLocaleString()}. YouTube audit restrictions may keep it private.`}</p>
                  <label><input type="checkbox" checked={directConfirmed} onChange={(event) => setDirectConfirmed(event.target.checked)} /> I verified that <strong>{directReview.destinationName}</strong> is YouTube channel <code>{directReview.channelId}</code> and approve this upload.</label>
                  <button type="button" className="primary" disabled={!directConfirmed || directBusy || currentDirectReceipt?.status === "verified"} onClick={() => void approveDirectYouTubeUpload()}>{directBusy ? "Uploading and verifying…" : "Approve local direct upload"}</button>
                </div>}
                {readyLibraryClips.length > 0 && <div className="approval-box">
                  <strong>Private test batch</strong>
                  <p>Select rendered clips, review their titles and the exact destination, then approve sequential private uploads. No public release is requested.</p>
                  {readyLibraryClips.map((item) => <label key={item.id}><input type="checkbox" checked={directBatchIncluded[item.id] !== false}
                    onChange={(event) => { setDirectBatchIncluded((current) => ({ ...current, [item.id]: event.target.checked })); setDirectBatch(null); }} /> {item.title} · {item.clip.start}–{item.clip.end}s</label>)}
                  <button type="button" className="secondary" disabled={!accessToken || !directYouTubeTargets.length || directBatchBusy} onClick={prepareDirectPrivateBatch}>Review private batch</button>
                </div>}
                {directBatch && directBatch.reviews[0]?.profileId === activeProfileId && directBatch.ownerEmail === signedInEmail && <div className="approval-box" role="status">
                  <strong>Private batch review · {directBatch.reviews.length} clip{directBatch.reviews.length === 1 ? "" : "s"}</strong>
                  <p>Destination: {directBatch.reviews[0].destinationName} · YouTube channel <code>{directBatch.reviews[0].channelId}</code>. Every item uploads privately.</p>
                  {directBatch.reviews.map((review) => <p key={review.idempotencyKey}>{review.title} · {review.description || "No description"} · {directReceipts.find((receipt) => receipt.review.idempotencyKey === review.idempotencyKey)?.status ?? "awaiting approval"}</p>)}
                  <label><input type="checkbox" checked={directBatchConfirmed} onChange={(event) => setDirectBatchConfirmed(event.target.checked)} /> I verified channel <code>{directBatch.reviews[0].channelId}</code> and approve all {directBatch.reviews.length} private test uploads.</label>
                  <button type="button" className="primary" disabled={!directBatchConfirmed || directBatchBusy || directBusy || directBatch.reviews.every((review) => ["verified", "processing"].includes(directReceipts.find((receipt) => receipt.review.idempotencyKey === review.idempotencyKey)?.status ?? ""))} onClick={() => void approveDirectPrivateBatch()}>{directBatchBusy ? "Uploading private clips…" : "Approve private test batch"}</button>
                </div>}
                {directReceipts.filter((receipt) => receipt.review.profileId === activeProfileId && receipt.ownerEmail === signedInEmail).map((receipt) => <div className="approval-box" role="status" key={receipt.review.idempotencyKey}>
                  <strong>Direct YouTube upload: {receipt.status}</strong>
                  <p>{receipt.review.destinationName} · channel <code>{receipt.review.channelId}</code> · {receipt.review.title}</p>
                  {receipt.uploadId && <p>TV7 receipt: <code>{receipt.uploadId}</code></p>}
                  {receipt.remoteVideoId && <p>YouTube video ID: <code>{receipt.remoteVideoId}</code></p>}
                  {receipt.status === "processing" && <><p>YouTube is processing this video. TV7 will keep the same upload and check again.</p>
                    <button type="button" className="secondary" disabled={directBusy} onClick={() => receipt.uploadId && void verifyDirectUpload(receipt.uploadId, receipt.remoteVideoId)}>Verify processing</button></>}
                  {receipt.status === "verified" && <p>{receipt.review.mode === "private_now" ? "Private test upload verified. It is not a live post." : "Scheduled upload verified by Backend. Confirm publication separately in YouTube."}</p>}
                  {receipt.status === "verified" && receipt.uploadId && <details><summary>Release date · {receipt.review.publishAt ? new Date(receipt.review.publishAt).toLocaleString() : "Private; no release date"}</summary>
                    <label>New YouTube release date<input type="datetime-local" value={directReleaseDates[receipt.uploadId] ?? localDateTime(receipt.review.publishAt ?? new Date(Date.now() + 86400000).toISOString())} onChange={(event) => setDirectReleaseDates((current) => ({ ...current, [receipt.uploadId!]: event.target.value }))} /></label>
                    <button type="button" className="secondary" disabled={directBusy || !directReleaseDates[receipt.uploadId] || !directYouTubeTargets.some((target) => target.account_ref === receipt.review.destinationRef && target.publishing_ready)} onClick={() => void changeYouTubeRelease(receipt.uploadId!)}>Update release date on YouTube</button>
                    {!directYouTubeTargets.some((target) => target.account_ref === receipt.review.destinationRef && target.publishing_ready) && <p className="note">YouTube public release setup is required. Your private upload remains unchanged.</p>}
                  </details>}
                  {receipt.error && <p role="alert" className="error">{receipt.error}</p>}
                  {receipt.status === "error" && <><label><input type="checkbox" checked={Boolean(directRetryConfirmed[receipt.review.idempotencyKey])} onChange={(event) => setDirectRetryConfirmed((current) => ({ ...current, [receipt.review.idempotencyKey]: event.target.checked }))} /> I verified this receipt targets channel <code>{receipt.review.channelId}</code>.</label>
                    <button type="button" className="secondary" disabled={!directRetryConfirmed[receipt.review.idempotencyKey] || directBusy || !directYouTubeTargets.some((target) => target.account_ref === receipt.review.destinationRef)} onClick={() => void approveDirectYouTubeUpload(receipt.review)}>Retry this upload</button></>}
                </div>)}
                {backendDirectUploads.filter((item) => item.creator_profile_id === activeProfileId && !directReceipts.some((receipt) => receipt.uploadId === item.upload_id && receipt.ownerEmail === signedInEmail)).map((item) =>
                  <div className="approval-box" key={item.upload_id}>
                    <strong>Previous YouTube upload: {item.status}</strong>
                    <p>{item.title} · channel <code>{item.target_account_ref.slice("youtube:".length)}</code> · clip <code>{item.local_clip_id}</code></p>
                    <p>TV7 receipt: <code>{item.upload_id}</code>{item.remote_video_id ? <> · YouTube video ID <code>{item.remote_video_id}</code></> : null}</p>
                    {item.scheduled_at && <p>Requested publish time: {new Date(item.scheduled_at).toLocaleString()}</p>}
                    {item.last_error && <p role="alert" className="error">{item.last_error}</p>}
                    {item.status === "processing" && <button type="button" className="secondary" disabled={directBusy} onClick={() => void verifyDirectUpload(item.upload_id, item.remote_video_id ?? undefined)}>Verify processing</button>}
                  </div>)}
              </details>
              {(readyLibraryClips.length > 0 || schedulePlan) && <section className="panel">
                <span className="kicker">REVIEW / SCHEDULE</span>
                <h2>Plan a release queue</h2>
                <p className="note">Plan release dates locally. Upload clips directly to YouTube once; YouTube handles release even when this computer is off.</p>
                {readyLibraryClips.length > 0 && !schedulePlan && <>
                  <div className="video-list">
                    {readyLibraryClips.map(({ id, clip, title }) => <label className="video-row" key={id}>
                      <input type="checkbox" checked={planIncluded[id] !== false}
                        onChange={(event) => setPlanIncluded((current) => ({ ...current, [id]: event.target.checked }))} />
                      <span><strong>{title}</strong><small>{clip.start}–{clip.end} seconds · {clip.burn_subtitles ? "Subtitles on" : "Subtitles off"} · {clip.post_copy?.source === "ai" ? "AI copy ready" : clip.post_copy?.source === "edited" ? "Copy edited" : "Needs post copy"}</small></span>
                    </label>)}
                  </div>
                  <div className="form-row">
                    <label>First local date and time<input type="datetime-local" value={planStart}
                      onChange={(event) => setPlanStart(event.target.value)} /></label>
                    <label>Posting frequency<select value={planCadence} onChange={(event) => setPlanCadence(event.target.value as "normal" | "custom")}><option value="normal">Medium · 2 daily at 12:00 and 19:00</option><option value="custom">Custom · days between clips</option></select></label>
                    {planCadence === "custom" && <label>Days between clips<input type="number" min="1" max="30" value={planSpacing}
                      onChange={(event) => setPlanSpacing(Number(event.target.value))} /></label>}
                  </div>
                  <label>Publish to<select value={planDestination} onChange={(event) => setPlanDestination(event.target.value)}>
                    <option value="all">All connected accounts · same time</option>
                    {publishingTargets.map((target) => <option key={`${target.platform}|${target.account_ref}`} value={`${target.platform}|${target.account_ref}`}>{platformName(target.platform)} · {target.display_name}</option>)}
                  </select></label>
                  {publishingTargets.every((target) => !target.publishing_ready) && <p className="note">No publishing-ready destinations for this profile. Connect accounts in Account. Instagram and TikTok authorization is not available yet.</p>}
                  <p className="note">The plan stays on this computer. YouTube uploads go directly to your channel with a release date; Backend retains connection and receipt metadata.</p>
                  <button type="button" className="secondary" disabled={!workspaceLoaded || !accessToken || !publishingTargets.length} onClick={buildSchedulePlan}>Create review plan</button>
                </>}
                {schedulePlan && <>
                  <p className="note">{schedulePlan.items.length} {schedulePlan.items.length === 1 ? "clip" : "clips"} · {schedulePlan.platform} · {schedulePlan.target} · {new Date(schedulePlan.items[0]!.scheduledAt).toLocaleString()} to {new Date(schedulePlan.items.at(-1)!.scheduledAt).toLocaleString()}</p>
                  {schedulePlan.items.map((item) => {
                    const latest = readyLibraryClips.find((clip) => clip.id === item.jobId)?.clip;
                    const upload = planUpload(item);
                    const scheduled = upload?.status === "scheduled";
                    const destination = publishingTargets.find((target) => target.account_ref === (item.target ?? schedulePlan.target));
                    return <div className="clip-editor" key={item.id}>
                      <h3>{item.title}</h3><span>{platformName(item.platform ?? schedulePlan.platform)} · {destination?.display_name ?? "Connected account"} · {scheduled ? "Scheduled on YouTube" : upload ? upload.status : item.status}{item.draftId ? ` · Backend draft #${item.draftId}` : ""}</span>
                      <label>Requested local date and time<input type="datetime-local" value={scheduled && upload ? directReleaseDates[upload.upload_id] ?? localDateTime(upload.scheduled_at!) : localDateTime(item.scheduledAt)}
                        disabled={directBusy || (schedulePlan.approvalStarted && !scheduled)}
                        onChange={(event) => { if (scheduled && upload) setDirectReleaseDates((current) => ({ ...current, [upload.upload_id]: event.target.value })); else { const date = new Date(event.target.value); if (Number.isFinite(date.getTime())) updatePlanItem(item.id, { scheduledAt: date.toISOString() }); } }} /></label>
                      {scheduled && upload && <><p className="note">Confirmed release: {new Date(upload.scheduled_at!).toLocaleString()} · <a href={`https://studio.youtube.com/video/${upload.remote_video_id}/edit`} target="_blank" rel="noreferrer">View in YouTube Studio</a></p><button type="button" className="secondary" disabled={directBusy || !directReleaseDates[upload.upload_id]} onClick={() => void changeYouTubeRelease(upload.upload_id)}>Update YouTube release date</button></>}
                      <label>Caption preview<textarea rows={3} value={item.caption} disabled={schedulePlan.approvalStarted || scheduled}
                        onChange={(event) => updatePlanItem(item.id, { caption: event.target.value })} /></label>
                      {item.error && <p role="alert" className="error">{item.error}</p>}
                      {item.status === "error" && !item.asset && latest?.output_path && latest.output_path !== item.render.output_path &&
                        <button type="button" className="secondary" disabled={planBusy}
                          onClick={() => updatePlanItem(item.id, { render: { output_path: latest.output_path!,
                            duration_seconds: outputFrames(Number(latest.end)-Number(latest.start),latest.remix_settings?.plan)/30, start_seconds: Number(latest.start),
                            end_seconds: Number(latest.end), caption_text: latest.caption_text }, asset: undefined,
                            clipId: undefined, status: "pending", error: "" })}>Use latest local render</button>}
                    </div>;
                  })}
                  <button type="button" className="primary" disabled={!accessToken || planBusy || schedulePlan.items.every((item) => item.status === "draft_ready" || planUpload(item)?.status === "scheduled")}
                    onClick={() => void (schedulePlan.items.every((item) => (item.platform ?? schedulePlan.platform) === "youtube_shorts") ? approveLocalYouTubePlan() : approveSchedulePlan())}>{schedulePlan.items.every((item) => planUpload(item)?.status === "scheduled") ? "All clips scheduled on YouTube" : planBusy ? "Uploading to YouTube…" : schedulePlan.approvalStarted ? "Retry unfinished items" : "Upload and schedule on connected accounts"}</button>
                  <button type="button" className="secondary" disabled={planBusy}
                    onClick={() => setSchedulePlan(null)}>Archive local plan</button>
                  <p className="note">Archiving removes this local plan only. Scheduled YouTube videos keep their release dates.</p>
                </>}
                {planError && <p role="alert" className="error">{planError}</p>}
                {schedulePlan && directError && <p role="alert" className="error">{directError}</p>}
              </section>}

            </div>
          )}
        </main>
      </div>
      {confirming && (
        <div className="overlay">
          <section
            className="dialog"
            role="dialog"
            aria-modal="true"
            aria-labelledby="confirm-title"
          >
            <span className="kicker">CONFIRM BATCH</span>
            <h2 id="confirm-title">
              Download {selected.length} selected videos?
            </h2>
            <p>
              Engine will download only these titles into its local workspace.
            </p>
            <label>Default clips per video (1–12)
              <input type="number" min="1" max="12" value={clipCount}
                onChange={(event) => setClipCount(Math.max(1, Math.min(12, Number(event.target.value) || 1)))} />
            </label>
            <label><input type="checkbox" checked={batchPostCopy} disabled={!accessToken}
              onChange={(event) => setBatchPostCopy(event.target.checked)} />Generate post copy automatically with DeepSeek</label>
            <p className="note">This sends transcript text and video titles to TV7 cloud AI. Video files stay local. Uses one AI call per clip; captions and rendering also work without AI.</p>
            <ul>
              {selected.map((video) => (
                <li key={video.id}>{video.title}</li>
              ))}
            </ul>
            <div className="dialog-actions">
              <button
                className="secondary"
                onClick={() => setConfirming(false)}
              >
                Back to selection
              </button>
              <button
                className="primary"
                disabled={batchBusy}
                onClick={() => void startBatch()}
              >
                {batchBusy ? "Starting…" : "Confirm download"}
              </button>
            </div>
          </section>
        </div>
      )}
    </div>
  );
}
