export type SubtitleStyle = {
  font_size: number; bottom_margin: number; bold: boolean;
  preset?: "clean" | "bold" | "boxed" | "highlight" | "word_box";
  font_name?: string; color?: string; highlight_color?: string; outline?: number; keywords?: string;
};
export const subtitlePresets: { name: string; style: SubtitleStyle }[] = [
  { name: "Word box", style: { preset: "word_box", font_size: 28, bottom_margin: 55, bold: true, outline: 3 } },
  { name: "Clean", style: { preset: "clean", font_size: 22, bottom_margin: 55, bold: false, outline: 1 } },
];
export const defaultSubtitleStyle: SubtitleStyle = { ...subtitlePresets[0]!.style, font_name: "Arial", color: "#FFFFFF", highlight_color: "#D0F26B", keywords: "" };
export function highlightedWords(text: string, keywords = ""): Set<string> {
  const normalize = (word: string) => word.replace(/^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$/gu, "").toLowerCase();
  const specified = keywords.split(",").map(normalize).filter(Boolean);
  if (specified.length) return new Set(specified);
  const longest = text.split(/\s+/).map(normalize).reduce((best, word) => [...word].length >= [...best].length ? word : best, "");
  return new Set([...longest].length >= 5 ? [longest] : []);
}

export type WordCue = { start_seconds: number; end_seconds: number; text: string };
export function wordGroups(cues: WordCue[]): WordCue[][] {
  const groups: WordCue[][] = []; let group: WordCue[] = []; let characters = 0;
  for (const cue of cues) {
    if (group.length && (group.length >= 4 || characters + [...cue.text].length > 32 || cue.start_seconds - group[group.length - 1]!.end_seconds > 0.6)) { groups.push(group); group = []; characters = 0; }
    group.push(cue); characters += [...cue.text].length + 1;
    if (/[.!?]$/.test(cue.text.trimEnd())) { groups.push(group); group = []; characters = 0; }
  }
  if (group.length) groups.push(group);
  return groups;
}

export function normalizeSubtitleStyle(style?: SubtitleStyle): SubtitleStyle {
  return { ...defaultSubtitleStyle, ...style, preset: style?.preset === "clean" ? "clean" : "word_box" };
}

export function withWordTiming<T extends { wordTranscriptPath?: string | null }>(clips: T[], path: string): T[] {
  return clips.map(clip => ({ ...clip, wordTranscriptPath: path }));
}

export const subtitleColors = ["#D0F26B", "#FFD68A", "#A5ECFF", "#FFBDD9", "#DDD0FF"];
export function colorForClip(style: SubtitleStyle | undefined, index: number): SubtitleStyle {
  const normalized = normalizeSubtitleStyle(style);
  const color = subtitleColors[((index % subtitleColors.length) + subtitleColors.length) % subtitleColors.length]!;
  return { ...normalized, color: normalized.preset === "word_box" ? "#FFFFFF" : color, highlight_color: color };
}
