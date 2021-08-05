# Mixer Plugin by Skylabs Technology

## Permissions
### Android
```
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="@string/custom_url_scheme" />
</intent-filter>
<intent-filter>
    <action android:name="android.intent.action.OPEN_DOCUMENT" />
    <category android:name="android.intent.category.DEFAULT" />
    <data android:scheme="io.ionic.starter" />
    <data android:mimeType="audio/*" />
</intent-filter>
```
```
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"></uses-permission>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"></uses-permission>
<uses-permission android:name="android.permission.RECORD_AUDIO"></uses-permission>
<uses-permission android:name="android.permission.ACCESS_MEDIA_LOCATION"></uses-permission>
<uses-permission android:name="android.permission.READ_PHONE_STATE"></uses-permission>
```
<docgen-index>

* [Methods](#methods)
* [`addListener(string, ...)`](#addlistenerstring-)
* [`play(...)`](#play)
* [`stop(...)`](#stop)
* [`isPlaying(...)`](#isplaying)
* [`getCurrentVolume(...)`](#getcurrentvolume)
* [`getCurrentEq(...)`](#getcurrenteq)
* [`initAudioFile(...)`](#initaudiofile)
* [`adjustVolume(...)`](#adjustvolume)
* [`adjustEq(...)`](#adjusteq)
* [`setElapsedTimeEvent(...)`](#setelapsedtimeevent)
* [`getElapsedTime(...)`](#getelapsedtime)
* [`getTotalTime(...)`](#gettotaltime)
* [`initMicInput(...)`](#initmicinput)
* [`getInputChannelCount()`](#getinputchannelcount)
* [`initAudioSession(...)`](#initaudiosession)
* [`deinitAudioSession()`](#deinitaudiosession)
* [`resetPlugin()`](#resetplugin)
* [`getAudioSessionPreferredInputPortType()`](#getaudiosessionpreferredinputporttype)
* [`destroyMicInput(...)`](#destroymicinput)
* [`destroyAudioFile(...)`](#destroyaudiofile)
* [Interfaces](#interfaces)
* [Enums](#enums)
----------------------------
</docgen-index>
<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### Methods

### addListener(string, ...)

```typescript
addListener(eventName: string, listenerFunc: Function) => Promise<PluginListenerHandle> & PluginListenerHandle
```

| Param              | Type                                          |
| ------------------ | --------------------------------------------- |
| **`eventName`**    | <code>string</code>                           |
| **`listenerFunc`** | <code><a href="#function">Function</a></code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt; & <a href="#pluginlistenerhandle">PluginListenerHandle</a></code>

--------------------


### play(...)

```typescript
play(request: BaseMixerRequest) => Promise<BaseResponse<PlaybackStateResponse>>
```

Toggles playback and pause on an initialized audio file

| Param         | Type                                                          |
| ------------- | ------------------------------------------------------------- |
| **`request`** | <code><a href="#basemixerrequest">BaseMixerRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#playbackstateresponse">PlaybackStateResponse</a>&gt;&gt;</code>

--------------------


### stop(...)

```typescript
stop(request: BaseMixerRequest) => Promise<BaseResponse<PlaybackStateResponse>>
```

Stops playback on a playing audio file

| Param         | Type                                                          |
| ------------- | ------------------------------------------------------------- |
| **`request`** | <code><a href="#basemixerrequest">BaseMixerRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#playbackstateresponse">PlaybackStateResponse</a>&gt;&gt;</code>

--------------------


### isPlaying(...)

```typescript
isPlaying(request: BaseMixerRequest) => Promise<BaseResponse<PlaybackStateBoolean>>
```

A boolean that reports the playback state of initialized audio file

| Param         | Type                                                          |
| ------------- | ------------------------------------------------------------- |
| **`request`** | <code><a href="#basemixerrequest">BaseMixerRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#playbackstateboolean">PlaybackStateBoolean</a>&gt;&gt;</code>

--------------------


### getCurrentVolume(...)

```typescript
getCurrentVolume(request: ChannelPropertyRequest) => Promise<BaseResponse<VolumeResponse>>
```

Reports current volume of playing audio file as a number between 0 and 1

| Param         | Type                                                                      |
| ------------- | ------------------------------------------------------------------------- |
| **`request`** | <code><a href="#channelpropertyrequest">ChannelPropertyRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#volumeresponse">VolumeResponse</a>&gt;&gt;</code>

--------------------


### getCurrentEq(...)

```typescript
getCurrentEq(request: ChannelPropertyRequest) => Promise<BaseResponse<EqResponse>>
```

Returns an object with numeric values for gain and frequency in bass, mid, and treble ranges

| Param         | Type                                                                      |
| ------------- | ------------------------------------------------------------------------- |
| **`request`** | <code><a href="#channelpropertyrequest">ChannelPropertyRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#eqresponse">EqResponse</a>&gt;&gt;</code>

--------------------


### initAudioFile(...)

```typescript
initAudioFile(request: InitChannelRequest) => Promise<BaseResponse<InitResponse>>
```

Returns AudioId string of initialized audio file

| Param         | Type                                                              |
| ------------- | ----------------------------------------------------------------- |
| **`request`** | <code><a href="#initchannelrequest">InitChannelRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#initresponse">InitResponse</a>&gt;&gt;</code>

--------------------


### adjustVolume(...)

```typescript
adjustVolume(request: AdjustVolumeRequest) => Promise<BaseResponse<null>>
```

Returns void, allows user to adjust volume

| Param         | Type                                                                |
| ------------- | ------------------------------------------------------------------- |
| **`request`** | <code><a href="#adjustvolumerequest">AdjustVolumeRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;null&gt;&gt;</code>

--------------------


### adjustEq(...)

```typescript
adjustEq(request: AdjustEqRequest) => Promise<BaseResponse<null>>
```

Returns void, allows user to adjust gain and frequency in bass, mid, and treble ranges

| Param         | Type                                                        |
| ------------- | ----------------------------------------------------------- |
| **`request`** | <code><a href="#adjusteqrequest">AdjustEqRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;null&gt;&gt;</code>

--------------------


### setElapsedTimeEvent(...)

```typescript
setElapsedTimeEvent(request: SetEventRequest) => Promise<BaseResponse<null>>
```

Sets an elapsed time event for a given audioId. Only applicable for audio files.

| Param         | Type                                                        |
| ------------- | ----------------------------------------------------------- |
| **`request`** | <code><a href="#seteventrequest">SetEventRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;null&gt;&gt;</code>

--------------------


### getElapsedTime(...)

```typescript
getElapsedTime(request: BaseMixerRequest) => Promise<BaseResponse<MixerTimeResponse>>
```

Returns an object representing hours, minutes, seconds, and milliseconds elapsed

| Param         | Type                                                          |
| ------------- | ------------------------------------------------------------- |
| **`request`** | <code><a href="#basemixerrequest">BaseMixerRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#mixertimeresponse">MixerTimeResponse</a>&gt;&gt;</code>

--------------------


### getTotalTime(...)

```typescript
getTotalTime(request: BaseMixerRequest) => Promise<BaseResponse<MixerTimeResponse>>
```

Returns total time in an object of hours, minutes, seconds, and millisecond totals

| Param         | Type                                                          |
| ------------- | ------------------------------------------------------------- |
| **`request`** | <code><a href="#basemixerrequest">BaseMixerRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#mixertimeresponse">MixerTimeResponse</a>&gt;&gt;</code>

--------------------


### initMicInput(...)

```typescript
initMicInput(request: InitChannelRequest) => Promise<BaseResponse<InitResponse>>
```

Returns AudioId string of initialized microphone input

| Param         | Type                                                              |
| ------------- | ----------------------------------------------------------------- |
| **`request`** | <code><a href="#initchannelrequest">InitChannelRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#initresponse">InitResponse</a>&gt;&gt;</code>

--------------------


### getInputChannelCount()

```typescript
getInputChannelCount() => Promise<BaseResponse<ChannelCountResponse>>
```

Returns the count and name of the initialized audio device

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#channelcountresponse">ChannelCountResponse</a>&gt;&gt;</code>

--------------------


### initAudioSession(...)

```typescript
initAudioSession(request: InitAudioSessionRequest) => Promise<BaseResponse<InitAudioSessionResponse>>
```

Initializes audio session with passed-in port type,

Returns a value describing the initialized port type for the audio session (usb, built-in, etc.)

| Param         | Type                                                                        |
| ------------- | --------------------------------------------------------------------------- |
| **`request`** | <code><a href="#initaudiosessionrequest">InitAudioSessionRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#initaudiosessionresponse">InitAudioSessionResponse</a>&gt;&gt;</code>

--------------------


### deinitAudioSession()

```typescript
deinitAudioSession() => Promise<BaseResponse<null>>
```

Sets 'isAudioSessionActive' bool to false, does not reset plugin state

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;null&gt;&gt;</code>

--------------------


### resetPlugin()

```typescript
resetPlugin() => Promise<BaseResponse<null>>
```

Resets plugin state back to its initial state

CAUTION: This will completely wipe everything you have initialized from the plugin!

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;null&gt;&gt;</code>

--------------------


### getAudioSessionPreferredInputPortType()

```typescript
getAudioSessionPreferredInputPortType() => Promise<BaseResponse<InitResponse>>
```

Returns a value describing the initialized port type for the audio session (usb, built-in, etc.)

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#initresponse">InitResponse</a>&gt;&gt;</code>

--------------------


### destroyMicInput(...)

```typescript
destroyMicInput(request: BaseMixerRequest) => Promise<BaseResponse<DestroyResponse>>
```

De-initializes a mic input based on passed-in audioId

| Param         | Type                                                          | Description |
| ------------- | ------------------------------------------------------------- | ----------- |
| **`request`** | <code><a href="#basemixerrequest">BaseMixerRequest</a></code> | audioId     |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#destroyresponse">DestroyResponse</a>&gt;&gt;</code>

--------------------


### destroyAudioFile(...)

```typescript
destroyAudioFile(request: BaseMixerRequest) => Promise<BaseResponse<DestroyResponse>>
```

De-initializes an audio file based on passed-in audioId

| Param         | Type                                                          | Description |
| ------------- | ------------------------------------------------------------- | ----------- |
| **`request`** | <code><a href="#basemixerrequest">BaseMixerRequest</a></code> | audioId     |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#destroyresponse">DestroyResponse</a>&gt;&gt;</code>

--------------------


### Interfaces



#### BaseResponse

| Prop          | Type                                                      |
| ------------- | --------------------------------------------------------- |
| **`status`**  | <code><a href="#responsestatus">ResponseStatus</a></code> |
| **`message`** | <code>string</code>                                       |
| **`data`**    | <code>T</code>                                            |


#### PlaybackStateResponse

| Prop        | Type                |
| ----------- | ------------------- |
| **`state`** | <code>string</code> |


#### BaseMixerRequest

Base class for all mixer requests

| Prop          | Type                | Description                         |
| ------------- | ------------------- | ----------------------------------- |
| **`audioId`** | <code>string</code> | A string identifying the audio file |


#### PlaybackStateBoolean

| Prop        | Type                 |
| ----------- | -------------------- |
| **`value`** | <code>boolean</code> |


#### VolumeResponse

| Prop         | Type                |
| ------------ | ------------------- |
| **`volume`** | <code>number</code> |


#### ChannelPropertyRequest

Get info about channel properties such as current volume, EQ, etc.

| Prop            | Type                                            | Description                                   |
| --------------- | ----------------------------------------------- | --------------------------------------------- |
| **`inputType`** | <code><a href="#inputtype">InputType</a></code> | Select between micophone and audio file input |


#### EqResponse

| Prop             | Type                |
| ---------------- | ------------------- |
| **`bassGain`**   | <code>number</code> |
| **`bassFreq`**   | <code>number</code> |
| **`midGain`**    | <code>number</code> |
| **`midFreq`**    | <code>number</code> |
| **`trebleGain`** | <code>number</code> |
| **`trebleFreq`** | <code>number</code> |


#### InitResponse

| Prop        | Type                |
| ----------- | ------------------- |
| **`value`** | <code>string</code> |


#### InitChannelRequest

For mixer requests specifying filePath on device

| Prop                      | Type                | Description                                                                                                                  |
| ------------------------- | ------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| **`filePath`**            | <code>string</code> | A string identifying the path to the audio file on device. Unused if initializing microphone channel                         |
| **`channelNumber`**       | <code>number</code> | The channel number being initialized for microphone. Unused if initializing audio file                                       |
| **`bassGain`**            | <code>number</code> | Optional bass gain setting for initialization: -36dB to +15 dB Default: 0dB                                                  |
| **`bassFrequency`**       | <code>number</code> | Optional init eq setting for low shelf Default: 115Hz                                                                        |
| **`midGain`**             | <code>number</code> | Optional mid gain setting for initialization: -36dB to +15 dB Default: 0dB                                                   |
| **`midFrequency`**        | <code>number</code> | Optional init setting for parametric mid band Default: 500Hz                                                                 |
| **`trebleGain`**          | <code>number</code> | Optional treble gain setting for initialization: -36dB to +15 dB Default: 0dB                                                |
| **`trebleFrequency`**     | <code>number</code> | Optional init eq setting for high shelf Default: 1.5kHhz                                                                     |
| **`volume`**              | <code>number</code> | Optional init setting for volume Default: 1 Range: 0 - 1                                                                     |
| **`channelListenerName`** | <code>string</code> | Required name used to set listener for volume metering Note: if empty string is passed, metering will be disabled on channel |


#### AdjustVolumeRequest

For mixer requests specifying volume level

| Prop            | Type                                            | Description                                      |
| --------------- | ----------------------------------------------- | ------------------------------------------------ |
| **`volume`**    | <code>number</code>                             | A number between 0 and 1 specifying volume level |
| **`inputType`** | <code><a href="#inputtype">InputType</a></code> | Select between microphone and audio file input   |


#### AdjustEqRequest

For mixer requests interacting with EQ

| Prop            | Type                                            | Description                                                                                                            |
| --------------- | ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **`eqType`**    | <code><a href="#eqtype">EqType</a></code>       | Identifies EQ band to adjust: Bass, Mid, Treble                                                                        |
| **`gain`**      | <code>number</code>                             | A number between -36dB and +15dB identifying EQ band gain                                                              |
| **`frequency`** | <code>number</code>                             | A number identifying cutoff/central frequency for EQ band Bass: &lt;range&gt; Mid: &lt;range&gt; Treble: &lt;range&gt; |
| **`inputType`** | <code><a href="#inputtype">InputType</a></code> | Select between microphone and audio file input                                                                         |


#### SetEventRequest

Request to set an event listener

| Prop            | Type                | Description                                      |
| --------------- | ------------------- | ------------------------------------------------ |
| **`eventName`** | <code>string</code> | The name of the event that will be subscribed to |


#### MixerTimeResponse

| Prop               | Type                |
| ------------------ | ------------------- |
| **`milliSeconds`** | <code>number</code> |
| **`seconds`**      | <code>number</code> |
| **`minutes`**      | <code>number</code> |
| **`hours`**        | <code>number</code> |


#### ChannelCountResponse

| Prop               | Type                |
| ------------------ | ------------------- |
| **`channelCount`** | <code>number</code> |
| **`deviceName`**   | <code>string</code> |


#### InitAudioSessionResponse

| Prop                            | Type                                                                  |
| ------------------------------- | --------------------------------------------------------------------- |
| **`preferredInputPortType`**    | <code><a href="#audiosessionporttype">AudioSessionPortType</a></code> |
| **`preferredInputPortName`**    | <code>string</code>                                                   |
| **`preferredIOBufferDuration`** | <code>number</code>                                                   |


#### InitAudioSessionRequest

| Prop                           | Type                                                                  |
| ------------------------------ | --------------------------------------------------------------------- |
| **`inputPortType`**            | <code><a href="#audiosessionporttype">AudioSessionPortType</a></code> |
| **`ioBufferDuration`**         | <code>number</code>                                                   |
| **`audioSessionListenerName`** | <code>string</code>                                                   |


#### DestroyResponse

listenerName and elapsedTimeEventNames will be populated 
with each appropriate event name. 
If names not found, empty string will be returned.

| Prop                       | Type                |
| -------------------------- | ------------------- |
| **`listenerName`**         | <code>string</code> |
| **`elapsedTimeEventName`** | <code>string</code> |



### Enums


#### ResponseStatus

| Members       | Value                  |
| ------------- | ---------------------- |
| **`SUCCESS`** | <code>"success"</code> |
| **`ERROR`**   | <code>"error"</code>   |


#### InputType

| Members    | Value               |
| ---------- | ------------------- |
| **`MIC`**  | <code>"mic"</code>  |
| **`FILE`** | <code>"file"</code> |


#### EqType

| Members      | Value                 |
| ------------ | --------------------- |
| **`BASS`**   | <code>"bass"</code>   |
| **`MID`**    | <code>"mid"</code>    |
| **`TREBLE`** | <code>"treble"</code> |


#### AudioSessionPortType

| Members                 | Value                          |
| ----------------------- | ------------------------------ |
| **`AVB`**               | <code>"avb"</code>             |
| **`HDMI`**              | <code>"hdmi"</code>            |
| **`PCI`**               | <code>"pci"</code>             |
| **`AIRPLAY`**           | <code>"airplay"</code>         |
| **`BLUETOOTH_A2DP`**    | <code>"bluetoothA2DP"</code>   |
| **`BLUETOOTH_HFP`**     | <code>"bluetoothHFP"</code>    |
| **`BLUETOOTH_LE`**      | <code>"bluetoothLE"</code>     |
| **`BUILT_IN_MIC`**      | <code>"builtInMic"</code>      |
| **`BUILT_IN_RECEIVER`** | <code>"builtInReceiver"</code> |
| **`BUILT_IN_SPEAKER`**  | <code>"builtInSpeaker"</code>  |
| **`CAR_AUDIO`**         | <code>"carAudio"</code>        |
| **`DISPLAY_PORT`**      | <code>"displayPort"</code>     |
| **`FIREWIRE`**          | <code>"firewire"</code>        |
| **`HEADPHONES`**        | <code>"headphones"</code>      |
| **`HEADSET_MIC`**       | <code>"headsetMic"</code>      |
| **`LINE_IN`**           | <code>"lineIn"</code>          |
| **`LINE_OUT`**          | <code>"lineOut"</code>         |
| **`THUNDERBOLT`**       | <code>"thunderbolt"</code>     |
| **`USB_AUDIO`**         | <code>"usbAudio"</code>        |
| **`VIRTUAL`**           | <code>"virtual"</code>         |
----------------------
### Contributing
To start contributing, run `npm run contribute-start` to get the necessary packages and build the project.
</docgen-api>