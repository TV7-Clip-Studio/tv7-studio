/** Late responses must not recreate a cleared batch or mutate a cancelled job. */
export function patchBatchClip<T extends {clips:{id:string}[]}>(batches:Record<string,T>,jobId:string,clipId:string,patch:Partial<T['clips'][number]>,cancelled=false):Record<string,T>{
 const batch=batches[jobId];
 if(cancelled||!batch)return batches;
 return {...batches,[jobId]:{...batch,clips:batch.clips.map(clip=>clip.id===clipId?{...clip,...patch}:clip)}};
}
