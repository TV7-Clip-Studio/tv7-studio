import {defaultRemixSettings,type RemixSettings} from './settings';
/** Cycle packs and palettes, then vary each recipe without eliminating clean intervals. */
export function shuffledRecipe(index:number,offset:number,random:()=>number=Math.random):RemixSettings {
 const packs=['comic','collage','neon','psychedelic','minimal'] as const;
 const artPack=packs[(index+offset)%packs.length];
 const treatment=artPack==='collage'?'editorial':artPack==='neon'?'retro':'comedy';
 const pick=<T,>(items:readonly T[])=>items[Math.min(items.length-1,Math.floor(random()*items.length))]!;
 return {...defaultRemixSettings(treatment),artPack,artIntensity:pick([35,50,65,80]),stickerSize:pick([35,50,65]),stickerDensity:pick(['sparse','normal'] as const),palette:['yellow','cyan','pink','lime','orange'][(index+offset*2+Math.floor(index/5))%5] as RemixSettings['palette'],effect:(['impact','glitch','shockwave','freeze','whip'] as const)[(index+offset+Math.floor(index/25))%5],intensity:pick([25,40,55]),frequency:pick(['sparse','medium'] as const),durationMs:pick([150,300,500]),breathingRoom:pick([2,3,4]),background:artPack==='psychedelic'?'kaleidoscope':pick(['blur','tunnel'] as const),backgroundIntensity:pick([20,30,40]),sound:pick(['none','impact','digital','sweep'] as const),soundVolume:pick([10,15,20])};
}

export function shuffleErrorSummary(error:string){
 if(/timed?\s*out|timeout/i.test(error))return 'Renderer timed out. Resume shuffle retries this clip.';
 if(error.includes('Cannot reach local Engine'))return 'Engine connection interrupted. Saved clips are retained; resume to retry.';
 if(error.includes('Media file is missing'))return `Missing local asset: ${error.split('/').at(-1)}. Resume checks and rebuilds missing renders.`;
 return error.replace(/^Error:\s*/,'').slice(0,240);
}
