//#region Request Objects

import type { PluginListenerHandle } from "@capacitor/core";

/**
 * Base class for all mixer requests, consists of audioId only
 */
export interface BaseMixerRequest {
  /**
   * A string identifying the audio file or microphone channel instance
   */
  audioId: string;
}

/**
 * Request used to initialize a channel on the mixer
 */
export interface InitChannelRequest extends BaseMixerRequest {
  /**
   * A string identifying the path to the audio file on device. 
   * 
   * Unused if initializing microphone channel
   */
  filePath?: string;
  /**
   * A string identifying the elapsed time event name. This will automatically
   * set the event and setElapsedTimeEvent is not needed.
   * 
   * Unused if initializing microphone channel
   */
  elapsedTimeEventName?: string;
  /**
   * The channel number being initialized for microphone. 
   * 
   * Unused if initializing audio file
   */
  channelNumber?: number;
  /**
   * Optional bass gain setting for initialization: -36dB to +15 dB
   * 
   * Default: 0dB
   */
  bassGain?: number;
  /**
   * Optional init eq setting for bass EQ band
   * 
   * iOS Default: 115Hz
   * 
   * Android Default: 200Hz
   */
  bassFrequency?: number;
  /**
   * Optional mid gain setting for initialization: -36dB to +15 dB
   * 
   * Default: 0dB
   */
  midGain?: number;
  /**
   * Optional init setting for mid EQ band
   * 
   * iOS Default: 500Hz
   * 
   * Android Default: 1499Hz
   */
  midFrequency?: number;
  /**
   * Optional treble gain setting for initialization: -36dB to +15 dB
   * 
   * Default: 0dB
   */
  trebleGain?: number;
  /**
   * Optional init eq setting for treble EQ band
   * 
   * iOS Default: 1.5kHz
   * 
   * Android Default: 20kHz
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
   * Subscribed event returns VolumeMeterEvent
   * 
   * Note: if empty string is passed, metering will be disabled on channel
   */
  channelListenerName: string;
}

/**
 * For mixer requests manipulating volume level
 */
export interface AdjustVolumeRequest extends BaseMixerRequest {
  /**
   * A number between 0 and 1 specifying volume level being set
   */
  volume: number;
  /**
   * Type of input on which volume is being adjusted
   */
  inputType: InputType;
}

/**
 * For mixer requests manipulating EQ 
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
   * Bass: 
   * - iOS implemented as a low shelf 
   * - Android implemented as a high pass filter
   * 
   * Mid:
   * - implemented as a parametric 'bump'
   * 
   * Treble:
   * - iOS implemented as a high shelf
   * - Android implemented as a low pass filter
   */
  frequency: number;
  /**
   * Type of input on which EQ is being adjusted
   */
  inputType: InputType;
}

/**
 * Request to get info about channel properties such as current volume, EQ, etc.
 */
export interface ChannelPropertyRequest extends BaseMixerRequest {
  /**
   * Type of input on which properties are being requested
   */
  inputType: InputType;
}

/**
 * Request to set an event listener
 */
export interface SetEventRequest extends BaseMixerRequest {
  /**
   * The name of the event that will be subscribed to
   * 
   * Subscribed event returns MixerTimeEvent
   */
  eventName: string;
}
/**
 * Request to initialize an audio session
 */
export interface InitAudioSessionRequest {
  /**
   * An enum describing input hardware device to be used
   */
  inputPortType?: AudioSessionPortType,
  /**
   * iOS only
   * 
   * The preferred duration of the input buffer (0.05 recommended as a starting point, change may be observed as output latency)
   */
  ioBufferDuration?: number,
  /**
   * The name of the audio session event that will be subscribed to.
   * 
   * Subscribed event returns AudioSessionEvent
   */
  audioSessionListenerName?: string
}
//#endregion

//#region Response Objects

/**
 * The response wrapper for all response objects
 */
export interface BaseResponse<T> {
  /**
   * Status of returned request. 
   * 
   * Ex: 'SUCCESS', 'ERROR'
   */
  status: ResponseStatus,
  /**
   * Message that describes response
   * 
   * Note: Can be used for user messages
   */
  message: string,
  /**
   * Response data object field
   * 
   * Ex: A MixerTimeResponse object
   */
  data: T
}

/**
 * Response representing HH:MM:SS.ms-formatted time
 */
export interface MixerTimeResponse {
  /**
   * ms in formatted time
   */
  milliSeconds: number,
  /**
   * SS in formatted time
   */
  seconds: number,
  /**
   * MM in formatted time
   */
  minutes: number,
  /**
   * HH in formatted time
   */
  hours: number
}

/**
 * Response that returns PlayerState
 */
export interface PlaybackStateResponse {
  /**
   * Represents the state of the player
   */
  state: PlayerState
}

/**
 * Response for tracking player state as a boolean
 */
export interface IsPlayingResponse {
  /**
   * Value of tracked player state
   */
  value: boolean
}

