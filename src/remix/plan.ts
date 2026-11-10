export const remixTools={hook:'Clickbait hook',cutaway:'Full-frame meme clip',zoom:'Punch-in zoom',impact:'Impact zoom',freeze:'Freeze frame',glitch:'RGB glitch',shockwave:'Shockwave',whip:'Whip motion',spotlight:'Spotlight',sound:'Sound insert',sticker:'Emoji sticker',meme:'Reaction card',callout:'Text callout',background:'VJ background'};
export type RemixTool=keyof typeof remixTools;
export const toolValues:Partial<Record<RemixTool,string[]>>={hook:['banner','freeze_banner','flash'],sound:['impact','digital','sweep','pop','rimshot','record_stop'],sticker:['food','football','magic','car','ghost','money'],meme:['double_take','awkward','sus','stonks'],background:['tunnel','kaleidoscope']};
export type RemixEvent={id:string;at:number;duration:number;tool:RemixTool;amount:number;value:string;text:string;reason:string;enabled:boolean;asset_start?:number};
export type RemixPlan={version:1;direction:string;events:RemixEvent[]};
export function activeEdits(plan:RemixPlan,time:number){return plan.events.filter(e=>e.enabled&&e.tool!=='cutaway'&&e.amount>0&&time>=e.at&&time<e.at+e.duration);}
export function editEnvelope(e:RemixEvent,time:number){return Math.max(0,Math.min(1,e.tool==='hook'?1:(time-e.at)/.08,(e.at+e.duration-time)/.12));}
