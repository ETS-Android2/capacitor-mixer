import { registerPlugin } from '@capacitor/core';

import type { MixerPlugin } from './definitions';

const Mixer = registerPlugin<MixerPlugin>('Mixer', {
    web: () => import('./web').then(m => new m.MixerWeb()),
});

export * from './definitions';
export { Mixer };