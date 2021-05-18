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

  async play(options: { filePath: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return { value: options.filePath };
  }
}

const Mixer = new MixerWeb();

export { Mixer };

import { registerWebPlugin } from '@capacitor/core';
registerWebPlugin(Mixer);
