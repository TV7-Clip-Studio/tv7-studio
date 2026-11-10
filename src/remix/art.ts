import type {Word} from './model';
import type {RemixSettings} from './settings';
export const artPacks={none:'Original layout',comic:'Comic chaos',collage:'Cutout collage',neon:'Neon broadcast',psychedelic:'Psychedelic',minimal:'Minimal punch'};
const meanings=[
 {pattern:/\b(futbol|equipo|campeon|gimnasia|gol)\b/,emoji:'⚽',label:'¿SALE CAMPEÓN?'},
 {pattern:/\b(regalo|navidad|papa noel|santa)\b/,emoji:'🎁',label:'REGALO ESPECIAL'},
 {pattern:/\b(asado|chorio|chorizo|empanada|sushi)\b/,emoji:'🍽️',label:'BUEN PROVECHO'},
 {pattern:/\b(deseo|genio|magia|varita|lampara)\b/,emoji:'✨',label:'PEDÍ UN DESEO'},
 {pattern:/\b(parca|muerte|fiambre|fantasma|halloween)\b/,emoji:'👻',label:'GIRO INESPERADO'},
 {pattern:/\b(auto|reno|bm|trineo)\b/,emoji:'🚗',label:'EN MARCHA'},
];
export function reactionFor(text:string){
 const normalized=text.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'');
 return meanings.find(item=>item.pattern.test(normalized))??null;
}
/** A single cue track keeps stickers, graphics and sound inside the same clean-gap contract. */
export function artEvents(words:Word[],start:number,duration:number,settings:RemixSettings){
 const gap=Math.max({sparse:4,medium:2.5,frequent:1.5}[settings.frequency],(settings.breathingRoom??3)+.8);
 const events:{time:number;reaction:ReturnType<typeof reactionFor>}[]=[];
 const density=settings.stickerDensity??'sparse';
 for(let i=0;i<words.length;i++){
  const time=words[i].start_seconds-start;
  if(time<1||time>duration-1.8)continue;
  const reaction=reactionFor(words[i].text);
  const phrase=i>0&&/[.!?…]$/.test(words[i-1].text);
  if(events.length&&time-events.at(-1)!.time<gap)continue;
  if(!phrase&&!reaction&&events.length)continue;
  const context=words.slice(i, i+8).map(w=>w.text).join(' ');
  events.push({time,reaction:density==='off'?null:reaction??(density==='normal'?reactionFor(context):null)});
 }
 return events;
}
export function creativeBrief(settings:RemixSettings,transcript:string){
 const looks={none:'preserve the original look',comic:'hand-inked comic panels, halftone textures, bold graphic silhouettes',collage:'handmade cutout paper collage, layered tactile materials, stop-motion texture',neon:'retro-futurist neon broadcast, luminous cyan and magenta, precise graphic accents',psychedelic:'surreal liquid colors, kaleidoscopic scenery, expressive painterly textures',minimal:'restrained cinematic lighting, uncluttered composition, crisp subject separation'};
 return `Restyle the supplied source video as ${looks[settings.artPack??'none']}. Preserve the character identity, actions, shot framing and exact duration. Keep faces and mouth movement stable. No generated text, captions, logos or replacement dialogue. Use visual intensity ${settings.artIntensity??50}%. Keep quieter moments between accents. Original dialogue and timed captions will be added afterward. Spoken context: ${transcript.slice(0,2400)}`;
}
