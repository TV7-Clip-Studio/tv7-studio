import {useCallback,useEffect,useLayoutEffect,useRef} from 'react';
import {Application,Sprite,Texture} from 'pixi.js';
import {RGBSplitFilter,ShockwaveFilter,ZoomBlurFilter,MotionBlurFilter} from 'pixi-filters';
import {OffthreadVideo,useDelayRender} from 'remotion';
import type {RemixSettings} from './settings';
export default function FilteredVideo({src,start,settings,strength,elapsed,volume}:{src:string;start:number;settings:RemixSettings;strength:number;elapsed:number;volume:number}) {
  const host=useRef<HTMLDivElement>(null);
  const runtime=useRef<{app:Application;canvas:HTMLCanvasElement;texture:Texture;split:RGBSplitFilter;wave:ShockwaveFilter;zoom:ZoomBlurFilter;motion:MotionBlurFilter}|null>(null);
  const pending=useRef<CanvasImageSource|null>(null);
  const current=useRef({settings,strength,elapsed});
  const {delayRender,continueRender,cancelRender}=useDelayRender();
  const draw=useCallback((image?:CanvasImageSource)=>{
    if(image)pending.current=image;
    const r=runtime.current;if(!r||!pending.current)return;
    const ctx=r.canvas.getContext('2d')!;ctx.fillStyle='#000';ctx.fillRect(0,0,1000,563);const size=pending.current as {videoWidth?:number;videoHeight?:number;naturalWidth?:number;naturalHeight?:number;width?:number;height?:number};const w=size.videoWidth??size.naturalWidth??size.width??1000;const h=size.videoHeight??size.naturalHeight??size.height??563;const fit=Math.min(1000/w,563/h);ctx.drawImage(pending.current,(1000-w*fit)/2,(563-h*fit)/2,w*fit,h*fit);r.texture.source.update();
    const {settings:s,strength:p,elapsed:e}=current.current;
    r.split.green={x:0,y:0};r.split.red={x:p*18,y:0};r.split.blue={x:-p*18,y:0};
    r.zoom.strength=p*.14;r.motion.velocity={x:p*24,y:0};
    r.wave.time=Number.isFinite(e)?e:0;r.wave.amplitude=p*35;r.wave.brightness=1;
    r.app.stage.filters=p<=0?[]:s.effect==='glitch'?[r.split]:s.effect==='shockwave'&&p>0?[r.wave]:s.effect==='impact'?[r.zoom]:s.effect==='whip'?[r.motion]:[];
    r.app.render();
  },[]);
  useEffect(()=>{
    let disposed=false;const handle=delayRender('Preparing visual effects');const app=new Application();
    void app.init({width:1000,height:563,preference:'webgl',autoStart:false,antialias:false,preserveDrawingBuffer:true}).then(()=>{
      if(disposed){app.destroy(true);continueRender(handle);return;}
      const canvas=document.createElement('canvas');canvas.width=1000;canvas.height=563;
      const texture=Texture.from(canvas);app.stage.addChild(new Sprite(texture));
      runtime.current={app,canvas,texture,split:new RGBSplitFilter(),wave:new ShockwaveFilter({center:{x:500,y:282},speed:1500,wavelength:120,radius:900}),zoom:new ZoomBlurFilter({center:{x:.5,y:.5}}),motion:new MotionBlurFilter({velocity:{x:0,y:0},kernelSize:9})};
      host.current?.appendChild(app.canvas);draw();continueRender(handle);
    }).catch(error=>cancelRender(error));
    return ()=>{disposed=true;continueRender(handle);if(runtime.current?.app===app){app.stage.filters=[];app.stage.removeChildren();for(const f of [runtime.current.split,runtime.current.wave,runtime.current.zoom,runtime.current.motion])f.destroy();runtime.current.texture.destroy(true);runtime.current=null;app.destroy(true);}};
  },[delayRender,continueRender,cancelRender,draw]);
  useLayoutEffect(()=>{current.current={settings,strength,elapsed};draw();},[draw,strength,elapsed,settings]);
  return <><OffthreadVideo src={src} trimBefore={Math.round(start*30)} volume={volume} onVideoFrame={draw} crossOrigin="anonymous" style={{position:'absolute',width:'100%',height:'100%',opacity:0}}/><div ref={host} style={{position:'absolute',inset:0}}/></>;
}
