import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import ts from 'typescript';
const code=ts.transpileModule(readFileSync(new URL('../src/remix/settings.ts',import.meta.url),'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2023}}).outputText;
const {defaultRemixSettings,effectBeats,effectAt,mixGains}=await import(`data:text/javascript;base64,${Buffer.from(code).toString('base64')}`);
const words=Array.from({length:20},(_,i)=>({start_seconds:20+i,end_seconds:20+i+.7,text:'phrase.'}));
test('effect cues stay inside source trim and respect spacing deterministically',()=>{
 assert.deepEqual(effectBeats(words,22,10,'sparse'),[1,5]);
 assert.deepEqual(effectBeats(words,22,10,'medium'),[1,5]);
 assert.deepEqual(effectBeats(words,22,10,'sparse'),effectBeats(words,22,10,'sparse'));
 assert.deepEqual(effectBeats([],22,10,'medium'),[]);
});
test('zero intensity disables motion, and duration controls the event envelope',()=>{
 const settings={...defaultRemixSettings(),intensity:100,durationMs:300};
 assert.equal(effectAt(.15,[0],settings).strength,1);
 assert.equal(effectAt(.31,[0],settings).strength,0);
 assert.equal(effectAt(.15,[0],{...settings,intensity:0}).strength,0);
 assert.equal(effectAt(.15,[0],{...settings,intensity:50}).strength,.5);
 assert.equal(effectAt(.6,[1],settings).strength,0);
});

test('mix reserves headroom for hot source audio and keeps zero-volume controls silent',()=>{
 const settings={...defaultRemixSettings(),sound:'digital',soundVolume:100};
 const hot=mixGains(settings,1.44);assert.ok(hot.dialogue*1.44+hot.effects<=.89);
 assert.equal(mixGains({...settings,dialogueVolume:0,soundVolume:0},1.44).dialogue,0);
 assert.equal(mixGains({...settings,soundVolume:0},1.44).effects,0);
 assert.equal(mixGains(settings,.2).dialogue,1);
});

test('all visual layers rest between bursts, with clean intro and outro',()=>{
 const settings={...defaultRemixSettings(),effect:'glitch',intensity:100};
 const beats=effectBeats(words,20,20,'frequent',3);
 assert.ok(beats.every((b,i)=>b>=1&&b<=18.2&&(i===0||b-beats[i-1]>=3.8)));
 assert.equal(effectAt(0,beats,settings).backgroundEnvelope,0);
 for(const beat of beats){
  assert.ok(effectAt(beat+.2,beats,settings).backgroundEnvelope>0);
  for(let t=beat+.8;t<beat+3.8;t+=.1){
   assert.equal(effectAt(t,beats,settings).strength,0);
   assert.equal(effectAt(t,beats,settings).backgroundEnvelope,0);
  }
 }
 assert.equal(effectAt(19.5,beats,settings).backgroundEnvelope,0);
});

const artCode=ts.transpileModule(readFileSync(new URL('../src/remix/art.ts',import.meta.url),'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2023}}).outputText;
const {reactionFor,artEvents,creativeBrief}=await import(`data:text/javascript;base64,${Buffer.from(artCode).toString('base64')}`);
test('semantic stickers follow meanings and do not decorate unrelated speech',()=>{
 assert.equal(reactionFor('FÚTBOL!').emoji,'⚽');assert.equal(reactionFor('varita').emoji,'✨');
 assert.equal(reactionFor('cualquier palabra'),null);
 const cues=[{start_seconds:1.2,end_seconds:1.5,text:'equipo'},{start_seconds:2,end_seconds:2.4,text:'regalo'},{start_seconds:5.2,end_seconds:5.6,text:'varita'}];
 const events=artEvents(cues,0,10,defaultRemixSettings());
 assert.deepEqual(events.map(e=>e.time),[1.2,5.2]);
 assert.ok(artEvents(cues,0,10,{...defaultRemixSettings(),stickerDensity:'off'}).every(e=>e.reaction===null));
});
test('AI restyling brief preserves dialogue and caption compositing boundaries',()=>{
 const brief=creativeBrief({...defaultRemixSettings(),artPack:'collage',artIntensity:35},'un deseo');
 assert.ok(brief.includes('paper collage'));assert.ok(brief.includes('35%'));assert.ok(brief.includes('No generated text'));
});

const settingsUrl=`data:text/javascript;base64,${Buffer.from(code).toString('base64')}`;
const shuffleCode=ts.transpileModule(readFileSync(new URL('../src/remix/shuffle.ts',import.meta.url),'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2023}}).outputText.replace(/from ['"]\.\/settings['"]/g,`from "${settingsUrl}"`);
const {shuffledRecipe}=await import(`data:text/javascript;base64,${Buffer.from(shuffleCode).toString('base64')}`);
test('global shuffle cycles distinct art packs and palettes with controlled clean gaps',()=>{
 const recipes=Array.from({length:10},(_,i)=>shuffledRecipe(i,2,()=>.5));
 assert.equal(new Set(recipes.slice(0,5).map(r=>r.artPack)).size,5);
 assert.equal(new Set(recipes.slice(0,5).map(r=>r.palette)).size,5);
 assert.equal(new Set(recipes.map(r=>JSON.stringify(r))).size,10);
 assert.ok(recipes.every(r=>r.artPack!=='none'&&r.breathingRoom>=2&&r.intensity<=55&&r.soundVolume<=20));
 assert.deepEqual(shuffledRecipe(0,2,()=>.5),recipes[0]);
});
