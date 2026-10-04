import { useRef, useState, type PointerEvent, type KeyboardEvent } from "react";

export type TimelineClip = { id: string; start: string; end: string; rendering?: boolean; result?: unknown };
type Range = { start: number; end: number };
type Mode = "move" | "start" | "end";
type Drag = { id: string; mode: Mode; pointerX: number; initial: Range; moved: boolean };

type Props = {
  clips: TimelineClip[];
  duration: number;
  selectedId: string | null;
  playhead: number;
  onSelect: (id: string) => void;
  onSeek: (seconds: number) => void;
  onChange: (id: string, range: Range) => void;
};

const clamp = (value: number, min: number, max: number) => Math.min(max, Math.max(min, value));
const seconds = (value: number) => {
  const whole = Math.floor(value);
  return `${Math.floor(whole / 60)}:${String(whole % 60).padStart(2, "0")}`;
};
const validRange = (clip: TimelineClip, duration: number): Range => {
  const minimum = Math.min(1, duration);
  const start = clamp(Number(clip.start) || 0, 0, duration - minimum);
  return { start, end: clamp(Number(clip.end) || start + minimum, start + minimum, duration) };
};
function movedRange(initial: Range, mode: Mode, delta: number, duration: number): Range {
  const minimum = Math.min(1, duration);
  if (mode === "move") {
    const length = initial.end - initial.start;
    const start = clamp(initial.start + delta, 0, Math.max(0, duration - length));
    return { start, end: start + length };
  }
  if (mode === "start") return { start: clamp(initial.start + delta, 0, initial.end - minimum), end: initial.end };
  return { start: initial.start, end: clamp(initial.end + delta, initial.start + minimum, duration) };
}

