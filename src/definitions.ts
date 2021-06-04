declare module '@capacitor/core' {
  interface PluginRegistry {
    Mixer: MixerPlugin;
  }
}
/**
 * Base class for all mixer requests
 */
export interface BaseMixerRequest {
  /**
   * A string identifying the audio file
   */
  audioId: string;
}
/**
 * For mixer requests specifying filePath on device
 */

// TODO: Add volume initializer?
export interface InitAudioFileRequest extends BaseMixerRequest {
  /**
   * A string identifying the path to the audio file on device
   */
  filePath: string;
  /**
   * Optional bass gain setting for initialization: -36dB to +15 dB
   * 
   * Default: 0dB
   */
  bassGain?: number;
  /**
   * Optional init eq setting for low shelf
   * 
   * Default: 115Hz
   */
  bassFrequency?: number;
  /**
   * Optional mid gain setting for initialization: -36dB to +15 dB
   * 
   * Default: 0dB
   */
  midGain?: number;
  /**
   * Optional init setting for parametric mid band
   * 
   * Default: 500Hz
   */
  midFrequency?: number;
  /**
   * Optional treble gain setting for initialization: -36dB to +15 dB
   * 
   * Default: 0dB
   */
  trebleGain?: number;
  /**
   * Optional init eq setting for high shelf
   * 
   * Default: 1.5kHhz
   */
  trebleFrequency?: number;
}
/**
 * For mixer requests specifying volume level
 */
export interface AdjustVolumeRequest extends BaseMixerRequest {
  /**
   * A number between 0 and 1 specifying volume level
   */
  volume: number;
}
/**
 * For mixer requests interacting with EQ 
 */
export interface AdjustEqRequest extends BaseMixerRequest {
  /**
   * Identifies EQ band to adjust: Bass, Mid, Treble
   */
  eqType: EqType;
  /**
   * A number between -36dB and +15dB identifying EQ band gain
   */
  gain: number;
  /**
   * A number identifying cutoff/central frequency for EQ band
   * 
   * Bass: <range>
   * 
   * Mid: <range>
   * 
   * Treble: <range>
   */
  frequency: number;
}
/**
 * Request to set an event listener
 */
export interface SetEventRequest extends BaseMixerRequest {
  /**
   * The name of the event that will be subscribed to
   */
  eventName: string;
}

export enum EqType {
  BASS = "bass",
  MID = "mid",
  TREBLE = "treble"
}

export interface MixerPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
  /**
   * Toggles playback and pause on an initialized audio file
   * @param options Takes BaseMixerRequest
   */
  play(options: BaseMixerRequest): Promise<{ state: string }>;

  stop(options: BaseMixerRequest): Promise<{ state: string }>;

  isPlaying(options: BaseMixerRequest): Promise<{ value: boolean }>;

  getCurrentVolume(options: BaseMixerRequest): Promise<{ volume: number }>;

  getCurrentEQ(options: BaseMixerRequest): Promise<{ bassGain: number, bassFreq: number, midGain: number, midFreq: number, trebleGain: number, trebleFreq: number }>;

  initAudioFile(options: InitAudioFileRequest): Promise<{ value: string }>;

  adjustVolume(options: AdjustVolumeRequest): Promise<void>;

  adjustEQ(options: AdjustEqRequest): Promise<void>;

  setElapsedTimeEvent(options: SetEventRequest): Promise<void>;
}

