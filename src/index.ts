// import { Mixer as MixerPlugin } from './definitions';
// declare const Mixer: MixerPlugin;
// export * from './definitions';
// export * from './web';
// export { Mixer };

import { registerPlugin } from '@capacitor/core';

import type { MixerPlugin } from './definitions';

const Mixer = registerPlugin<MixerPlugin>('Mixer', {
    web: () => import('./web').then(m => new m.MixerWeb()),
});

export * from './definitions';
export { Mixer };



// import { registerPlugin } from '@capacitor/core';
// import type { Mixer as MixerPlugin } from './definitions';
// declare const Mixer: MixerPlugin;

// const Mixer = registerPlugin<Mixer>('Mixer', {
//     // web: () => import('./web').then(m => new m.MixerWeb()),
//     // electron: () => ("./electron").then(m => new m.MyCoolPluginElectron())
// });

// export * from './definitions';
// export { Mixer };