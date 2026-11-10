import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import ts from 'typescript';
const source = ts.transpileModule(readFileSync(new URL('../src/subtitles.ts', import.meta.url), 'utf8'), { compilerOptions: { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2022 } }).outputText;
const { highlightedWords, wordGroups, normalizeSubtitleStyle, subtitlePresets, withWordTiming, colorForClip, subtitleColors } = await import(`data:text/javascript;base64,${Buffer.from(source).toString('base64')}`);
test('keyword emphasis handles punctuation, accents and explicit word choices', () => {
  assert.deepEqual([...highlightedWords('¡Papá Noël! contrato chimeneas', ' PAPÁ, contrato ')], ['papá', 'contrato']);
  assert.deepEqual([...highlightedWords('cinco largo')], ['largo']);
  assert.equal(highlightedWords('yo ya sé').size, 0);
});

test('word boxes keep original timings while grouping phrases and pauses', () => {
  const cue = (text, start, end) => ({ text, start_seconds: start, end_seconds: end });
  const words = [cue('Bueno,', 45.05, 45.86), cue('fue', 45.86, 46.23), cue('el', 46.23, 46.48), cue('rulo. ', 46.48, 47.37), cue('Otro', 48.4, 49), cue('día.', 49, 49.6)];
  const groups = wordGroups(words);
  assert.deepEqual(groups.map(group => group.map(word => word.text)), [['Bueno,', 'fue', 'el', 'rulo. '], ['Otro', 'día.']]);
  assert.deepEqual(groups.flat(), words);
  assert.equal(groups[0][1].end_seconds - groups[0][1].start_seconds > 0.36, true);
});

test('only Word box and Clean are offered; legacy styles normalize without losing preferences', () => {
  assert.deepEqual(subtitlePresets.map(item => item.style.preset), ['word_box', 'clean']);
  for (const preset of ['bold', 'boxed', 'highlight']) {
    const result = normalizeSubtitleStyle({ preset, font_size: 34, bottom_margin: 80, bold: true });
    assert.equal(result.preset, 'word_box'); assert.equal(result.font_size, 34);
  }
  assert.equal(normalizeSubtitleStyle({ preset: 'word_box' }).preset, 'word_box');
});

test('timing propagation updates every batch clip without discarding renders or copy', () => {
  const clips = [{ id: 'one', wordTranscriptPath: null, postCopy: { youtube_description: 'Written' } }, { id: 'two', wordTranscriptPath: null, result: { output_path: 'clip.mp4' } }];
  const saved = withWordTiming(clips, 'source-words.vtt');
  assert.deepEqual(saved.map(clip => clip.wordTranscriptPath), ['source-words.vtt', 'source-words.vtt']);
  assert.equal(saved[0].postCopy, clips[0].postCopy);
  assert.equal(saved[1].result, clips[1].result);
  assert.equal(clips[0].wordTranscriptPath, null);
});

test('clip palettes vary while retaining typography and readable word box text', () => {
  const styles = subtitleColors.map((_, index) => colorForClip({ preset: 'word_box', font_size: 34, bottom_margin: 70, bold: true }, index));
  assert.equal(new Set(styles.map(style => style.highlight_color)).size, subtitleColors.length);
  assert.ok(styles.every(style => style.color === '#FFFFFF' && style.font_size === 34 && style.bottom_margin === 70));
  assert.equal(colorForClip({ preset: "clean" }, subtitleColors.length).color, subtitleColors[0]);
});

test("new subtitle styles default to Word box; explicit Clean stays Clean", () => { assert.equal(normalizeSubtitleStyle().preset, "word_box"); assert.equal(normalizeSubtitleStyle({ preset: "clean" }).preset, "clean"); });
