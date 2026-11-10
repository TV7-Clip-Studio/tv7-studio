import { defaultSubtitleStyle, subtitlePresets, type SubtitleStyle } from "../subtitles";

export default function SubtitleControls({ value, onChange, onSaveDefault, isProfileDefault }: { value: SubtitleStyle; onChange: (value: SubtitleStyle) => void; onSaveDefault: () => void; isProfileDefault: boolean }) {
  const style = { ...defaultSubtitleStyle, ...value, preset: value.preset === "word_box" ? "word_box" as const : "clean" as const };
  const matchingPreset = subtitlePresets.find((preset) => preset.style.preset === style.preset);
  const change = (patch: Partial<SubtitleStyle>) => onChange({ ...style, ...patch });
  return <fieldset className="subtitle-controls"><legend>Subtitle style · {matchingPreset?.name ?? "Custom"}</legend>
    <div className="subtitle-presets" role="group" aria-label="Subtitle presets">{subtitlePresets.map((preset) => <button type="button" key={preset.name} className={matchingPreset?.name === preset.name ? "active" : "secondary"} aria-pressed={matchingPreset?.name === preset.name} onClick={() => onChange({ ...style, ...preset.style })}>{preset.name}</button>)}</div>
    <details><summary>Font, colors and placement</summary><div className="form-row">
      <label>Font<select value={style.font_name} onChange={(e) => change({ font_name: e.target.value })}>{["Arial", "Verdana", "DejaVu Sans"].map((font) => <option key={font}>{font}</option>)}</select></label>
      <label>Size<select value={style.font_size} onChange={(e) => change({ font_size: Number(e.target.value) })}>{[18, 22, 28, 34, 40].map((size) => <option key={size} value={size}>{size}</option>)}</select></label>
      <label>Placement<select value={style.bottom_margin} onChange={(e) => change({ bottom_margin: Number(e.target.value) })}><option value="20">Lower</option><option value="32">Safe area</option><option value="55">Higher</option><option value="80">Near center</option></select></label>
      <label>Text color<input type="color" value={style.color} onChange={(e) => change({ color: e.target.value })} /></label>
      {style.preset === "word_box" && <label>Highlight color<input type="color" value={style.highlight_color} onChange={(e) => change({ highlight_color: e.target.value })} /></label>}
      <label>Outline<select value={style.outline} onChange={(e) => change({ outline: Number(e.target.value) })}>{[0, 1, 2, 3, 4, 5].map((size) => <option key={size} value={size}>{size === 0 ? "None" : size}</option>)}</select></label>
      <label className="checkbox"><input type="checkbox" checked={style.bold} onChange={(e) => change({ bold: e.target.checked })} />Bold</label>
    </div></details>
    <button type="button" className="secondary" onClick={onSaveDefault} disabled={isProfileDefault}>{isProfileDefault ? "Saved as profile default" : "Save as profile default"}</button>
    <p className="note">Preview updates before rendering. Installed fonts may vary; check the finished render.</p>
  </fieldset>;
}
