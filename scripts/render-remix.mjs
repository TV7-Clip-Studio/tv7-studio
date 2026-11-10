import {bundle} from '@remotion/bundler';
import {selectComposition, renderMedia, openBrowser} from '@remotion/renderer';
import {createServer} from 'node:http';
import {existsSync,createReadStream,writeFileSync,renameSync} from 'node:fs';
import {readFile, stat, rm} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {basename,dirname,join} from 'node:path';
import {createHash} from 'node:crypto';
import {execFile} from 'node:child_process';
import {promisify} from 'node:util';
const run=promisify(execFile);
const input=JSON.parse(await readFile(process.argv[2],'utf8'));
let source=input.source;
const original=await stat(source);
const progressPath=input.progressPath;
let lastProgress=0;
const report=(status,progress=0)=>{if(!progressPath)return;const temp=progressPath+'.tmp';writeFileSync(temp,JSON.stringify({status,progress,updated_at:Date.now()}));renameSync(temp,progressPath);};
report('preparing');
// A bounded H.264 input avoids repeated 4K VP9 decoding by every render tab.
const probe=JSON.parse((await run('ffprobe',['-v','error','-select_streams','v:0','-show_entries','stream=codec_name,width,height','-of','json',source])).stdout).streams[0];
if(probe.width>1920||probe.height>1920||probe.codec_name!=='h264'){
 const key=createHash('sha256').update(`${source}:${original.size}:${original.mtimeMs}`).digest('hex').slice(0,20);
 const proxy=join(dirname(input.output),`.remix-source-${key}.mp4`);
 if(!existsSync(proxy)){
  const pending=proxy+'.pending.mp4';
  try{await run('ffmpeg',['-v','error','-y','-i',source,'-vf','scale=1920:1080:force_original_aspect_ratio=decrease:force_divisible_by=2','-c:v','libx264','-preset','veryfast','-crf','20','-pix_fmt','yuv420p','-c:a','aac','-movflags','+faststart',pending],{maxBuffer:2*1024*1024});renameSync(pending,proxy);}
  catch(error){await rm(pending,{force:true});report('failed');throw error;}
 }
 source=proxy;
}
const media=await stat(source);
const mediaFiles=new Map([['/source.mp4',{path:source,size:media.size}]]);
for(const a of input.cutaways??[]){const data=await stat(a.path);mediaFiles.set(`/cutaway/${a.id}.mp4`,{path:a.path,size:data.size});}
const server=createServer((req,res)=>{
 const entry=mediaFiles.get(req.url);if(!entry){res.writeHead(404).end();return;}
 const media=entry;
 const match=req.headers.range?.match(/^bytes=(\d+)-(\d*)$/), start=match?Number(match[1]):0,end=match&&match[2]?Math.min(Number(match[2]),media.size-1):media.size-1;
 if(start>end){res.writeHead(416).end();return;}
 res.writeHead(match?206:200,{'Content-Type':'video/mp4','Accept-Ranges':'bytes','Access-Control-Allow-Origin':'*','Content-Length':end-start+1,...(match?{'Content-Range':`bytes ${start}-${end}/${media.size}`}:{})});createReadStream(entry.path,{start,end}).pipe(res);
});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
let browser;let serveUrl;
try {
 const cutaways=Object.fromEntries((input.cutaways??[]).map(a=>[a.id,{src:`http://127.0.0.1:${server.address().port}/cutaway/${a.id}.mp4`,attribution:a.attribution,title:a.title,duration:a.duration}]));
 const props={cutaways,src:`http://127.0.0.1:${server.address().port}/source.mp4`,start:input.start,duration:input.end-input.start,words:input.words,treatment:input.treatment,settings:input.settings};
 serveUrl=await bundle({entryPoint:fileURLToPath(new URL('../src/remix/Root.tsx',import.meta.url)),publicDir:fileURLToPath(new URL('../public',import.meta.url)),enableCaching:false});
 browser=await openBrowser('chrome',{browserExecutable:process.env.TV7_REMIX_BROWSER || (existsSync('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome')?'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome':undefined)});
 const composition=await selectComposition({serveUrl,id:'Remix',inputProps:props,puppeteerInstance:browser,timeoutInMilliseconds:60000});
 report('rendering');
 await renderMedia({serveUrl,composition,inputProps:props,codec:'h264',outputLocation:input.output,puppeteerInstance:browser,concurrency:2,crf:20,offthreadVideoCacheSizeInBytes:512*1024*1024,timeoutInMilliseconds:60000,onProgress:({progress})=>{if(Date.now()-lastProgress>500){lastProgress=Date.now();report('rendering',progress);}}});
 report('complete',1);
} catch(error){report('failed');throw error;} finally {
 if(browser)await Promise.race([browser.close({silent:true}),new Promise(resolve=>setTimeout(resolve,3000))]);
 server.closeAllConnections();server.close();
 if(serveUrl&&basename(serveUrl).startsWith('remotion-webpack-bundle-'))await rm(serveUrl,{recursive:true,force:true});
}
process.exit(0);
