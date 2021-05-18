declare module '@capacitor/core' {
  interface PluginRegistry {
    Mixer: MixerPlugin;
  }
}

export interface MixerPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;

  play(options: { filePath: string }): Promise<{ value: string }>;
}

