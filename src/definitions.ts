import { Plugin } from "@capacitor/core/dist/esm/definitions";

declare module '@capacitor/core' {
  interface PluginRegistry {
    Mixer: MixerPlugin;
  }
}
//#region Request Objects
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

export interface InitChannelRequest extends BaseMixerRequest {
  /**
   * A string identifying the path to the audio file on device. Unused if initializing microphone channel.
   */
  filePath?: string;
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
  /**
   * Optional init setting for volume 
   * 
   * Default: 1
   * 
   * Range: 0 - 1
   */
  volume?: number;
  /**
   * Required name used to set listener for volume metering
   * 
   * Note: if empty string is passed, metering will be disabled on channel
   */
  channelListenerName: string;
}
/**
 * For mixer requests specifying volume level
 */
export interface AdjustVolumeRequest extends BaseMixerRequest {
  /**
   * A number between 0 and 1 specifying volume level
   */
  volume: number;
  /**
   * Select between microphone and audio file input
   */
  inputType: InputType;
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
  /**
   * Select between microphone and audio file input
   */
  inputType: InputType;
}
/**
 * Get info about channel properties such as current volume, EQ, etc.
 */
export interface ChannelPropertyRequest extends BaseMixerRequest {
  /**
   * Select between micophone and audio file input
   */
  inputType: InputType;
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
//#endregion

//#region Response Objects
export interface BaseResponse<T> {
  status: ResponseStatus,
  message: string,
  data: T
}

export interface MixerTimeResponse {
  milliSeconds: number,
  seconds: number,
  minutes: number,
  hours: number
}

export interface PlaybackStateResponse {
  state: string
}

export interface PlaybackStateBoolean {
  value: boolean
}

export interface VolumeResponse {
  volume: number
}

export interface EqResponse {
  bassGain: number
  bassFreq: number
  midGain: number
  midFreq: number
  trebleGain: number
  trebleFreq: number
}

export interface VolumeMeterResponse {
  meterLevel: number
}

export interface InitResponse {
  value: string
}
//#endregion

export enum ResponseStatus {
  SUCCESS = "success",
  ERROR = "error"
}

export enum EqType {
  BASS = "bass",
  MID = "mid",
  TREBLE = "treble"
}

export enum InputType {
  MIC = "mic",
  FILE = "file"
}

export interface MixerPlugin extends Plugin {
  echo(request: { value: string }): Promise<{ value: string }>;
  /**
   * Toggles playback and pause on an initialized audio file
   * @param request
   */
  play(request: BaseMixerRequest): Promise<BaseResponse<PlaybackStateResponse>>;
  /**
   * Stops playback on a playing audio file
   * @param request 
   */
  stop(request: BaseMixerRequest): Promise<BaseResponse<PlaybackStateResponse>>;
  /**
   * A boolean that reports the playback state of initialized audio file
   * @param request 
   */
  isPlaying(request: BaseMixerRequest): Promise<BaseResponse<PlaybackStateBoolean>>;
  /**
   * Reports current volume of playing audio file as a number between 0 and 1
   * @param request 
   */
  getCurrentVolume(request: ChannelPropertyRequest): Promise<BaseResponse<VolumeResponse>>;
  /**
   * Returns an object with numeric values for gain and frequency in bass, mid, and treble ranges
   * @param request 
   */
  getCurrentEq(request: ChannelPropertyRequest): Promise<BaseResponse<EqResponse>>;
  /**
   * Returns AudioId string of initialized audio file
   * @param request 
   */
  initAudioFile(request: InitChannelRequest): Promise<BaseResponse<InitResponse>>;
  /**
   * Returns void, allows user to adjust volume
   * @param request 
   */
  adjustVolume(request: AdjustVolumeRequest): Promise<BaseResponse<null>>;
  /**
   * Returns void, allows user to adjust gain and frequency in bass, mid, and treble ranges
   * @param request 
   */
  adjustEq(request: AdjustEqRequest): Promise<BaseResponse<null>>;

  setElapsedTimeEvent(request: SetEventRequest): Promise<BaseResponse<null>>; // Gonna get rid of this, no comments
  /**
   * Returns an object representing hours, minutes, seconds, and milliseconds elapsed
   * @param request 
   */
  getElapsedTime(request: BaseMixerRequest): Promise<BaseResponse<MixerTimeResponse>>;
  /**
   * Returns total time in an object of hours, minutes, seconds, and millisecond totals
   * @param request 
   */
  getTotalTime(request: BaseMixerRequest): Promise<BaseResponse<MixerTimeResponse>>;
  /**
   * Returns AudioId string of initialized microphone input
   * @param request 
   */
  initMicInput(request: InitChannelRequest): Promise<BaseResponse<InitResponse>>;
}

