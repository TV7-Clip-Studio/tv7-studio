import {outputFrames} from "./cutaways";
import React from "react";
import {Composition, registerRoot} from 'remotion';
import {RemixComposition} from './Composition';
registerRoot(()=> <React.Fragment><Composition id="Remix" component={RemixComposition} width={1080} height={1920} fps={30} durationInFrames={300} defaultProps={{src:'',start:0,duration:10,words:[],treatment:'comedy'}} calculateMetadata={({props})=>({durationInFrames:outputFrames(props.duration,props.settings?.plan)})}/></React.Fragment>);
