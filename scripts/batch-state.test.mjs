import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import ts from 'typescript';
const code=ts.transpileModule(readFileSync(new URL('../src/batch-state.ts',import.meta.url),'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext}}).outputText;
const {patchBatchClip}=await import(`data:text/javascript;base64,${Buffer.from(code).toString('base64')}`);
test('late channel renders cannot crash or resurrect cleared clip state',()=>{
 const empty={};assert.equal(patchBatchClip(empty,'old-job','clip',{result:'late'}),empty);
 const batches={job:{status:'rendering',clips:[{id:'clip',result:null}]}};
 assert.equal(patchBatchClip(batches,'job','clip',{result:'late'},true),batches);
 const changed=patchBatchClip(batches,'job','clip',{result:'ready'});
 assert.equal(changed.job.clips[0].result,'ready');assert.equal(changed.job.status,'rendering');assert.equal(batches.job.clips[0].result,null);
});
