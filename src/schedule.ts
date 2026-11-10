/** Keep calendar slots in local time, including across daylight-saving changes. */
export function releaseSlot(start: Date, index: number, cadence: "normal" | "custom", spacing: number): string {
  const date = new Date(start);
  if (cadence === "normal") {
    date.setDate(date.getDate() + Math.floor(index / 2));
    date.setHours(index % 2 === 0 ? 12 : 19, 0, 0, 0);
  } else {
    date.setDate(date.getDate() + index * spacing);
  }
  return date.toISOString();
}

/** Fill future noon/evening slots without moving existing releases. */
export function nextFreeSlots(now: Date, occupied: string[], count: number): string[] {
  const reserved = new Set(occupied.map(value => new Date(value).getTime()).filter(Number.isFinite));
  const slots: string[] = [];
  const day = new Date(now); day.setHours(0, 0, 0, 0);
  while (slots.length < count) {
    for (const hour of [12, 19]) {
      const slot = new Date(day); slot.setHours(hour, 0, 0, 0);
      if (slot.getTime() > now.getTime() && !reserved.has(slot.getTime())) slots.push(slot.toISOString());
      if (slots.length === count) break;
    }
    day.setDate(day.getDate() + 1);
  }
  return slots;
}

/** Deduplicate by content and interleave shuffled source buckets. */
export function shuffledUniqueClips<T>(items: T[], source: (item: T) => string, identity: (item: T) => string, random = Math.random): T[] {
  const buckets = new Map<string, T[]>(); const seen = new Set<string>();
  for (const item of items) { const key = identity(item); if (seen.has(key)) continue; seen.add(key); const group = source(item); buckets.set(group, [...(buckets.get(group) ?? []), item]); }
  const shuffle = <V>(values: V[]) => { for (let i = values.length - 1; i > 0; i--) { const j = Math.floor(random() * (i + 1)); [values[i], values[j]] = [values[j]!, values[i]!]; } return values; };
  for (const bucket of buckets.values()) shuffle(bucket);
  const result: T[] = []; let previous = "";
  while (buckets.size) {
    const sources = shuffle([...buckets.keys()]);
    if (sources.length > 1 && sources[0] === previous) [sources[0], sources[1]] = [sources[1]!, sources[0]!];
    for (const key of sources) { const bucket = buckets.get(key)!; result.push(bucket.shift()!); previous = key; if (!bucket.length) buckets.delete(key); }
  }
  return result;
}