/**
 * Response for tracking channel volume
 */
export interface VolumeResponse {
  /**
   * Value of tracked channel volume
   */
  volume: number
}

/**
 * Response for tracking channel EQ
 */
export interface EqResponse {
  /**
   * Bass gain for channel
   * 
   * - Range: -36 to +15 dB
   */
  bassGain: number
  /**
   * Bass frequency for channel
   * 
   * - Suggested range: 20Hz to 499Hz
   */
  bassFrequency: number
  /**
   * Mid gain for channel
   * 
   * - Range: -36 to +15 dB
   */
  midGain: number
  /**
   * Mid frequency for channel
   * 
   * - Suggested range: 500Hz to 1499Hz
   */
  midFrequency: number
  /**
   * Treble gain for channel
   * 
   * - Range: -36 to +15 dB
   */
  trebleGain: number
  /**
   * Treble frequency for channel
   * 
   * - Suggested range: 1.5kHz to 20kHz
   */
  trebleFrequency: number
}

/**
 * Response for initialization of channel
 */
export interface InitResponse {
  /**
   * Initialized channel audioId
   */
  value: string
}

/**
 * Response for channel count of requested audio port
 */
export interface ChannelCountResponse {
  /**
   * Number of channels found
   */
  channelCount: number
  /**
   * Name of the device at the requested audio port
   */
  deviceName: string
}

/**
 * Response for destroying a channel
 */
export interface DestroyResponse {
  /**
   * The name of the volume metering event
   * 
   * Note: If no event is found, empty string is returned
   */
  listenerName: string
  /**
   * The name of the elapsed time event
   * 
   * Note: If no event is found, empty string is returned
   */
  elapsedTimeEventName: string
}

/**
 * Response for initalizing audio session
 */
export interface InitAudioSessionResponse {
  /**
   * Type found when initializing audio session
   */
  preferredInputPortType: AudioSessionPortType,
  /**
   * Device name found when initializing audio session
   */
  preferredInputPortName: string,
  /**
   * iOS only 
   * 
   * Preferred buffer duration when initializing audio session 
   */
  preferredIOBufferDuration: number
}

//#endregion

//#region Event Objects

/**
 * Event response for handling audio session notifications
 */
export interface AudioSessionEvent {
  /**
   * The event type that occurred
   */
  handlerType: AudioSessionHandlerTypes;
}

/**
 * Event response for handling current elapsed time
 */
export type MixerTimeEvent = MixerTimeResponse

/**
 * Event response for handling current volume level
 */
export interface VolumeMeterEvent {
  /**
   * Calculated amplitude in dB
   * 
   * - Range: -80 to 0 dB
   */
  meterLevel: number
}

//#endregion

/**
 * Possible states of player
 */
export type PlayerState = "play" | "pause" | "stop" | "not implemented";

/**
 * Status of the given response
 */
export enum ResponseStatus {
  SUCCESS = "success",
  ERROR = "error"
}

/**
 * Band selection for EQ
 */
export enum EqType {
  BASS = "bass",
  MID = "mid",
  TREBLE = "treble"
}

/**
 * Channel type selection for mixer
 */
export enum InputType {
  MIC = "mic",
  FILE = "file"
}

/**
 * Audio Session port type
 */
export enum AudioSessionPortType {
  // AVB = "avb",
  HDMI = "hdmi",
  // PCI = "pci",
  /**
   * iOS only
   */
  AIRPLAY = "airplay",
  BLUETOOTH_A2DP = "bluetoothA2DP",
  BLUETOOTH_HFP = "bluetoothHFP",
  /**
   * iOS only
   */
  BLUETOOTH_LE = "bluetoothLE",
  BUILT_IN_MIC = "builtInMic",
  /**
   * iOS only
   */
  HEADSET_MIC_WIRED = "headsetMicWired",
  HEADSET_MIC_USB = "headsetMicUsb",
  LINE_IN = "lineIn",
  /**
   * iOS only
   */
  THUNDERBOLT = "thunderbolt",
  USB_AUDIO = "usbAudio",
  VIRTUAL = "virtual"
}

/**
 * Response types for Audio Session events
 */
export enum AudioSessionHandlerTypes {
  /**
   * Invoked when another audio session has started
   * 
   * This can cause your audio to be 'ducked', or silenced with the audio session
   */
  INTERRUPT_BEGAN = "INTERRUPT_BEGAN",
  /**
   * Invoked when another audio session has ended
   * 
   * Your audio session should resume
   */
  INTERRUPT_ENDED = "INTERRUPT_ENDED",
  /**
   * Invoked when the device you're currently connected to is disconnected from the audio session
   */
  ROUTE_DEVICE_DISCONNECTED = "ROUTE_DEVICE_DISCONNECTED",
  /**
   * Invoked when previously-used device is reconnected to the audio session
   */
  ROUTE_DEVICE_RECONNECTED = "ROUTE_DEVICE_RECONNECTED",
  /**
   * Invoked when previously-UNUSED device is connected to the audio session
   */
  ROUTE_NEW_DEVICE_FOUND = "ROUTE_NEW_DEVICE_FOUND"
}

