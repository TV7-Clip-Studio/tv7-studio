export type Treatment = 'comedy' | 'editorial' | 'retro';
export type Word = {start_seconds:number; end_seconds:number; text:string};
import type {RemixSettings} from "./settings";
import type {CutawayMedia} from "./cutaways";
export type RemixProps = {cutaways?:Record<string,CutawayMedia>;src:string; start:number; duration:number; words:Word[]; treatment:Treatment; settings?:RemixSettings};
export const treatments = {comedy:{name:'Punchy comedy',paper:'#0D0D12',accent:'#FFE600',ink:'#ffffff'},editorial:{name:'Editorial collage',paper:'#F4F0E8',accent:'#D13426',ink:'#171717'},retro:{name:'Retro broadcast',paper:'#071c27',accent:'#00F0FF',ink:'#ffffff'}};