export default function MultiClipTimeline({ clips, duration, selectedId, playhead, onSelect, onSeek, onChange }: Props) {
  const track = useRef<HTMLDivElement>(null);
  const drag = useRef<Drag | null>(null);
  const seekFrame = useRef<number | null>(null);
  const pendingSeek = useRef(0);
  const [preview, setPreview] = useState<{ id: string; range: Range } | null>(null);
  const safeDuration = Math.max(0.1, duration);
  const lanes: Record<string, number> = {};
  const laneEnds: number[] = [];
  [...clips].sort((a, b) => Number(a.start) - Number(b.start)).forEach((clip) => {
    const range = validRange(clip, safeDuration);
    let lane = laneEnds.findIndex((end) => range.start >= end);
    if (lane < 0) lane = laneEnds.length;
    laneEnds[lane] = range.end;
    lanes[clip.id] = lane;
  });
  const laneCount = Math.max(2, laneEnds.length);
  const marks = Array.from({ length: 5 }, (_, index) => index * safeDuration / 4);

  function seekAt(clientX: number) {
    const bounds = track.current?.getBoundingClientRect();
    if (bounds) onSeek(clamp((clientX - bounds.left) / bounds.width * safeDuration, 0, safeDuration));
  }
  function previewFrame(secondsToSeek: number) {
    pendingSeek.current = secondsToSeek;
    if (seekFrame.current !== null) return;
    seekFrame.current = requestAnimationFrame(() => {
      seekFrame.current = null;
      onSeek(pendingSeek.current);
    });
  }
  function begin(event: PointerEvent<HTMLButtonElement>, clip: TimelineClip, mode: Mode) {
    event.preventDefault();
    event.stopPropagation();
    event.currentTarget.setPointerCapture(event.pointerId);
    drag.current = { id: clip.id, mode, pointerX: event.clientX, initial: validRange(clip, safeDuration), moved: false };
    onSelect(clip.id);
  }
  function move(event: PointerEvent<HTMLButtonElement>) {
    const current = drag.current;
    const width = track.current?.getBoundingClientRect().width;
    if (!current || !width) return;
    const delta = (event.clientX - current.pointerX) / width * safeDuration;
    if (Math.abs(event.clientX - current.pointerX) > 2) current.moved = true;
    if (current.moved) {
      const range = movedRange(current.initial, current.mode, delta, safeDuration);
      setPreview({ id: current.id, range });
      previewFrame(current.mode === "end" ? range.end : range.start);
    }
  }
  function finish(event: PointerEvent<HTMLButtonElement>, cancelled = false) {
    const current = drag.current;
    if (!current) return;
    if (event.currentTarget.hasPointerCapture(event.pointerId)) event.currentTarget.releasePointerCapture(event.pointerId);
    if (seekFrame.current !== null) { cancelAnimationFrame(seekFrame.current); seekFrame.current = null; }
    if (!cancelled && current.moved) {
      const width = track.current?.getBoundingClientRect().width;
      if (width) {
        const range = movedRange(current.initial, current.mode, (event.clientX - current.pointerX) / width * safeDuration, safeDuration);
        onChange(current.id, range);
        onSeek(current.mode === "end" ? range.end : range.start);
      }
    } else if (!cancelled && current.mode === "move") {
      onSeek(current.initial.start);
    }
    drag.current = null;
    setPreview(null);
  }
  function nudge(event: KeyboardEvent<HTMLButtonElement>, clip: TimelineClip, mode: Mode) {
    if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") return;
    event.preventDefault();
    const amount = (event.shiftKey ? 1 : 0.1) * (event.key === "ArrowRight" ? 1 : -1);
    onSelect(clip.id);
    const range = movedRange(validRange(clip, safeDuration), mode, amount, safeDuration);
    onChange(clip.id, range);
    onSeek(mode === "end" ? range.end : range.start);
  }

  return <div className="multi-timeline" role="region" aria-label="Video clip timeline">
    <div className="timeline-ruler" ref={track} role="slider" tabIndex={0} aria-label="Seek source video" aria-valuemin={0} aria-valuemax={safeDuration} aria-valuenow={clamp(playhead, 0, safeDuration)}
      onPointerDown={(event) => { event.preventDefault(); event.currentTarget.setPointerCapture(event.pointerId); seekAt(event.clientX); }}
      onPointerMove={(event) => { if (event.currentTarget.hasPointerCapture(event.pointerId)) seekAt(event.clientX); }}
      onPointerUp={(event) => { if (event.currentTarget.hasPointerCapture(event.pointerId)) event.currentTarget.releasePointerCapture(event.pointerId); }}
      onKeyDown={(event) => { if (event.key === "ArrowLeft" || event.key === "ArrowRight") { event.preventDefault(); onSeek(clamp(playhead + (event.key === "ArrowRight" ? 1 : -1) * (event.shiftKey ? 5 : 1), 0, safeDuration)); } }}>
      {marks.map((mark, index) => <span key={index} style={{ left: `${index * 25}%` }}>{seconds(mark)}</span>)}
    </div>
    <div className="timeline-lanes" style={{ height: `${laneCount * 36 + 8}px` }} onPointerDown={(event) => { if (event.target === event.currentTarget) seekAt(event.clientX); }}>
      <div className="timeline-playhead" style={{ left: `${clamp(playhead / safeDuration * 100, 0, 100)}%` }} />
      {clips.map((clip, index) => {
        const range = preview?.id === clip.id ? preview.range : validRange(clip, safeDuration);
        const active = clip.id === selectedId;
        return <div key={clip.id} className={`timeline-clip${active ? " selected" : ""}${clip.result ? " ready" : ""}`}
          style={{ left: `${range.start / safeDuration * 100}%`, width: `${(range.end - range.start) / safeDuration * 100}%`, top: `${lanes[clip.id] * 36 + 4}px` }}>
          <button type="button" className="timeline-handle start" aria-label={`Trim start of clip ${index + 1}`} title="Drag to trim start; arrows nudge"
            onPointerDown={(event) => begin(event, clip, "start")} onPointerMove={move} onPointerUp={finish} onPointerCancel={(event) => finish(event, true)} onKeyDown={(event) => nudge(event, clip, "start")} />
          <button type="button" className="timeline-body" aria-label={`Move clip ${index + 1}, ${range.start.toFixed(1)} to ${range.end.toFixed(1)} seconds`}
            aria-pressed={active} title={`Clip ${index + 1}: drag to move; arrows nudge`}
            onPointerDown={(event) => begin(event, clip, "move")} onPointerMove={move} onPointerUp={finish} onPointerCancel={(event) => finish(event, true)} onKeyDown={(event) => nudge(event, clip, "move")}>
            <span>Clip {index + 1}</span><small>{clip.rendering ? "Rendering" : clip.result ? "Ready" : `${(range.end - range.start).toFixed(1)}s`}</small>
          </button>
          <button type="button" className="timeline-handle end" aria-label={`Trim end of clip ${index + 1}`} title="Drag to trim end; arrows nudge"
            onPointerDown={(event) => begin(event, clip, "end")} onPointerMove={move} onPointerUp={finish} onPointerCancel={(event) => finish(event, true)} onKeyDown={(event) => nudge(event, clip, "end")} />
        </div>;
      })}
    </div>
    <p className="timeline-help">Drag a clip to move it; drag its ends to trim. Arrow keys nudge by 0.1s, Shift by 1s.</p>
  </div>;
}
