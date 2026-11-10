import {AbsoluteFill,useCurrentFrame} from 'remotion';
import {visualizeAudio,type AudioData} from '@remotion/media-utils';
import type {RemixSettings} from './settings';
export default function VJBackground({start,settings,accent,audio,envelope}:{start:number;settings:RemixSettings;accent:string;audio:AudioData|null;envelope:number}) {
  const frame=useCurrentFrame();
  const spectrum=audio?visualizeAudio({audioData:audio,frame:frame+Math.round(start*30),fps:30,numberOfSamples:16}):[];
  const energy=Math.min(1,spectrum.reduce((a,b)=>a+b,0)/Math.max(1,spectrum.length)*4);
  const rotation=frame*.12;
  return <AbsoluteFill style={{opacity:settings.backgroundIntensity/100*envelope,pointerEvents:'none'}}><svg viewBox="0 0 1080 1920" width="100%" height="100%" aria-hidden="true"><g transform={`translate(540 860) rotate(${rotation})`}>
    {Array.from({length:14},(_,i)=>{
      const phase=(i/14+frame/180)%1;const radius=80+phase*1150;const hue=(i*24+frame*.15)%360;
      return settings.background==='tunnel'?<circle key={i} r={radius*(1+energy*.15)} fill="none" stroke={i%2?accent:`hsl(${hue} 85% 60%)`} strokeWidth={6+energy*16} opacity={1-phase}/>:<g key={i} transform={`rotate(${i*360/14})`}><path d={`M 0 0 Q ${180+energy*120} -300 0 -1100 Q -180 -300 0 0`} fill={`hsl(${hue} 80% 50% / .22)`} stroke={accent} strokeWidth={3+energy*6}/></g>;
    })}
  </g></svg></AbsoluteFill>;
}
