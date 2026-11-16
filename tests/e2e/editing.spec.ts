import { expect, test, type Page } from "@playwright/test";
import { join } from "node:path";

const fixtures = process.env.TV7_E2E_DIR!;
const transcript = {
  name: "fixture.vtt",
  mimeType: "text/vtt",
  buffer: Buffer.from("WEBVTT\n\n00:00:00.500 --> 00:00:07.000\nFirst scene.\n\n00:00:07.100 --> 00:00:14.000\nSecond scene.\n"),
};

async function renderClip(page: Page) {
  const tools = page.locator("details.workspace-tools").first();
  await tools.locator("summary").click();
  await page.getByLabel("Import a WebVTT transcript instead").setInputFiles(transcript);
  await expect(page.getByText("Transcript ready:", { exact: false })).toBeVisible();
  const editor = page.getByText("Edit clip · timing, subtitles and framing", { exact: true });
  if (await editor.count() && !(await page.getByLabel("Burn subtitles").isVisible())) {
    await editor.click();
  }
  await page.getByLabel("Burn subtitles").uncheck();
  await page.getByRole("spinbutton", { name: "Start (seconds)", exact: true }).fill("1");
  await page.getByRole("spinbutton", { name: "End (seconds)", exact: true }).fill("5");
  await page.getByRole("button", { name: "Render clip", exact: true }).click();
  await expect(page.getByLabel("Selected rendered clip preview")).toBeVisible();
  const preview = page.getByLabel("Selected rendered clip preview");
  await expect.poll(() => preview.evaluate((video: HTMLVideoElement) => video.duration)).toBeCloseTo(4, 1);
}

test.beforeEach(async ({ page }) => {
  await page.route("http://127.0.0.1:18000/**", route => route.abort());
  await page.goto("/");
  await expect(page.getByText("Engine connected")).toBeVisible();
  await page.getByRole("button", { name: "Ingest", exact: true }).click();
});

test("import, edit, preview, and reopen a saved clip", async ({ page }) => {
  await page.locator('input[type="file"][accept*="video"]').setInputFiles(join(fixtures, "local-fixture.mp4"));
  await expect(page.getByRole("heading", { name: "Clip editor" })).toBeVisible();
  await renderClip(page);
  await page.getByRole("button", { name: "Library", exact: true }).click();
  await expect(page.getByRole("button", { name: /^local-fixture\.mp4 .*1 clip/ })).toBeVisible();
  await page.reload();
  await page.getByRole("button", { name: "Library", exact: true }).click();
  const project = page.getByRole("button", { name: /^local-fixture\.mp4 .*1 clip/ });
  await project.click();
  await expect(page.getByLabel("Selected rendered clip preview")).toBeVisible();
});

test("discover and ingest a selected channel video and find its render in Schedule", async ({ page }) => {
  await page.getByLabel("Channel URL").fill("https://www.youtube.com/@fixture");
  await page.getByRole("button", { name: "Discover videos" }).click();
  await page.getByRole("checkbox", { name: /Channel fixture/ }).check();
  await page.getByRole("button", { name: "Review selected (1)" }).click();
  await page.getByRole("button", { name: "Confirm download" }).click();
  await page.getByRole("button", { name: "Open in clip workspace" }).click();
  await renderClip(page);
  await page.getByRole("button", { name: "Schedule", exact: true }).click();
  await page.getByText("YouTube uploads and receipts", { exact: true }).click();
  await expect(page.getByLabel("Rendered clip").locator("option").filter({ hasText: /Channel fixture/ }).first()).toBeAttached();
  await expect(page.getByRole("button", { name: "Approve local direct upload" })).toHaveCount(0);
});
