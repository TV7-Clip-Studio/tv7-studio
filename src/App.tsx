import { useCallback, useEffect, useRef, useState } from "react";
import { invoke, isTauri } from "@tauri-apps/api/core";
import "./App.css";

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
};
type Diagnostics = {
  status?: string;
  capabilities?: { name: string; status: string }[];
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
  start: string;
  end: string;
  captionText: string;
  burnSubtitles: boolean;
  result?: RenderResult;
  error?: string;
  rendering?: boolean;
};
type RenderResult = {
  output_path: string;
  duration_seconds: number;
  media_id?: string;
  start_seconds: number;
  end_seconds: number;
  caption_text: string;
};
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
};
type LicenseReadiness = {
  license_status: string;
  cloud_ai_available: boolean;
  cloud_ai_credits_remaining: number;
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
  caption: string | null;
  attempt_count: number;
};
type PlanItem = {
  id: string;
  jobId: string;
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
type SavedPlan = { ownerEmail: string; platform: string; target: string; items: PlanItem[]; approvalStarted: boolean };
type Page = "overview" | "local" | "channel";
type EngineConnection = { base_url: string; token: string };
const channelStorageKey = "tv7-channel-batch-v1";
const schedulePlanStorageKey = "tv7-channel-schedule-plan-v1";
function loadSchedulePlan(): SavedPlan | null {
  try {
    const saved = JSON.parse(window.localStorage.getItem(schedulePlanStorageKey) ?? "null") as SavedPlan | null;
    return saved && Array.isArray(saved.items) && saved.items.length > 0 ? saved : null;
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
  if (accessToken) headers.set("Authorization", `Bearer ${accessToken}`);
  let response: Response;
  try {
    response = await fetch(backendBase + path, { ...init, headers });
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
  const [page, setPage] = useState<Page>("overview");
  const [connection, setConnection] = useState<EngineConnection>(() =>
    isTauri()
      ? { base_url: "", token: "" }
      : { base_url: browserBase, token: "" },
  );
  const base = connection.base_url;
  const token = connection.token;
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
    metadata?: MediaMetadata;
    probeError?: string;
  } | null>(null);
  const [fileError, setFileError] = useState("");
  const [transcript, setTranscript] = useState<TranscriptImport | null>(null);
  const [transcriptBusy, setTranscriptBusy] = useState(false);
  const [transcriptError, setTranscriptError] = useState("");
  const [candidates, setCandidates] = useState<Candidate[]>([]);
  const [clipCount, setClipCount] = useState(5);
  const [clipDrafts, setClipDrafts] = useState<ClipDraft[]>([]);
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
  const [accessToken, setAccessToken] = useState("");
  const [signedInEmail, setSignedInEmail] = useState("");
  const [youtubeConnection, setYoutubeConnection] =
    useState<YouTubeConnection | null>(null);
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
  const [batchPreview, setBatchPreview] = useState<{ jobId: string; clipId: string; mediaId: string } | null>(null);
  const [batchPreviewUrl, setBatchPreviewUrl] = useState<string | null>(null);
  const [batchPreviewError, setBatchPreviewError] = useState("");
  const startedBatchVideos = useRef(new Set(Object.keys(restoredChannelBatch.videos)));
  const batchQueue = useRef<Promise<void>>(Promise.resolve());
  const [planStart, setPlanStart] = useState(() => {
    const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);
    tomorrow.setHours(9, 0, 0, 0);
    return `${tomorrow.getFullYear()}-${String(tomorrow.getMonth() + 1).padStart(2, "0")}-${String(tomorrow.getDate()).padStart(2, "0")}T09:00`;
  });
  const [planSpacing, setPlanSpacing] = useState(3);
  const [planPlatform, setPlanPlatform] = useState("youtube_shorts");
  const [planTarget, setPlanTarget] = useState("");
  const [planIncluded, setPlanIncluded] = useState<Record<string, boolean>>({});
  const [schedulePlan, setSchedulePlan] = useState<SavedPlan | null>(loadSchedulePlan);
  const [planBusy, setPlanBusy] = useState(false);
  const approvalInFlight = useRef(false);
  const [planError, setPlanError] = useState("");
  const [queue, setQueue] = useState<QueueJob[]>([]);
  const [queueBusy, setQueueBusy] = useState(false);
  const [queueError, setQueueError] = useState("");
  const [queueHasMore, setQueueHasMore] = useState(false);
  const [queueDates, setQueueDates] = useState<Record<number, string>>({});
  const loadQueue = useCallback(async (offset = 0) => {
    if (!accessToken) return;
    setQueueBusy(true);
    setQueueError("");
    try {
      const fetched = await backendRequest<QueueJob[]>(`/api/v1/schedule-jobs?limit=100&offset=${offset}`, accessToken);
      setQueue((current) => offset ? [...current, ...fetched] : fetched);
      setQueueHasMore(fetched.length === 100);
      setQueueDates((current) => ({ ...current, ...Object.fromEntries(fetched.filter((job) => job.scheduled_at).map((job) => [job.id, localDateTime(job.scheduled_at!)])) }));
    } catch (error) { setQueueError(String(error)); }
    finally { setQueueBusy(false); }
  }, [accessToken]);
  useEffect(() => { if (accessToken) queueMicrotask(() => void loadQueue()); }, [accessToken, loadQueue]);
  const selected = Object.values(selection);
  const renderedBatchClips = jobs.flatMap((job) => (batchVideos[job.jobId]?.clips ?? [])
    .filter((clip) => clip.result?.media_id)
    .map((clip) => ({ job, clip })));
  const sourceStreamUrl = !token && fileResult?.media_path && base
    ? `${base}/v1/media/source?path=${encodeURIComponent(fileResult.media_path)}`
    : null;
  const sourceDisplayUrl = sourceStreamUrl ?? sourcePreviewUrl;
  const sourceTooLarge = Boolean(token && (fileResult?.size_bytes ?? 0) > 250 * 1024 * 1024);

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
    if (!batchPreview || !base) return;
    let cancelled = false;
    let objectUrl: string | null = null;
    const headers = new Headers();
    if (token) headers.set("Authorization", `Bearer ${token}`);
    void fetch(`${base}/v1/media/assets/${encodeURIComponent(batchPreview.mediaId)}`, { headers })
      .then(async (response) => {
        if (!response.ok) throw new Error(`Clip preview unavailable: HTTP ${response.status}`);
        const blob = await response.blob();
        if (!cancelled) { objectUrl = URL.createObjectURL(blob); setBatchPreviewUrl(objectUrl); }
      }).catch((error: unknown) => { if (!cancelled) setBatchPreviewError(String(error)); });
    return () => { cancelled = true; if (objectUrl) URL.revokeObjectURL(objectUrl); };
  }, [base, batchPreview, token]);

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
    if (!renderResult?.media_id || !base) return;
    let cancelled = false;
    let objectUrl: string | null = null;
    const headers = new Headers();
    if (token) headers.set("Authorization", `Bearer ${token}`);
    void fetch(
      `${base}/v1/media/assets/${encodeURIComponent(renderResult.media_id)}`,
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
  }, [base, renderResult?.media_id, token]);

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
    setClipDrafts(found.candidates.map((candidate) => ({
      ...candidate,
      id: crypto.randomUUID(),
      start: candidate.start_seconds.toFixed(2),
      end: candidate.end_seconds.toFixed(2),
      captionText: candidate.text,
      burnSubtitles: true,
    })));
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
    ++mediaVersion.current;
    setFileBusy(true);
    setFileError("");
    setSourcePreviewUrl(null);
    setSourcePreviewError("");
    setFileResult(null);
    setTranscript(null);
    setCandidates([]);
    setClipDrafts([]);
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
        setClipStart("0");
        setClipEnd(String(Math.min(30, probe.metadata.duration_seconds ?? 30)));
        void prepareTranscript(result.media_path);
      } catch (error) {
        setFileResult({
          name: file.name,
          ...result,
          probeError: String(error),
        });
        void prepareTranscript(result.media_path);
      }
    } catch (error) {
      setFileError(String(error));
    } finally {
      setFileBusy(false);
    }
  }
  async function openDownloadedJob(job: Job, name: string, sourceUrl?: string, batchVideo?: BatchVideo, selectedResult?: RenderResult) {
    const mediaPath = job.result?.media_path;
    if (job.status !== "succeeded" || !mediaPath) return;
    setFileBusy(true);
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
        metadata: probe.metadata,
      });
      setTranscript(batchVideo?.transcriptPath ? { name: "Channel captions or local transcript", transcript_id: "", transcript_path: batchVideo.transcriptPath, cue_count: 0, duration_seconds: 0 } : null);
      setCandidates(batchVideo?.clips ?? []);
      setClipDrafts(batchVideo?.clips ?? []);
      setSelectedCandidate(null);
      setClipStart("0");
      setClipEnd(String(Math.min(30, probe.metadata.duration_seconds ?? 30)));
      setRenderResult(selectedResult ?? null);
      setAsset(null);
      setCloudClip(null);
      setDraft(null);
      setPage("local");
      if (!batchVideo?.transcriptPath) void prepareTranscript(mediaPath, sourceUrl ?? job.result?.url);
    } catch (error) {
      setDownloadOpenError(String(error));
    } finally {
      setFileBusy(false);
    }
  }
  async function importTranscript(file: File) {
    ++mediaVersion.current;
    setTranscriptBusy(true);
    setTranscriptError("");
    setTranscript(null);
    setCandidates([]);
    setClipDrafts([]);
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
    setClipDrafts((current) => current.map((clip) => clip.id === id ? { ...clip, ...patch } : clip));
    setRenderResult(null);
    setAsset(null); setCloudClip(null); setDraft(null);
  }
  async function renderClip(clip: ClipDraft, context?: { mediaPath: string; duration?: number | null; transcriptPath?: string }): Promise<RenderResult> {
    const mediaPath = context?.mediaPath ?? fileResult?.media_path;
    if (!mediaPath) throw new Error("Import a video first.");
    const start = Number(clip.start);
    const end = Number(clip.end);
    const duration = context ? context.duration : fileResult?.metadata?.duration_seconds;
    if (!Number.isFinite(start) || !Number.isFinite(end) || start < 0 || end <= start)
      throw new Error("End must be after a non-negative start.");
    if (duration != null && end > duration) throw new Error("End exceeds video duration.");
    let subtitlePath = clip.burnSubtitles ? context?.transcriptPath ?? transcript?.transcript_path : undefined;
    if (clip.burnSubtitles && clip.captionText !== clip.text) {
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
    const parent = mediaPath.slice(0, mediaPath.lastIndexOf("/"));
    const response = await request<{ result: RenderResult }>(base, token, "/v1/media/render-clip", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        source_path: mediaPath,
        output_path: `${parent}/clip-${crypto.randomUUID()}.mp4`,
        start_seconds: start,
        end_seconds: end,
        ...(subtitlePath ? { subtitle_path: subtitlePath } : {}),
      }),
    });
    return { ...response.result, start_seconds: start, end_seconds: end, caption_text: clip.captionText };
  }
  async function renderDraft(clip: ClipDraft) {
    updateClip(clip.id, { rendering: true, error: "", result: undefined });
    try {
      const result = await renderClip(clip);
      updateClip(clip.id, { rendering: false, result });
    } catch (error) {
      updateClip(clip.id, { rendering: false, error: String(error) });
    }
  }
  async function renderBatch() {
    setBatchRendering(true);
    for (const clip of clipDrafts) await renderDraft(clip);
    setBatchRendering(false);
  }
  function updateBatchVideo(jobId: string, patch: Partial<BatchVideo>) {
    setBatchVideos((current) => ({ ...current, [jobId]: { ...current[jobId], ...patch } }));
  }
  function updateBatchClip(jobId: string, clipId: string, patch: Partial<ClipDraft>) {
    setBatchVideos((current) => ({
      ...current,
      [jobId]: {
        ...current[jobId],
        clips: current[jobId].clips.map((clip) => clip.id === clipId ? { ...clip, ...patch } : clip),
      },
    }));
  }
  async function renderBatchClip(item: BatchJob, clip: ClipDraft, transcriptPath: string) {
    const mediaPath = item.job?.result?.media_path;
    if (!mediaPath) return;
    updateBatchClip(item.jobId, clip.id, { rendering: true, error: "", result: undefined });
    try {
      const result = await renderClip(clip, { mediaPath, transcriptPath });
      updateBatchClip(item.jobId, clip.id, { rendering: false, result });
    } catch (error) {
      updateBatchClip(item.jobId, clip.id, { rendering: false, error: String(error) });
    }
  }
  async function processBatchVideo(item: BatchJob, count: number) {
    const mediaPath = item.job?.result?.media_path;
    if (!mediaPath) return;
    updateBatchVideo(item.jobId, { status: "Acquiring captions or transcribing locally…", count, clips: [] });
    try {
      const transcriptPath = await acquireTranscript(mediaPath, item.url);
      updateBatchVideo(item.jobId, { status: "Proposing clip ranges…", transcriptPath });
      const found = await request<{ candidates: Candidate[] }>(base, token, "/v1/transcripts/candidates", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ transcript_path: transcriptPath, max_candidates: count }),
      });
      const clips: ClipDraft[] = found.candidates.map((candidate) => ({
        ...candidate, id: crypto.randomUUID(),
        start: candidate.start_seconds.toFixed(2), end: candidate.end_seconds.toFixed(2),
        captionText: candidate.text, burnSubtitles: true,
      }));
      updateBatchVideo(item.jobId, { status: `Rendering ${clips.length} clips locally…`, clips });
      for (const clip of clips) await renderBatchClip(item, clip, transcriptPath);
      updateBatchVideo(item.jobId, { status: "Local batch finished. Review each clip." });
    } catch (error) {
      updateBatchVideo(item.jobId, { status: "Needs attention", error: String(error) });
    }
  }
  async function signIn() {
    setLoginBusy(true);
    setLoginError("");
    try {
      const result = await backendRequest<{ access_token: string }>(
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
        const youtube = await backendRequest<YouTubeConnection>(
          "/api/v1/youtube/connection",
          result.access_token,
        );
        setYoutubeConnection(youtube);
        if (youtube.connected && youtube.channel_id)
          setTargetAccount(`youtube:${youtube.channel_id}`);
        if (youtube.connected && youtube.channel_id)
          setPlanTarget(`youtube:${youtube.channel_id}`);
      } catch {
        setYoutubeConnection(null);
      }
    } catch (error) {
      setLoginError(String(error));
    } finally {
      setLoginBusy(false);
    }
  }
  function signOut() {
    setAccessToken("");
    setSignedInEmail("");
    setYoutubeConnection(null);
    setLicense(null);
    setAsset(null);
    setCloudClip(null);
    setDraft(null);
    setQueue([]);
  }
  function buildSchedulePlan() {
    setPlanError("");
    if (schedulePlan) { setPlanError("Archive the current local plan before creating another. Backend drafts already created by it remain in the queue."); return; }
    const start = new Date(planStart);
    if (!Number.isFinite(start.getTime()) || start.getTime() <= Date.now()) { setPlanError("Choose a future start date and time."); return; }
    if (!Number.isInteger(planSpacing) || planSpacing < 1 || planSpacing > 30) { setPlanError("Spacing must be 1–30 days."); return; }
    const requiredPrefix = `${planPlatform === "youtube_shorts" ? "youtube" : planPlatform}:`;
    if (!planTarget.trim().startsWith(requiredPrefix) || planTarget.trim().length <= requiredPrefix.length) {
      setPlanError(`Target account reference must start with ${requiredPrefix} and include an account ID.`); return;
    }
    const rendered = jobs.flatMap((job) => (batchVideos[job.jobId]?.clips ?? [])
      .filter((clip) => clip.result?.media_id && planIncluded[`${job.jobId}:${clip.id}`] !== false)
      .map((clip) => ({ job, clip })));
    if (!rendered.length) { setPlanError("Select at least one rendered clip."); return; }
    if (rendered.length > 25) { setPlanError("Select at most 25 clips for one schedule plan."); return; }
    const items: PlanItem[] = rendered.map(({ job, clip }, index) => ({
      id: `${job.jobId}:${clip.id}`, jobId: job.jobId, title: `${job.title} · clip ${index + 1}`,
      render: clip.result!, caption: clip.captionText,
      scheduledAt: new Date(start.getTime() + index * planSpacing * 86400000).toISOString(),
      idempotencyKey: crypto.randomUUID(), status: "pending",
    }));
    setSchedulePlan({ ownerEmail: "", platform: planPlatform, target: planTarget.trim(), items, approvalStarted: false });
  }
  function updatePlanItem(id: string, patch: Partial<PlanItem>) {
    setSchedulePlan((current) => current ? { ...current, items: current.items.map((item) => item.id === id ? { ...item, ...patch } : item) } : null);
  }
  async function approveSchedulePlan() {
    if (!schedulePlan || !accessToken || approvalInFlight.current) return;
    if (schedulePlan.ownerEmail && schedulePlan.ownerEmail !== signedInEmail) { setPlanError("Sign in with the account that approved this plan to retry it."); return; }
    if (!schedulePlan.target || !schedulePlan.items.length) return;
    const requiredPrefix = `${schedulePlan.platform === "youtube_shorts" ? "youtube" : schedulePlan.platform}:`;
    if (!schedulePlan.target.startsWith(requiredPrefix) || schedulePlan.target.length <= requiredPrefix.length) {
      setPlanError(`Target account reference must start with ${requiredPrefix} and include an account ID.`); return;
    }
    approvalInFlight.current = true;
    setPlanBusy(true);
    setPlanError("");
    setSchedulePlan((current) => current ? { ...current, ownerEmail: current.ownerEmail || signedInEmail, approvalStarted: true } : null);
    for (const original of schedulePlan.items) {
      if (original.status === "draft_ready") continue;
      let item = original;
      const save = (patch: Partial<PlanItem>) => { item = { ...item, ...patch }; updatePlanItem(item.id, patch); };
      try {
        if (!item.render.media_id) throw new Error("Rendered Engine asset is missing.");
        if (!item.asset) {
          save({ status: "uploading", error: "" });
          const headers = new Headers();
          if (token) headers.set("Authorization", `Bearer ${token}`);
          const response = await fetch(`${base}/v1/media/assets/${encodeURIComponent(item.render.media_id)}`, { headers });
          if (!response.ok) throw new Error(`Engine export unavailable (HTTP ${response.status}). Rerender this clip in Channel batch, then use its latest render in this plan before retrying.`);
          if (!response.headers.get("Content-Type")?.startsWith("video/mp4")) throw new Error("Engine did not return an MP4 clip.");
          const body = new FormData();
          body.append("file", await response.blob(), `tv7-${item.id.replaceAll(":", "-")}.mp4`);
          const uploaded = await backendRequest<BackendAsset>("/api/v1/uploads/assets", accessToken, { method: "POST", body });
          save({ asset: uploaded, status: "asset_ready" });
        }
        if (!item.clipId) {
          const source = jobs.find((job) => job.jobId === item.jobId);
          if (!source) throw new Error("Source video metadata is unavailable.");
          const video = await backendRequest<CloudVideo>("/api/v1/videos/local", accessToken, {
            method: "POST", headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ source_url: `local://${item.jobId}`, title: source.title, original_filename: source.title }),
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
        }
        const draft = await backendRequest<ScheduleDraft>(`/api/v1/clips/${item.clipId}/schedule-drafts`, accessToken, {
          method: "POST", headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ platform: schedulePlan.platform, target_account_ref: schedulePlan.target,
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
      !targetAccount.trim()
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
  return (
    <div className="shell">
      <header className="topbar">
        <div className="brand">
          <b>
            TV<span>7</span>
          </b>
          <small>TV7 STUDIO</small>
        </div>
        <div role="status" className={"connection " + (ready ? "ready" : "")}>
          ● Engine {ready ? "connected" : "unavailable"}
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
          <button
            className={page === "local" ? "active" : ""}
            onClick={() => setPage("local")}
          >
            Local media
          </button>
          <button
            className={page === "channel" ? "active" : ""}
            onClick={() => setPage("channel")}
          >
            Channel batch
          </button>
          <p>
            Media work runs in your local Engine. Full editing and live
            publishing are still in development.
          </p>
        </nav>
        <main>
          {page === "overview" && (
            <>
              <span className="kicker">LOCAL WORKSPACE</span>
              <h1>Make more from your media.</h1>
              <p className="lead">
                A single interface for browser and desktop. Start with a local
                video or discover a channel, then send only what you choose to
                Engine.
              </p>
              <div className="actions">
                <button onClick={() => setPage("local")}>
                  <span className="glyph">↗</span>
                  <strong>Open a local video</strong>
                  <span>Select a file and hand it to Engine.</span>
                  <em>Get started →</em>
                </button>
                <button onClick={() => setPage("channel")}>
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
          {page === "local" && (
            <>
              <span className="kicker">INGEST / 01</span>
              <h1>Local media</h1>
              <p className="lead">
                Choose a file from this computer. It is copied into Engine’s
                local workspace, without sending it to Backend.
              </p>
              <section className="panel">
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
                {fileResult && <div className="clip-editor">
                  <h3>Source preview</h3>
                  {sourceDisplayUrl ? <video ref={sourcePlayer} controls src={sourceDisplayUrl}
                    aria-label="Source video preview" className="clip-preview" /> :
                    <p className="note">Loading source preview…</p>}
                  {sourceTooLarge && <p role="alert" className="error">This source is too large for the desktop preview bridge. Clip rendering remains available.</p>}
                  {sourcePreviewError && <p role="alert" className="error">{sourcePreviewError}</p>}
                </div>}
              </section>
              <section className="panel">
                <span className="kicker">TRANSCRIPT / CLIP</span>
                <h2>Review clip batch</h2>
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
                {transcript && candidates.length === 0 && (
                  <p className="note">
                    No candidate ranges found in this transcript.
                  </p>
                )}
                {clipDrafts.length > 0 && <>
                  <button type="button" className="primary" disabled={batchRendering || !ready}
                    onClick={() => void renderBatch()}>{batchRendering ? "Rendering batch…" : `Render ${clipDrafts.length} clips locally`}</button>
                  <div className="video-list" aria-label="Clip drafts">
                    {clipDrafts.map((clip, index) => <div className="clip-editor" key={clip.id}>
                      <h3>Clip {index + 1}</h3>
                      <label>Caption text
                        <textarea value={clip.captionText} rows={3}
                          onChange={(event) => updateClip(clip.id, { captionText: event.target.value, result: undefined })} />
                      </label>
                      {clip.captionText !== clip.text && <p className="note">Edited text will replace this clip's subtitle cues with one cue spanning its selected time range.</p>}
                      <button type="button" className="secondary" disabled={!sourceDisplayUrl}
                        onClick={() => { if (sourcePlayer.current) { sourcePlayer.current.currentTime = Number(clip.start); sourcePlayer.current.play().catch(() => {}); } }}>
                        Play source from start
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
                      <button type="button" className="secondary" disabled={clip.rendering || batchRendering || !ready}
                        onClick={() => void renderDraft(clip)}>{clip.rendering ? "Rendering…" : clip.result ? "Retry render" : "Render clip"}</button>
                      {clip.error && <p role="alert" className="error">{clip.error}</p>}
                      {clip.result && <div className="result"><span>Rendered locally · {clip.result.duration_seconds.toFixed(1)} seconds</span>
                        <button type="button" className="secondary" onClick={() => { setRenderResult(clip.result ?? null); setAsset(null); setCloudClip(null); setDraft(null); }}>Preview and select for cloud handoff</button></div>}
                    </div>)}
                  </div>
                </>}
                {fileResult && (
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
                  </div>
                )}
                {renderError && (
                  <p role="alert" className="error">
                    {renderError}
                  </p>
                )}
                {renderResult && (
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
              </section>
              {renderResult && (
                <section className="panel">
                  <span className="kicker">OPTIONAL CLOUD HANDOFF</span>
                  <h2>Keep a private scheduling draft</h2>
                  <p className="note">
                    Your render stays on this computer until you approve an
                    upload. The Backend stores an owner-only asset and a
                    schedule draft. A draft is not a live post or a guarantee of
                    future posting.
                  </p>
                  <p className="note">
                    Backend: <code>{backendBase}</code>
                  </p>
                  {!accessToken ? (
                    <form
                      onSubmit={(event) => {
                        event.preventDefault();
                        void signIn();
                      }}
                    >
                      <label htmlFor="account-email">TV7 account email</label>
                      <input
                        id="account-email"
                        type="email"
                        autoComplete="username"
                        required
                        value={accountEmail}
                        onChange={(event) =>
                          setAccountEmail(event.target.value)
                        }
                      />
                      <label htmlFor="account-password">Password</label>
                      <input
                        id="account-password"
                        type="password"
                        autoComplete="current-password"
                        required
                        value={accountPassword}
                        onChange={(event) =>
                          setAccountPassword(event.target.value)
                        }
                      />
                      <button className="secondary" disabled={loginBusy}>
                        {loginBusy ? "Signing in…" : "Sign in for cloud draft"}
                      </button>
                    </form>
                  ) : (
                    <div className="account-row">
                      <span>Signed in as {accountEmail}</span>
                      <button
                        className="secondary"
                        type="button"
                        onClick={signOut}
                      >
                        Sign out
                      </button>
                    </div>
                  )}
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
                      <label htmlFor="target-account">
                        YouTube target reference
                      </label>
                      <input
                        id="target-account"
                        required
                        pattern="youtube:.+"
                        placeholder="youtube:channel-id"
                        value={targetAccount}
                        onChange={(event) =>
                          setTargetAccount(event.target.value)
                        }
                      />
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
                </section>
              )}
              <section className="panel">
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
              </section>
              <p className="note">
                Batch proposals come from transcript timing. A full timeline
                editor and publishing are later integrations.
              </p>
            </>
          )}
          {page === "channel" && (
            <>
              <span className="kicker">INGEST / 02</span>
              <h1>Channel batch</h1>
              <p className="lead">
                Discover a channel, review its videos, and explicitly choose
                which ones Engine may download. Choose only media you have
                rights to use; download failures are shown per job.
              </p>
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
                      disabled={!ready || discoverBusy}
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
                  {jobs.map((item) => (
                    <div className="job" key={item.jobId}>
                      <strong>{item.title}</strong>
                      <span>{jobStatus(item.job)}</span>
                      {item.job?.error && <small>{item.job.error}</small>}
                      {batchVideos[item.jobId] && <>
                        <span>{batchVideos[item.jobId].status}</span>
                        {batchVideos[item.jobId].error && <p role="alert" className="error">{batchVideos[item.jobId].error}</p>}
                        <label>Clips for this video (1–12)
                          <input type="number" min="1" max="12" value={batchVideos[item.jobId].count}
                            onChange={(event) => updateBatchVideo(item.jobId, { count: Math.max(1, Math.min(12, Number(event.target.value) || 1)) })} />
                        </label>
                        {item.job?.result?.media_path && <button type="button" className="secondary"
                          onClick={() => { batchQueue.current = batchQueue.current.then(() => processBatchVideo(item, batchVideos[item.jobId].count)); }}>
                          Retry or regenerate this video
                        </button>}
                        {batchVideos[item.jobId].clips.map((clip, index) => <div className="clip-editor" key={clip.id}>
                          <h3>Clip {index + 1} · {clip.rendering ? "Rendering…" : clip.result ? "Rendered" : clip.error ? "Needs retry" : "Queued"}</h3>
                          <label>Caption text<textarea rows={3} value={clip.captionText}
                            onChange={(event) => updateBatchClip(item.jobId, clip.id, { captionText: event.target.value, result: undefined })} /></label>
                          <div className="form-row">
                            <label>Start (seconds)<input type="number" min="0" step="0.01" value={clip.start}
                              onChange={(event) => updateBatchClip(item.jobId, clip.id, { start: event.target.value, result: undefined })} /></label>
                            <label>End (seconds)<input type="number" min="0" step="0.01" value={clip.end}
                              onChange={(event) => updateBatchClip(item.jobId, clip.id, { end: event.target.value, result: undefined })} /></label>
                          </div>
                          <label className="checkbox"><input type="checkbox" checked={clip.burnSubtitles}
                            onChange={(event) => updateBatchClip(item.jobId, clip.id, { burnSubtitles: event.target.checked, result: undefined })} /> Burn subtitles</label>
                          {clip.captionText !== clip.text && <p className="note">Edited caption text uses one cue across this clip.</p>}
                          {clip.error && <p role="alert" className="error">{clip.error}</p>}
                          <button type="button" className="secondary" disabled={clip.rendering || !batchVideos[item.jobId].transcriptPath}
                            onClick={() => void renderBatchClip(item, clip, batchVideos[item.jobId].transcriptPath!)}>
                            {clip.result ? "Retry render" : "Render clip"}</button>
                          {clip.result && <>
                            <span>Local render: {clip.result.duration_seconds.toFixed(1)} seconds</span>
                            {clip.result.media_id && <button type="button" className="secondary"
                              onClick={() => { setBatchPreviewUrl(null); setBatchPreviewError(""); setBatchPreview({ jobId: item.jobId, clipId: clip.id, mediaId: clip.result!.media_id! }); }}>Preview clip</button>}
                            <button type="button" className="secondary" disabled={fileBusy}
                              onClick={() => void openDownloadedJob(item.job!, item.title, item.url, batchVideos[item.jobId], clip.result)}>
                              Open for explicit cloud handoff</button>
                          </>}
                          {batchPreview?.jobId === item.jobId && batchPreview.clipId === clip.id && <>
                            {batchPreviewUrl ? <video controls src={batchPreviewUrl} className="clip-preview" aria-label={`${item.title} clip ${index + 1} preview`} /> : <span>Loading preview…</span>}
                            {batchPreviewError && <p role="alert" className="error">{batchPreviewError}</p>}
                          </>}
                        </div>)}
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
              <section className="panel">
                <span className="kicker">REVIEW / SCHEDULE</span>
                <h2>Plan a channel release queue</h2>
                <p className="note">Choose rendered clips, review dates and captions, then explicitly approve private uploads and Backend schedule drafts. A draft is not a live post.</p>
                {renderedBatchClips.length > 0 && !schedulePlan && <>
                  <div className="video-list">
                    {renderedBatchClips.map(({ job, clip }) => <label className="video-row" key={`${job.jobId}:${clip.id}`}>
                      <input type="checkbox" checked={planIncluded[`${job.jobId}:${clip.id}`] !== false}
                        onChange={(event) => setPlanIncluded((current) => ({ ...current, [`${job.jobId}:${clip.id}`]: event.target.checked }))} />
                      <span><strong>{job.title}</strong><small>{clip.start}–{clip.end} seconds · {clip.captionText}</small></span>
                    </label>)}
                  </div>
                  <div className="form-row">
                    <label>First local date and time<input type="datetime-local" value={planStart}
                      onChange={(event) => setPlanStart(event.target.value)} /></label>
                    <label>Days between clips<input type="number" min="1" max="30" value={planSpacing}
                      onChange={(event) => setPlanSpacing(Number(event.target.value))} /></label>
                  </div>
                  <div className="form-row">
                    <label>Platform<select value={planPlatform} onChange={(event) => setPlanPlatform(event.target.value)}>
                      <option value="youtube_shorts">YouTube Shorts (draft only)</option><option value="tiktok">TikTok (draft only)</option><option value="instagram">Instagram (draft only)</option>
                    </select></label>
                    <label>Target account reference<input value={planTarget} placeholder="youtube:channel-id"
                      onChange={(event) => setPlanTarget(event.target.value)} /></label>
                  </div>
                  <p className="note">All platforms create drafts only here. Live publishing requires a connected account and an enabled Backend adapter.</p>
                  <button type="button" className="secondary" onClick={buildSchedulePlan}>Create review plan</button>
                </>}
                {schedulePlan && <>
                  <p className="note">{schedulePlan.items.length} clips · {schedulePlan.platform} · {schedulePlan.target} · {new Date(schedulePlan.items[0]!.scheduledAt).toLocaleString()} to {new Date(schedulePlan.items.at(-1)!.scheduledAt).toLocaleString()}</p>
                  {schedulePlan.items.map((item) => {
                    const latest = batchVideos[item.jobId]?.clips.find((clip) => `${item.jobId}:${clip.id}` === item.id)?.result;
                    return <div className="clip-editor" key={item.id}>
                      <h3>{item.title}</h3><span>{item.status}{item.draftId ? ` · Backend draft #${item.draftId}` : ""}</span>
                      <label>Requested local date and time<input type="datetime-local" value={localDateTime(item.scheduledAt)}
                        disabled={schedulePlan.approvalStarted}
                        onChange={(event) => { const date = new Date(event.target.value); if (Number.isFinite(date.getTime())) updatePlanItem(item.id, { scheduledAt: date.toISOString() }); }} /></label>
                      <label>Caption preview<textarea rows={3} value={item.caption} disabled={schedulePlan.approvalStarted}
                        onChange={(event) => updatePlanItem(item.id, { caption: event.target.value })} /></label>
                      {item.error && <p role="alert" className="error">{item.error}</p>}
                      {item.status === "error" && !item.asset && latest?.media_id && latest.media_id !== item.render.media_id &&
                        <button type="button" className="secondary" disabled={planBusy}
                          onClick={() => updatePlanItem(item.id, { render: latest, status: "pending", error: "" })}>Use latest local render</button>}
                    </div>;
                  })}
                  <button type="button" className="primary" disabled={!accessToken || planBusy || schedulePlan.items.every((item) => item.status === "draft_ready")}
                    onClick={() => void approveSchedulePlan()}>{planBusy ? "Creating drafts…" : schedulePlan.approvalStarted ? "Retry unfinished items" : "Approve private uploads and schedule drafts"}</button>
                  <button type="button" className="secondary" disabled={planBusy}
                    onClick={() => setSchedulePlan(null)}>Archive local plan</button>
                  <p className="note">Archiving removes this local plan only. Any Backend drafts already created remain in the account queue.</p>
                </>}
                {planError && <p role="alert" className="error">{planError}</p>}
              </section>
              <section className="panel">
                <span className="kicker">ACCOUNT / BACKEND</span>
                <h2>Schedule queue</h2>
                <p className="note">Backend draft status is authoritative. Pending drafts can be rescheduled or cancelled before any publish attempt; no live post is initiated here.</p>
                {!accessToken ? <form onSubmit={(event) => { event.preventDefault(); void signIn(); }}>
                  <label>TV7 account email<input type="email" required autoComplete="username" value={accountEmail}
                    onChange={(event) => setAccountEmail(event.target.value)} /></label>
                  <label>Password<input type="password" required autoComplete="current-password" value={accountPassword}
                    onChange={(event) => setAccountPassword(event.target.value)} /></label>
                  <button className="secondary" disabled={loginBusy}>{loginBusy ? "Signing in…" : "Sign in to view queue"}</button>
                </form> : <div className="account-row"><span>Signed in as {signedInEmail}</span><button className="secondary" onClick={signOut}>Sign out</button></div>}
                {loginError && <p role="alert" className="error">{loginError}</p>}
                {accessToken && youtubeConnection && <p className="note">YouTube account: {youtubeConnection.connected ? youtubeConnection.channel_title ?? youtubeConnection.channel_id : "not connected"}.</p>}
                {accessToken && <>
                  <button type="button" className="secondary" disabled={queueBusy} onClick={() => void loadQueue()}>Refresh queue</button>
                  {queueError && <p role="alert" className="error">{queueError}</p>}
                  {queue.length === 0 && !queueBusy && <p className="note">No Backend schedule jobs in this account.</p>}
                  {queue.map((job) => <div className="job" key={job.id}>
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
            </>
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
