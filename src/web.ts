import { WebPlugin } from '@capacitor/core';
import { AdjustEqRequest, AdjustVolumeRequest, BaseMixerRequest, InitAudioFileRequest, MixerPlugin, SetEventRequest } from './definitions';

export class MixerWeb extends WebPlugin implements MixerPlugin {
  constructor() {
    super({
      name: 'Mixer',
      platforms: ['web'],
    });
  }

  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }

  async play(options: BaseMixerRequest): Promise<{ state: string }> {
    console.log('ECHO', options);
    return { state: options.audioId };
  }

  async stop(options: BaseMixerRequest): Promise<{ state: string }> {
    console.log('boi', options);
    return { state: options.audioId }
  }

  async isPlaying(options: BaseMixerRequest): Promise<{ value: boolean }> {
    console.log('areyouplaying?', options);
    return { value: true }
  }

  async getCurrentVolume(options: BaseMixerRequest): Promise<{ volume: number }> {
    console.log('how loud is it?', options);
    return { volume: -1 }
  }

  async getCurrentEQ(options: BaseMixerRequest): Promise<{
    bassGain: number, bassFreq: number,
    midGain: number, midFreq: number,
    trebleGain: number, trebleFreq: number
  }> {
    console.log('tell us about eq', options);
    return {
      bassGain: -1, bassFreq: -1,
      midGain: -1, midFreq: -1,
      trebleGain: -1, trebleFreq: -1
    }
  }



  async initAudioFile(options: InitAudioFileRequest): Promise<{ value: string }> {
    console.log('HEYBUBBY', options);
    return { value: `${options.filePath} ${options.audioId}` }
  }

  async adjustVolume(options: AdjustVolumeRequest): Promise<void> {
    console.log('adjusting volume', options);
    return
  }

  async adjustEQ(options: AdjustEqRequest): Promise<void> {
    console.log('adjusting eq', options);
    return
  }

  async setElapsedTimeEvent(options: SetEventRequest): Promise<void> {
    console.log('ur late lol', options);
    return
  }

}

const Mixer = new MixerWeb();

export { Mixer };

import { registerWebPlugin } from '@capacitor/core';
registerWebPlugin(Mixer);
