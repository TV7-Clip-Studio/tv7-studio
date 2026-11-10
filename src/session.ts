export type AccountSession = { accessToken: string; refreshToken: string; email: string };
const storageKey = "tv7-account-session-v1";
export const sessionChanged = "tv7-session-changed";

function readSession(): AccountSession | null {
  try {
    const value = JSON.parse(localStorage.getItem(storageKey) ?? "null");
    return value && typeof value.accessToken === "string" && typeof value.refreshToken === "string" && typeof value.email === "string" ? value : null;
  } catch { return null; }
}

let session = readSession();
let refreshing: Promise<string> | null = null;
const tokens = new Set(session ? [session.accessToken] : []);
export function accountSession() { return session; }
export function saveSession(value: AccountSession | null) {
  if (!value && !session) return;
  session = value;
  refreshing = null;
  tokens.clear();
  if (value) tokens.add(value.accessToken);
  try {
    if (value) localStorage.setItem(storageKey, JSON.stringify(value));
    else localStorage.removeItem(storageKey);
  } catch { /* In-memory login still works when storage is unavailable. */ }
  window.dispatchEvent(new CustomEvent(sessionChanged, { detail: value }));
}

// Only tokens belonging to this login may be renewed; logout and account switches
// cannot resurrect an earlier session when an outstanding request finishes.
export async function sessionToken(base: string, token: string, force = false): Promise<string> {
  if (!session || !tokens.has(token)) return token;
  if (refreshing) return refreshing;
  if (!force) {
    try {
      const payload = JSON.parse(atob(session.accessToken.split(".")[1].replace(/-/g, "+").replace(/_/g, "/")));
      if (payload.exp * 1000 > Date.now() + 60_000) return session.accessToken;
    } catch { /* Let Backend validate and renew opaque or malformed tokens. */ }
  }
  const previous = session;
  const task = (async () => {
    const response = await fetch(base + "/api/v1/auth/refresh", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refresh_token: previous.refreshToken }),
    });
    if (session !== previous) throw new Error("Account session changed.");
    if (response.status === 401) {
      saveSession(null);
      window.dispatchEvent(new CustomEvent("tv7-session-expired", { detail: previous.accessToken }));
      throw new Error("Your TV7 session expired. Sign in again.");
    }
    if (!response.ok) throw new Error("Cannot renew TV7 session. Try again when Backend is available.");
    const data = await response.json();
    if (session !== previous) throw new Error("Account session changed.");
    if (typeof data.access_token !== "string" || typeof data.refresh_token !== "string") throw new Error("Backend returned an incomplete session.");
    const knownTokens = [...tokens];
    saveSession({ ...previous, accessToken: data.access_token, refreshToken: data.refresh_token });
    knownTokens.forEach((known) => tokens.add(known));
    return data.access_token as string;
  })();
  refreshing = task;
  try { return await task; }
  finally { if (refreshing === task) refreshing = null; }
}
