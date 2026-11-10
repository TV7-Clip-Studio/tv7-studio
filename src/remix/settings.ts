import type {RemixPlan} from './plan';
import type {Treatment, Word} from './model';
export type RemixSettings = {
  treatment: Treatment;
  plan?: RemixPlan;
  palette?: 'yellow'|'cyan'|'pink'|'lime'|'orange';
  artPack?: 'none' | 'comic' | 'collage' | 'neon' | 'psychedelic' | 'minimal';
  artIntensity?: number;
  stickerSize?: number;
  stickerDensity?: 'off' | 'sparse' | 'normal';
  effect: 'none' | 'impact' | 'glitch' | 'shockwave' | 'freeze' | 'whip';
  intensity: number;
  frequency: 'sparse' | 'medium' | 'frequent';
  durationMs: number;
  breathingRoom?: number;
  background: 'blur' | 'tunnel' | 'kaleidoscope';
  backgroundIntensity: number;
  sound: 'none' | 'impact' | 'digital' | 'sweep';
  soundVolume: number;
  dialogueVolume: number;
};
export function defaultRemixSettings(treatment:Treatment='comedy'):RemixSettings {
  return {treatment,artPack:'none',artIntensity:50,stickerSize:50,stickerDensity:'sparse',effect:'none',intensity:40,frequency:'sparse',durationMs:300,breathingRoom:3,background:'blur',backgroundIntensity:30,sound:'none',soundVolume:20,dialogueVolume:100};
}
export function effectBeats(words:Word[],start:number,duration:number,frequency:RemixSettings['frequency'],breathingRoom=3):number[] {
  const gap=Math.max({sparse:4,medium:2.5,frequent:1.5}[frequency],breathingRoom+0.8);
  const beats:number[]=[];
  for (let i=0;i<words.length;i++) {
    const time=words[i].start_seconds-start;
    if(time<1||time>duration-1.8)continue;
    if(beats.length===0 || (i>0&&/[.!?…]$/.test(words[i-1].text)&&time-beats.at(-1)!>=gap))beats.push(time);
  }
  return beats;
}
export function effectAt(time:number,beats:number[],settings:RemixSettings) {
  const last=beats.findLast(beat=>beat<=time);
  const elapsed=last===undefined?Infinity:time-last;
  const length=settings.durationMs/1000;
  const envelope=elapsed<length?Math.sin(Math.PI*elapsed/length):0;
  const backgroundEnvelope=elapsed<0.8-1e-9?Math.min(1,elapsed/0.12,(0.8-elapsed)/0.18):0;
  return {elapsed, strength:settings.intensity/100*envelope,backgroundEnvelope};
}
export const effectPresets = {
  impact:{label:'Impact comedy',patch:{treatment:'comedy',effect:'impact',intensity:55,frequency:'medium',background:'blur',sound:'impact',soundVolume:20}},
  glitch:{label:'Glitch broadcast',patch:{treatment:'retro',effect:'glitch',intensity:45,frequency:'medium',background:'blur',sound:'digital',soundVolume:15}},
  vj:{label:'Psychedelic VJ',patch:{treatment:'comedy',effect:'shockwave',intensity:35,frequency:'sparse',background:'kaleidoscope',backgroundIntensity:40,sound:'sweep',soundVolume:12}},
} satisfies Record<string,{label:string;patch:Partial<RemixSettings>}>;

/** Reserve headroom for accents and AAC reconstruction peaks; never boost quiet dialogue. */
export function mixGains(settings:RemixSettings,sourcePeak:number) {
  const ceiling=settings.sound==='none'?0.82:0.7;
  return {dialogue:settings.dialogueVolume/100*Math.min(1,ceiling/Math.max(sourcePeak,0.001)),effects:settings.soundVolume/100*0.18};
}
