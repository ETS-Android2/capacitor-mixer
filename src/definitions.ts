declare module '@capacitor/core' {
  interface PluginRegistry {
    Mixer: MixerPlugin;
  }
}

export interface MixerPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;

  play(options: { audioID: string }): Promise<{ state: string }>;

  stop(options: { audioID: string }): Promise<{ state: string }>;

  isPlaying(options: { audioID: string }): Promise<{ value: boolean }>;

  getCurrentVolume(options: { audioID: string }): Promise<{ volume: number }>;

  initAudioFile(options: { filePath: string, audioID: string }): Promise<{ value: string }>;

  adjustVolume(options: { volume: number, audioID: string }): Promise<void>;

  adjustEQ(options: { audioID: string, eqType: string, gain: number, frequency: number }): Promise<void>;
}

