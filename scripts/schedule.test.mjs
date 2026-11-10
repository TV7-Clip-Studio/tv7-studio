import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import ts from 'typescript';
const source = ts.transpileModule(readFileSync(new URL('../src/schedule.ts', import.meta.url), 'utf8'), { compilerOptions: { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2022 } }).outputText;
const { nextFreeSlots, shuffledUniqueClips } = await import(`data:text/javascript;base64,${Buffer.from(source).toString('base64')}`);
test('smart schedule skips past and occupied slots and fills successive days', () => {
  const now = new Date(2026, 9, 12, 13);
  const occupied = new Date(2026, 9, 12, 19).toISOString();
  const slots = nextFreeSlots(now, [occupied], 3).map(value => new Date(value));
  assert.deepEqual(slots.map(date => [date.getDate(), date.getHours()]), [[13,12],[13,19],[14,12]]);
  assert.deepEqual(nextFreeSlots(now, [], 0), []);
});

test('unique clip ranges are shuffled across source videos', () => {
 const items = [{video:'a',clip:1},{video:'a',clip:2},{video:'b',clip:1},{video:'b',clip:2},{video:'c',clip:1},{video:'a',clip:1}];
 const mixed = shuffledUniqueClips(items, item => item.video, item => `${item.video}:${item.clip}`, () => 0.2);
 assert.equal(mixed.length, 5); assert.equal(new Set(mixed.map(item => `${item.video}:${item.clip}`)).size, 5);
 assert.ok(mixed.slice(1).every((item,index) => item.video !== mixed[index].video));
});
