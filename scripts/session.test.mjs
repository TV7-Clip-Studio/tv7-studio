import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import ts from 'typescript';

const source = ts.transpileModule(readFileSync(new URL('../src/session.ts', import.meta.url), 'utf8'), { compilerOptions: { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2022 } }).outputText;
const access = (exp) => `header.${Buffer.from(JSON.stringify({ exp })).toString('base64url')}.signature`;
let instance = 0;
async function setup(saved) {
  const data = new Map(saved ? [['tv7-account-session-v1', JSON.stringify(saved)]] : []);
  globalThis.localStorage = { getItem: (key) => data.get(key) ?? null, setItem: (key, value) => data.set(key, value), removeItem: (key) => data.delete(key) };
  globalThis.window = new EventTarget();
  const module = await import(`data:text/javascript;base64,${Buffer.from(source).toString('base64')}#${instance++}`);
  return { module, data };
}
const expired = { accessToken: access(1), refreshToken: 'test-refresh', email: 'test@example.com' };

test('restore login and coalesce simultaneous renewal requests', async () => {
  const { module, data } = await setup(expired);
  assert.deepEqual(module.accountSession(), expired);
  let calls = 0;
  const next = access(Math.floor(Date.now() / 1000) + 1800);
  globalThis.fetch = async () => { calls++; return new Response(JSON.stringify({ access_token: next, refresh_token: 'new-refresh' })); };
  const results = await Promise.all([module.sessionToken('http://backend', expired.accessToken), module.sessionToken('http://backend', expired.accessToken)]);
  assert.deepEqual(results, [next, next]);
  assert.equal(calls, 1);
  assert.equal(JSON.parse(data.get('tv7-account-session-v1')).refreshToken, 'new-refresh');
  const reload = await setup(module.accountSession());
  assert.equal(reload.module.accountSession().accessToken, next);
});

test('temporary network failure preserves session; rejected refresh removes it', async () => {
  const { module, data } = await setup(expired);
  globalThis.fetch = async () => { throw new Error('offline'); };
  await assert.rejects(module.sessionToken('http://backend', expired.accessToken));
  assert.deepEqual(module.accountSession(), expired);
  globalThis.fetch = async () => new Response('{}', { status: 401 });
  await assert.rejects(module.sessionToken('http://backend', expired.accessToken));
  assert.equal(module.accountSession(), null);
  assert.equal(data.size, 0);
});

test('logout during renewal cannot restore earlier account', async () => {
  const { module } = await setup(expired);
  let complete;
  globalThis.fetch = () => new Promise((resolve) => { complete = resolve; });
  const pending = module.sessionToken('http://backend', expired.accessToken);
  module.saveSession(null);
  complete(new Response(JSON.stringify({ access_token: access(9999999999), refresh_token: 'new' })));
  await assert.rejects(pending, /session changed/);
  assert.equal(module.accountSession(), null);
});
