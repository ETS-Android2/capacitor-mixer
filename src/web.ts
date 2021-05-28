import { WebPlugin } from '@capacitor/core';
import { MixerPlugin } from './definitions';

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

  async play(options: { audioID: string }): Promise<{ state: string }> {
    console.log('ECHO', options);
    return { state: options.audioID };
  }

  async stop(options: { audioID: string }): Promise<{ state: string }> {
    console.log('boi', options);
    return { state: options.audioID }
  }

  async isPlaying(options: { audioID: string }): Promise<{ value: boolean }> {
    console.log('areyouplaying?', options);
    return { value: true }
  }

  async getCurrentVolume(options: { audioID: string }): Promise<{ volume: number }> {
    console.log('how loud is it?', options);
    return { volume: -1 }
  }

  async initAudioFile(options: { filePath: string, audioID: string }): Promise<{ value: string }> {
    console.log('HEYBUBBY', options);
    return { value: `${options.filePath} ${options.audioID}` }
  }

  async adjustVolume(options: { volume: number, audioID: string }): Promise<void> {
    console.log('adjusting volume', options);
    return
  }

  async adjustEQ(options: { audioID: string, eqType: string, gain: number, frequency: number }): Promise<void> {
    console.log('adjusting eq', options);
    return
  }

}

const Mixer = new MixerWeb();

export { Mixer };

import { registerWebPlugin } from '@capacitor/core';
registerWebPlugin(Mixer);
