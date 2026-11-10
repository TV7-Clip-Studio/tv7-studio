import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import ts from 'typescript';
const source=ts.transpileModule(readFileSync(new URL('../src/remix/plan.ts',import.meta.url),'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext}}).outputText;
const {activeEdits,editEnvelope}=await import(`data:text/javascript;base64,${Buffer.from(source).toString('base64')}`);
test('director uses explicit clip-relative edits with clean frames and disabled tools',()=>{
 const h={id:'h',at:0,duration:1,tool:'hook',amount:80,value:'freeze_banner',text:'¿ASADO A LAS 9:30?',reason:'Hook',enabled:true};
 const e={id:'a',at:4,duration:1,tool:'sound',amount:20,value:'pop',text:'',reason:'Punchline',enabled:true};
 const p={version:1,direction:'Dry comedy',events:[h,e,{...e,id:'off',enabled:false}]};
 assert.deepEqual(activeEdits(p,0),[h]);assert.equal(editEnvelope(h,0),1);
 assert.deepEqual(activeEdits(p,3.99),[]);assert.deepEqual(activeEdits(p,4.5),[e]);assert.deepEqual(activeEdits(p,5),[]);
 assert.equal(editEnvelope(e,4),0);assert.equal(editEnvelope(e,4.5),1);assert.equal(editEnvelope(e,5),0);
});
const clockCode=ts.transpileModule(readFileSync(new URL('../src/remix/cutaways.ts',import.meta.url),'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext}}).outputText;
const {timelineSegments,outputFrames}=await import(`data:text/javascript;base64,${Buffer.from(clockCode).toString('base64')}`);
test('whole-frame inserts add output time without losing or repeating source frames',()=>{
 const event=(id,at,duration,enabled=true)=>({id,at,duration,enabled,tool:'cutaway',amount:0,value:'meme-test',text:'',reason:'Reaction'});
 const p={version:1,direction:'Test',events:[event('second',7,1),event('first',2,1.5),event('disabled',4,1,false)]};
 const segments=timelineSegments(10,p);
 assert.deepEqual(segments.map(s=>[s.kind,s.from,s.frames,s.kind==='source'?s.sourceFrame:s.event.id]),[['source',0,60,0],['cutaway',60,45,'first'],['source',105,150,60],['cutaway',255,30,'second'],['source',285,90,210]]);
 assert.equal(segments.filter(s=>s.kind==='source').reduce((sum,s)=>sum+s.frames,0),300);assert.equal(outputFrames(10,p),375);
 assert.equal(segments.at(-1).from+segments.at(-1).frames,375);
});
