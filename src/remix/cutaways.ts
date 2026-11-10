import type {RemixPlan} from './plan';
export type CutawayMedia={src:string;attribution:string;title:string;duration:number};
export function cutawayEvents(plan?:RemixPlan){return (plan?.events??[]).filter(e=>e.enabled&&e.tool==='cutaway').sort((a,b)=>a.at-b.at);}
export function outputFrames(duration:number,plan?:RemixPlan){return Math.ceil(duration*30)+cutawayEvents(plan).reduce((sum,e)=>sum+Math.round(e.duration*30),0);}
/** Cuts are anchored to source time. Inserting one never shifts another's source anchor. */
export function timelineSegments(duration:number,plan?:RemixPlan){
 const segments:({kind:'source';from:number;frames:number;sourceFrame:number}|{kind:'cutaway';from:number;frames:number;event:ReturnType<typeof cutawayEvents>[number]})[]=[];
 let source=0,output=0;const end=Math.ceil(duration*30);
 for(const event of cutawayEvents(plan)){
  const at=Math.max(source,Math.min(end,Math.round(event.at*30)));
  if(at>source){segments.push({kind:'source',from:output,frames:at-source,sourceFrame:source});output+=at-source;}
  const frames=Math.max(1,Math.round(event.duration*30));segments.push({kind:'cutaway',from:output,frames,event});output+=frames;source=at;
 }
 if(source<end)segments.push({kind:'source',from:output,frames:end-source,sourceFrame:source});
 return segments;
}
