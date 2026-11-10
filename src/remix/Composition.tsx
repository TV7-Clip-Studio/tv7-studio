import React, {useMemo} from "react";
import {useAudioData} from "@remotion/media-utils";
import { Audio, Freeze, Sequence, staticFile, AbsoluteFill, OffthreadVideo, useCurrentFrame } from 'remotion';
import {treatments,type RemixProps} from "./model";
import FilteredVideo from "./FilteredVideo";
import VJBackground from "./VJBackground";
import {defaultRemixSettings,effectAt,mixGains} from "./settings";
import {timelineSegments} from "./cutaways";
import PlanOverlays from "./PlanOverlays";
import {activeEdits,editEnvelope} from "./plan";
import ArtOverlays from "./ArtOverlays";
import {artEvents} from "./art";
function SourceComposition({src,start,duration,words:allWords,treatment,settings:recipe,offset=0}:RemixProps&{offset?:number}) {
 const words=allWords.filter(w=>w.end_seconds>start&&w.start_seconds<start+duration);
 const frame=useCurrentFrame()+offset, time=frame/30+start;
 const mediaStart=start+offset/30;
 const index=words.findIndex(w=>time>=w.start_seconds&&time<w.end_seconds);
 const recent=index>=0?index:words.findLastIndex(w=>w.start_seconds<=time);
 const group=recent<0?[]:words.slice(Math.floor(recent/4)*4,Math.floor(recent/4)*4+4);
 const baseSettings=recipe??defaultRemixSettings(treatment);
 const plan=baseSettings.plan;
 const planned=plan?activeEdits(plan,frame/30):[];
 const hookEdit=planned.find(e=>e.tool==='hook');
 const motion=planned.find(e=>['zoom','impact','freeze','glitch','shockwave','whip'].includes(e.tool));
 const backgroundEdit=planned.find(e=>e.tool==='background');
 const settings=plan?{...baseSettings,effect:(motion?.tool==='zoom'?'impact':motion?.tool??(hookEdit?.value==='freeze_banner'?'freeze':hookEdit?'impact':'none')) as typeof baseSettings.effect,background:(backgroundEdit?.value??'blur') as typeof baseSettings.background,backgroundIntensity:backgroundEdit?.amount??0,sound:'none' as const}:baseSettings;
 const theme={...treatments[treatment],...(settings.palette?{accent:{yellow:'#FFE600',cyan:'#00F0FF',pink:'#FF75D6',lime:'#D0F26B',orange:'#FFAB40'}[settings.palette]}:{})};
 const audio=useAudioData(src);
 const peak=useMemo(()=>{
   if(!audio)return 1;
   const from=Math.max(0,Math.round(start*audio.sampleRate));const to=Math.round((start+duration)*audio.sampleRate);
   let maximum=0;for(const channel of audio.channelWaveforms)for(let i=from;i<Math.min(to,channel.length);i++)maximum=Math.max(maximum,Math.abs(channel[i]));
   return maximum;
 },[audio,start,duration]);
 const gains=mixGains(settings,peak);
 const events=artEvents(words,start,duration,settings);
 const beats=events.map(event=>event.time);
 const reaction=events.findLast(event=>event.time<=frame/30)?.reaction??null;
 const automatic=effectAt(frame/30,beats,settings);
 const activeMotion=motion??hookEdit;
 const elapsed=plan?(activeMotion?frame/30-activeMotion.at:Infinity):automatic.elapsed;
 const strength=plan?(activeMotion?activeMotion.amount/100*editEnvelope(activeMotion,frame/30):0):automatic.strength;
 const backgroundEnvelope=plan?(backgroundEdit?editEnvelope(backgroundEdit,frame/30):0):automatic.backgroundEnvelope;
 const scale=['impact','freeze'].includes(settings.effect)?1+strength*.12:1;
 const holdFrame=plan&&(motion?.tool==='freeze'||hookEdit?.value==='freeze_banner')?Math.round((motion?.at??hookEdit?.at??0)*30):settings.effect==='freeze'&&strength>0?Math.round((beats.findLast(beat=>beat<=frame/30)??frame/30)*30):frame;
 const jitter=settings.effect==='glitch'?Math.sin(frame*2.7)*strength*9:settings.effect==='whip'?Math.sin(elapsed/settings.durationMs*1000*Math.PI*2)*strength*90:0;
 const shift=Number.isFinite(jitter)?jitter:0;
 return <React.Fragment><AbsoluteFill style={{backgroundColor:theme.paper,fontFamily:'Arial, sans-serif',color:theme.ink}}>
  {treatment!=='editorial'&&<AbsoluteFill style={{opacity:backgroundEnvelope*(settings.background==='blur'?settings.backgroundIntensity/100:.12*settings.backgroundIntensity/100),filter:'blur(45px)',transform:'scale(1.2)'}}><OffthreadVideo src={src} trimBefore={Math.round(mediaStart*30)} muted style={{width:'100%',height:'100%',objectFit:'cover'}}/></AbsoluteFill>}
  {settings.background!=='blur'&&<VJBackground start={mediaStart} settings={settings} accent={theme.accent} audio={audio} envelope={backgroundEnvelope}/>}
  {settings.sound!=='none'&&settings.soundVolume>0&&beats.map((beat,i)=><Sequence key={i} from={Math.round(beat*30)-offset} durationInFrames={15} layout="none"><Audio src={staticFile(`remix-sfx/${settings.sound}.wav`)} volume={gains.effects} /></Sequence>)}
  {(plan||settings.effect==='freeze')&&<Audio src={src} trimBefore={Math.round(mediaStart*30)} volume={gains.dialogue}/>}
  <div style={{position:'absolute',top:460,left:40,width:1000,height:563,overflow:'hidden',border:treatment==='editorial'?'12px solid white':'none',boxShadow:'0 18px 50px #0004',transform:`rotate(${treatment==='editorial'?-1:0}deg)`}}><div style={{position:'absolute',inset:0,transform:`translateX(${shift}px) scale(${scale})`}}>{plan?<Freeze frame={holdFrame-offset}><FilteredVideo src={src} start={mediaStart} settings={settings} strength={strength} elapsed={elapsed} volume={0}/></Freeze>:settings.effect==='freeze'?<Freeze frame={holdFrame-offset}><OffthreadVideo src={src} trimBefore={Math.round(mediaStart*30)} muted style={{width:'100%',height:'100%',objectFit:'contain'}}/></Freeze>:settings.effect==='none'?<OffthreadVideo src={src} trimBefore={Math.round(mediaStart*30)} volume={gains.dialogue} style={{width:'100%',height:'100%',objectFit:'contain'}}/>:<FilteredVideo src={src} start={mediaStart} settings={settings} strength={strength} elapsed={elapsed} volume={gains.dialogue}/>}</div></div>
  {!plan&&<ArtOverlays settings={settings} envelope={backgroundEnvelope} elapsed={elapsed} reaction={reaction} accent={theme.accent}/>}
  {plan&&<PlanOverlays plan={plan} time={frame/30} offset={offset} accent={theme.accent}/>}
  <div style={{position:'absolute',top:1200,left:90,right:90,height:360,display:'flex',justifyContent:'center',alignItems:'flex-start',alignContent:'flex-start',flexWrap:'wrap',gap:14,fontSize:64,lineHeight:1.45,fontWeight:800,textAlign:'center'}}>{group.map((w,i)=><span key={i} style={{padding:'2px 14px',borderRadius:treatment==='retro'?0:12,background:time>=w.start_seconds&&time<w.end_seconds?theme.accent:'transparent',color:time>=w.start_seconds&&time<w.end_seconds?(treatment==='editorial'?'white':'#111'):theme.ink,textShadow:treatment==='editorial'||(time>=w.start_seconds&&time<w.end_seconds)?'none':'0 3px 5px #000'}}>{w.text}</span>)}</div>
  <div style={{position:'absolute',left:76,top:treatment==='editorial'?385:350,width:90,height:8,background:theme.accent}}/>
  {treatment==='retro'&&<div style={{position:'absolute',top:330,right:76,fontFamily:'monospace',fontSize:26,letterSpacing:5,color:theme.accent,border:`2px solid ${theme.accent}`,padding:'12px 20px'}}>ON AIR</div>}
  {treatment==='editorial'&&<div style={{position:'absolute',left:76,top:330,fontFamily:'Georgia,serif',fontSize:32,letterSpacing:4}}>OTRO DÍA / EN EL BARRIO</div>}
  {treatment==='editorial'&&<><div style={{position:'absolute',left:68,top:410,width:55,height:55,borderLeft:`6px solid ${theme.accent}`,borderTop:`6px solid ${theme.accent}`}}/><div style={{position:'absolute',right:68,top:1010,width:55,height:55,borderRight:`6px solid ${theme.accent}`,borderBottom:`6px solid ${theme.accent}`}}/></>}
  {treatment==='retro'&&<AbsoluteFill style={{pointerEvents:'none',height:1050,opacity:.08*backgroundEnvelope,background:'repeating-linear-gradient(transparent 0px,transparent 3px,#000 3px,#000 5px)'}}/>}
 </AbsoluteFill></React.Fragment>;
}

