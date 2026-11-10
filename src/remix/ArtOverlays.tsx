import type {RemixSettings} from './settings';
import type {reactionFor} from './art';
export default function ArtOverlays({settings,envelope,elapsed,reaction,accent}:{settings:RemixSettings;envelope:number;elapsed:number;reaction:ReturnType<typeof reactionFor>;accent:string}){
 const pack=settings.artPack??'none';
 if(pack==='none'||envelope<=0)return null;
 const power=(settings.artIntensity??50)/100;
 const motion=Math.sin(Math.min(elapsed,.8)*Math.PI/.8);
 const rotation=Math.sin(elapsed*18)*power*8;
 const size=90+(settings.stickerSize??50)*1.5;
 return <div style={{position:'absolute',inset:0,pointerEvents:'none',opacity:envelope*power}}>
  <svg width="1080" height="1920" viewBox="0 0 1080 1920" style={{position:'absolute',inset:0,clipPath:'inset(0 0 760px 0)'}}>
   {pack==='comic'&&Array.from({length:16},(_,i)=>{const a=i*Math.PI/8;return <path key={i} d={`M ${540+Math.cos(a)*640} ${760+Math.sin(a)*520} L ${540+Math.cos(a)*(500-motion*60)} ${760+Math.sin(a)*(370-motion*40)}`} stroke={accent} strokeWidth={i%2?8:18}/>;})}
   {pack==='collage'&&<><path d="M 75 340 l 320 -24 -18 55 -305 22 Z" fill="#e6c08b"/><path d="M 715 1080 l 290 -25 10 42 -295 30 Z" fill={accent}/><path d="M 35 445 l 80 -12 -24 52 34 55 -90 -8 Z" fill="#fff"/></>}
   {pack==='neon'&&<g fill="none" stroke={accent} strokeWidth="5"><path d="M 55 560 v -115 h 180 M 1025 900 v 140 h -180"/><circle cx="940" cy="350" r={40+motion*20}/><path d="M 80 1080 h 170 m 20 0 h 35"/></g>}
   {pack==='psychedelic'&&Array.from({length:8},(_,i)=><ellipse key={i} cx="540" cy="760" rx={430+motion*50} ry="340" fill="none" stroke={`hsl(${i*45+elapsed*90} 90% 60%)`} strokeWidth="7" transform={`rotate(${i*22.5+elapsed*35} 540 760)`}/>)}
   {pack==='minimal'&&<path d="M 80 1100 h 230" stroke={accent} strokeWidth={8+motion*8}/>}
  </svg>
  {reaction&&settings.stickerDensity!=='off'&&<div style={{position:'absolute',top:pack==='minimal'?1080:310,right:100,transform:`rotate(${rotation}deg) scale(${.8+motion*.25})`,fontSize:size,fontFamily:'Apple Color Emoji, Segoe UI Emoji, sans-serif',filter:'drop-shadow(0 7px 5px #0008)'}}>{reaction.emoji}</div>}
  {reaction&&pack!=='minimal'&&<div style={{position:'absolute',top:1090,left:80,padding:'10px 22px',fontSize:30,fontWeight:900,letterSpacing:3,color:'#111',background:accent,transform:`rotate(${pack==='collage'?-5:rotation/3}deg)`,border:pack==='comic'?'5px solid #111':'none'}}>{reaction.label}</div>}
 </div>;
}
