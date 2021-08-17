import { WebPlugin } from '@capacitor/core';

import type {
  AdjustEqRequest,
  AdjustVolumeRequest,
  BaseMixerRequest,
  BaseResponse,
  ChannelCountResponse,
  ChannelPropertyRequest,
  EqResponse,
  InitChannelRequest,
  InitResponse,
  MixerPlugin,
  MixerTimeResponse,
  IsPlayingResponse,
  PlaybackStateResponse,
  SetEventRequest,
  VolumeResponse,
  DestroyResponse,
  InitAudioSessionResponse,
  InitAudioSessionRequest
} from './definitions';
import {
  AudioSessionPortType,
  ResponseStatus
} from './definitions'

export class MixerWeb extends WebPlugin implements MixerPlugin {
  constructor() {
    super({
      name: 'Mixer',
      platforms: ['web'],
    });
  }

  async requestMixerPermissions(): Promise<BaseResponse<null>> {
    console.log('request mixer permission');
    return { status: ResponseStatus.ERROR, message: "not implemented", data: null };
  }

  async playOrPause(options: BaseMixerRequest): Promise<BaseResponse<PlaybackStateResponse>> {
    console.log('ECHO', options);
    return { status: ResponseStatus.ERROR, message: "not implemented", data: { state: "play" } };
  }

  async stop(options: BaseMixerRequest): Promise<BaseResponse<PlaybackStateResponse>> {
    console.log('boi', options);
    return { status: ResponseStatus.ERROR, message: "not implemented", data: { state: "stop" } };
  }

  async isPlaying(options: BaseMixerRequest): Promise<BaseResponse<IsPlayingResponse>> {
    console.log('areyouplaying?', options);
    return { status: ResponseStatus.ERROR, message: "not implemented", data: { value: true } };
  }

  async getCurrentVolume(options: ChannelPropertyRequest): Promise<BaseResponse<VolumeResponse>> {
    console.log('how loud is it?', options);
    return { status: ResponseStatus.ERROR, message: "not implemented", data: { volume: -1 } };
  }

  async getCurrentEq(options: ChannelPropertyRequest): Promise<BaseResponse<EqResponse>> {
    console.log('tell us about eq', options);
    return {
      status: ResponseStatus.ERROR, message: "not implemented", data: {
        bassGain: -1, bassFrequency: -1,
        midGain: -1, midFrequency: -1,
        trebleGain: -1, trebleFrequency: -1
      }
    };
  }

  async initAudioSession(request: InitAudioSessionRequest): Promise<BaseResponse<InitAudioSessionResponse>> {
    console.log('not implemented', request)
    return { status: ResponseStatus.ERROR, message: "not implemented for the web", data: { preferredIOBufferDuration: -1, preferredInputPortName: "", preferredInputPortType: AudioSessionPortType.BUILT_IN_MIC } };
  }

  async deinitAudioSession(): Promise<BaseResponse<null>> {
    console.log('not implemented')
    return { status: ResponseStatus.ERROR, message: "not implemented", data: null };
  }

  async resetPlugin(): Promise<BaseResponse<null>> {
    console.log('not implemented')
    return { status: ResponseStatus.ERROR, message: "not implemented", data: null };
  }

  async getAudioSessionPreferredInputPortType(): Promise<BaseResponse<InitResponse>> {
    console.log('not implemented')
    return { status: ResponseStatus.ERROR, message: "not implemented", data: { value: "not implemented" } };
  }

  async destroyMicInput(request: BaseMixerRequest): Promise<BaseResponse<DestroyResponse>> {
    console.log('not implemented', request)
    return { status: ResponseStatus.ERROR, message: "not implemented", data: { listenerName: "", elapsedTimeEventName: "" } };
  }

  async destroyAudioFile(request: BaseMixerRequest): Promise<BaseResponse<DestroyResponse>> {
    console.log('not implemented', request)
    return { status: ResponseStatus.ERROR, message: "not implemented", data: { listenerName: "", elapsedTimeEventName: "" } };
  }



  async initAudioFile(options: InitChannelRequest): Promise<BaseResponse<InitResponse>> {
    console.log('Not Implemented', options);
    return { status: ResponseStatus.ERROR, message: "not implemented", data: { value: `${options.filePath} ${options.audioId}` } };
  }

  async adjustVolume(options: AdjustVolumeRequest): Promise<BaseResponse<null>> {
    console.log('adjusting volume', options);
    return { status: ResponseStatus.ERROR, message: "not implemented", data: null };
  }

  async adjustEq(options: AdjustEqRequest): Promise<BaseResponse<null>> {
    console.log('adjusting eq', options);
    return { status: ResponseStatus.ERROR, message: "not implemented", data: null };
  }

  async setElapsedTimeEvent(options: SetEventRequest): Promise<BaseResponse<null>> {
    console.log('Not Implemented', options);
    return { status: ResponseStatus.ERROR, message: "not implemented", data: null };
  }

  async getElapsedTime(options: BaseMixerRequest): Promise<BaseResponse<MixerTimeResponse>> {
    console.log('not implemented', options);
    return { status: ResponseStatus.ERROR, message: "not implemented", data: { milliSeconds: 0, seconds: 0, minutes: 0, hours: 0 } };
  }

  async getTotalTime(options: BaseMixerRequest): Promise<BaseResponse<MixerTimeResponse>> {
    console.log('Not Implemented', options);
    return { status: ResponseStatus.ERROR, message: "not implemented", data: { milliSeconds: 0, seconds: 0, minutes: 0, hours: 0 } };
  }

  async initMicInput(request: InitChannelRequest): Promise<BaseResponse<InitResponse>> {
    console.log('Not Implemented', request);
    return { status: ResponseStatus.ERROR, message: "not implemented", data: { value: `${request.audioId}` } };
  }

  async getInputChannelCount(): Promise<BaseResponse<ChannelCountResponse>> {
    console.log('Not Implemented');
    return { status: ResponseStatus.ERROR, message: "not implemented", data: { channelCount: 0, deviceName: "" } }
  }

}