export function RemixComposition(props:RemixProps){
 const segments=timelineSegments(props.duration,props.settings?.plan);
 return <AbsoluteFill>{segments.map((segment,i)=><Sequence key={i} from={segment.from} durationInFrames={segment.frames}>
 {segment.kind==='source'?<SourceComposition {...props} offset={segment.sourceFrame}/>:<AbsoluteFill style={{background:'#080a0c'}}>
 {props.cutaways?.[segment.event.value]?<>
 <OffthreadVideo src={props.cutaways[segment.event.value].src} trimBefore={Math.round((segment.event.asset_start??0)*30)} muted style={{width:'100%',height:'100%',objectFit:'cover',filter:'blur(35px)',opacity:.35,position:'absolute'}}/>
 <OffthreadVideo src={props.cutaways[segment.event.value].src} trimBefore={Math.round((segment.event.asset_start??0)*30)} volume={segment.event.amount/100*.8} style={{width:'100%',height:'100%',objectFit:'contain'}}/>
 <div style={{position:'absolute',bottom:38,left:40,right:40,color:'white',font:'22px Arial',textAlign:'center',textShadow:'0 2px 4px black'}}>{props.cutaways[segment.event.value].attribution}</div>
 </>:<div style={{margin:'auto',color:'white',font:'40px Arial'}}>Reaction clip unavailable</div>}
 </AbsoluteFill>}
 </Sequence>)}</AbsoluteFill>;
}