export interface MixerPlugin {

  /**
   * Requests permissions required by the mixer plugin
   * 
   * - iOS: Permissions must be added to application in the Info Target Properties
   * 
   * - Android: Permissions must be added to AndroidManifest.XML
   * 
   * See README for additional information on permissions
   */
  requestMixerPermissions(): Promise<BaseResponse<null>>;

  /**
   * Adds listener for AudioSession events
   * 
   * Ex: 
   * 
   * Register Listener:
   * ```typescript
   * Mixer.addListener("myEventName", this.myListenerFunction.bind(this));
   * 
   * myListenerFunction(response: AudioSessionEvent) { 
   *  // handle event 
   * }
   * ```
   * @param eventName 
   * @param listenerFunc 
   */
  addListener(eventName: string, listenerFunc: (response: AudioSessionEvent) => void): Promise<PluginListenerHandle> & PluginListenerHandle;

  /**
   * Adds listener for audio track time update events
   * 
   * Ex: 
   * 
   * Register Listener: 
   * ```typescript
   * Mixer.addListener("myEventName", this.myListenerFunction.bind(this));
   * 
   * myListenerFunction(response: MixerTimeEvent) { 
   *  // handle event 
   * }
   * ```
   * @param eventName 
   * @param listenerFunc 
   */
  addListener(eventName: string, listenerFunc: (response: MixerTimeEvent) => void): Promise<PluginListenerHandle> & PluginListenerHandle;

  /**
   * Adds listener for volume metering update events
   * 
   * Ex: 
   * 
   * Register Listener: 
   * ```typescript
   * Mixer.addListener("myEventName", this.myListenerFunction.bind(this));
   * 
   * myListenerFunction(response: AudioSessionEvent) { 
   *  // handle event 
   * }
   * ```
   * @param eventName 
   * @param listenerFunc 
   */
  addListener(eventName: string, listenerFunc: (response: VolumeMeterEvent) => void): Promise<PluginListenerHandle> & PluginListenerHandle;

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
   * A boolean that returns the playback state of initialized audio file
   * @param request 
   */
  isPlaying(request: BaseMixerRequest): Promise<BaseResponse<IsPlayingResponse>>;

  /**
   * Returns current volume of a channel as a number between 0 and 1
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
   * Adjusts volume for a channel
   * @param request 
   */
  adjustVolume(request: AdjustVolumeRequest): Promise<BaseResponse<null>>;

  /**
   * Adjusts gain and frequency in bass, mid, and treble ranges for a channel
   * @param request 
   */
  adjustEq(request: AdjustEqRequest): Promise<BaseResponse<null>>;

  /**
   * Sets an elapsed time event name for a given audioId. To unset elapsedTimeEvent 
   * pass an empty string and this will stop the event from being triggered.
   * 
   * Only applicable for audio files
   * @param request 
   */
  setElapsedTimeEvent(request: SetEventRequest): Promise<BaseResponse<null>>;

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
   * Initializes microphone channel on mixer
   * 
   * Returns AudioId string of initialized microphone input
   * @param request 
   */
  initMicInput(request: InitChannelRequest): Promise<BaseResponse<InitResponse>>;

  /**
   * Returns the channel count and name of the initialized audio device
   */
  getInputChannelCount(): Promise<BaseResponse<ChannelCountResponse>>;

  /**
   * Initializes audio session with selected port type,
   * 
   * Returns a value describing the initialized port type for the audio session (usb, built-in, etc.)
   * @param request
   */
  initAudioSession(request: InitAudioSessionRequest): Promise<BaseResponse<InitAudioSessionResponse>>;

  /**
   * Cancels audio session and resets selected port. Use prior to changing port type
   */
  deinitAudioSession(): Promise<BaseResponse<null>>;

  /**
   * Resets plugin state back to its initial state
   * 
   * <span style="color: 'red'">CAUTION: This will completely wipe everything you have initialized from the plugin!</span>
   */
  resetPlugin(): Promise<BaseResponse<null>>;

  /**
   * Returns a value describing the initialized port type for the audio session (usb, built-in, etc.)
   */
  getAudioSessionPreferredInputPortType(): Promise<BaseResponse<InitResponse>>;

  /**
   * De-initializes a mic input channel based on audioId
   * 
   * Note: Once destroyed, the channel cannot be recovered
   * @param request audioId
   */
  destroyMicInput(request: BaseMixerRequest): Promise<BaseResponse<DestroyResponse>>;

  /**
   * De-initializes an audio file channel based on audioId
   * 
   * Note: Once destroyed, the channel cannot be recovered
   * @param request audioId
   */
  destroyAudioFile(request: BaseMixerRequest): Promise<BaseResponse<DestroyResponse>>;
}

