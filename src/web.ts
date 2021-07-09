import { WebPlugin } from '@capacitor/core';
import {
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
  PlaybackStateBoolean,
  PlaybackStateResponse,
  ResponseStatus,
  SetEventRequest,
  VolumeResponse,
  DestroyResponse
} from './definitions';

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

  async play(options: BaseMixerRequest): Promise<BaseResponse<PlaybackStateResponse>> {
    console.log('ECHO', options);
    return { status: ResponseStatus.ERROR, message: "not implemented", data: { state: options.audioId } };
  }

  async stop(options: BaseMixerRequest): Promise<BaseResponse<PlaybackStateResponse>> {
    console.log('boi', options);
    return { status: ResponseStatus.ERROR, message: "not implemented", data: { state: options.audioId } };
  }

  async isPlaying(options: BaseMixerRequest): Promise<BaseResponse<PlaybackStateBoolean>> {
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
        bassGain: -1, bassFreq: -1,
        midGain: -1, midFreq: -1,
        trebleGain: -1, trebleFreq: -1
      }
    };
  }

  async initAudioSession(): Promise<BaseResponse<InitResponse>> {
    console.log('not implemented')
    return { status: ResponseStatus.ERROR, message: "not implemented", data: { value: "not implemented" } };
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

const Mixer = new MixerWeb();

export { Mixer };

import { registerWebPlugin } from '@capacitor/core';
registerWebPlugin(Mixer);
