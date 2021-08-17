# Mixer Plugin by Skylabs Technology

## Android
### Usage
Minimum target deployment: 28

to set this value you can add this to your ./android/variables.gradle
```gradle
ext {
    minSdkVersion = 28
}
```
### Permissions
```xml
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
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"></uses-permission>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"></uses-permission>
<uses-permission android:name="android.permission.RECORD_AUDIO"></uses-permission>
<uses-permission android:name="android.permission.READ_PHONE_STATE"></uses-permission>
```
# API

<docgen-index>

* [`requestMixerPermissions()`](#requestmixerpermissions)
* [`addListener(string, ...)`](#addlistenerstring-)
* [`addListener(string, ...)`](#addlistenerstring-)
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
* [Type Aliases](#type-aliases)
* [Enums](#enums)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### requestMixerPermissions()

```typescript
requestMixerPermissions() => Promise<BaseResponse<null>>
```

Requests permissions required by the mixer plugin

- iOS: Permissions must be added to application in the Info Target Properties

- Android: Permissions must be added to AndroidManifest.XML

See README for additional information on permissions

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;null&gt;&gt;</code>

--------------------


### addListener(string, ...)

```typescript
addListener(eventName: string, listenerFunc: (response: AudioSessionEvent) => void) => Promise<PluginListenerHandle> & PluginListenerHandle
```

Adds listener for AudioSession events

Ex: 

Register Listener:
```typescript
Mixer.addListener("myEventName", this.myListenerFunction.bind(this));

myListenerFunction(response: <a href="#audiosessionevent">AudioSessionEvent</a>) { 
 // handle event 
}
```

| Param              | Type                                                                                   |
| ------------------ | -------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>string</code>                                                                    |
| **`listenerFunc`** | <code>(response: <a href="#audiosessionevent">AudioSessionEvent</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt; & <a href="#pluginlistenerhandle">PluginListenerHandle</a></code>

--------------------


### addListener(string, ...)

```typescript
addListener(eventName: string, listenerFunc: (response: MixerTimeEvent) => void) => Promise<PluginListenerHandle> & PluginListenerHandle
```

Adds listener for audio track time update events

Ex: 

Register Listener: 
```typescript
Mixer.addListener("myEventName", this.myListenerFunction.bind(this));

myListenerFunction(response: <a href="#mixertimeevent">MixerTimeEvent</a>) { 
 // handle event 
}
```

| Param              | Type                                                                                   |
| ------------------ | -------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>string</code>                                                                    |
| **`listenerFunc`** | <code>(response: <a href="#mixertimeresponse">MixerTimeResponse</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt; & <a href="#pluginlistenerhandle">PluginListenerHandle</a></code>

--------------------


### addListener(string, ...)

```typescript
addListener(eventName: string, listenerFunc: (response: VolumeMeterEvent) => void) => Promise<PluginListenerHandle> & PluginListenerHandle
```

Adds listener for volume metering update events

Ex: 

Register Listener: 
```typescript
Mixer.addListener("myEventName", this.myListenerFunction.bind(this));

myListenerFunction(response: <a href="#audiosessionevent">AudioSessionEvent</a>) { 
 // handle event 
}
```

| Param              | Type                                                                                 |
| ------------------ | ------------------------------------------------------------------------------------ |
| **`eventName`**    | <code>string</code>                                                                  |
| **`listenerFunc`** | <code>(response: <a href="#volumemeterevent">VolumeMeterEvent</a>) =&gt; void</code> |

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
isPlaying(request: BaseMixerRequest) => Promise<BaseResponse<IsPlayingResponse>>
```

A boolean that returns the playback state of initialized audio file

| Param         | Type                                                          |
| ------------- | ------------------------------------------------------------- |
| **`request`** | <code><a href="#basemixerrequest">BaseMixerRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#isplayingresponse">IsPlayingResponse</a>&gt;&gt;</code>

--------------------


### getCurrentVolume(...)

```typescript
getCurrentVolume(request: ChannelPropertyRequest) => Promise<BaseResponse<VolumeResponse>>
```

Returns current volume of a channel as a number between 0 and 1

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

Adjusts volume for a channel

| Param         | Type                                                                |
| ------------- | ------------------------------------------------------------------- |
| **`request`** | <code><a href="#adjustvolumerequest">AdjustVolumeRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;null&gt;&gt;</code>

--------------------


### adjustEq(...)

```typescript
adjustEq(request: AdjustEqRequest) => Promise<BaseResponse<null>>
```

Adjusts gain and frequency in bass, mid, and treble ranges for a channel

| Param         | Type                                                        |
| ------------- | ----------------------------------------------------------- |
| **`request`** | <code><a href="#adjusteqrequest">AdjustEqRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;null&gt;&gt;</code>

--------------------


### setElapsedTimeEvent(...)

```typescript
setElapsedTimeEvent(request: SetEventRequest) => Promise<BaseResponse<null>>
```

Sets an elapsed time event name for a given audioId. To unset elapsedTimeEvent 
pass an empty string and this will stop the event from being triggered.

Only applicable for audio files

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

Initializes microphone channel on mixer

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

Returns the channel count and name of the initialized audio device

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#channelcountresponse">ChannelCountResponse</a>&gt;&gt;</code>

--------------------


### initAudioSession(...)

```typescript
initAudioSession(request: InitAudioSessionRequest) => Promise<BaseResponse<InitAudioSessionResponse>>
```

Initializes audio session with selected port type,

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

Cancels audio session and resets selected port. Use prior to changing port type

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;null&gt;&gt;</code>

--------------------


### resetPlugin()

```typescript
resetPlugin() => Promise<BaseResponse<null>>
```

Resets plugin state back to its initial state

&lt;span style="color: 'red'"&gt;CAUTION: This will completely wipe everything you have initialized from the plugin!&lt;/span&gt;

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

De-initializes a mic input channel based on audioId

Note: Once destroyed, the channel cannot be recovered

| Param         | Type                                                          | Description |
| ------------- | ------------------------------------------------------------- | ----------- |
| **`request`** | <code><a href="#basemixerrequest">BaseMixerRequest</a></code> | audioId     |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#destroyresponse">DestroyResponse</a>&gt;&gt;</code>

--------------------


### destroyAudioFile(...)

```typescript
destroyAudioFile(request: BaseMixerRequest) => Promise<BaseResponse<DestroyResponse>>
```

De-initializes an audio file channel based on audioId

Note: Once destroyed, the channel cannot be recovered

| Param         | Type                                                          | Description |
| ------------- | ------------------------------------------------------------- | ----------- |
| **`request`** | <code><a href="#basemixerrequest">BaseMixerRequest</a></code> | audioId     |

**Returns:** <code>Promise&lt;<a href="#baseresponse">BaseResponse</a>&lt;<a href="#destroyresponse">DestroyResponse</a>&gt;&gt;</code>

--------------------


### Interfaces


#### BaseResponse

The response wrapper for all response objects

| Prop          | Type                                                      | Description                                                                                |
| ------------- | --------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| **`status`**  | <code><a href="#responsestatus">ResponseStatus</a></code> | Status of returned request. Ex: 'SUCCESS', 'ERROR'                                         |
| **`message`** | <code>string</code>                                       | Message that describes response Note: Can be used for user messages                        |
| **`data`**    | <code>T</code>                                            | Response data object field Ex: A <a href="#mixertimeresponse">MixerTimeResponse</a> object |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


#### AudioSessionEvent

Event response for handling audio session notifications

| Prop              | Type                                                                          | Description                  |
| ----------------- | ----------------------------------------------------------------------------- | ---------------------------- |
| **`handlerType`** | <code><a href="#audiosessionhandlertypes">AudioSessionHandlerTypes</a></code> | The event type that occurred |


#### MixerTimeResponse

Response representing HH:MM:SS.ms-formatted time

| Prop               | Type                | Description          |
| ------------------ | ------------------- | -------------------- |
| **`milliSeconds`** | <code>number</code> | ms in formatted time |
| **`seconds`**      | <code>number</code> | SS in formatted time |
| **`minutes`**      | <code>number</code> | MM in formatted time |
| **`hours`**        | <code>number</code> | HH in formatted time |


#### VolumeMeterEvent

Event response for handling current volume level

| Prop             | Type                | Description                                     |
| ---------------- | ------------------- | ----------------------------------------------- |
| **`meterLevel`** | <code>number</code> | Calculated amplitude in dB - Range: -80 to 0 dB |


#### PlaybackStateResponse

Response that returns <a href="#playerstate">PlayerState</a>

| Prop        | Type                                                | Description                        |
| ----------- | --------------------------------------------------- | ---------------------------------- |
| **`state`** | <code><a href="#playerstate">PlayerState</a></code> | Represents the state of the player |


#### BaseMixerRequest

Base class for all mixer requests, consists of audioId only

| Prop          | Type                | Description                                                        |
| ------------- | ------------------- | ------------------------------------------------------------------ |
| **`audioId`** | <code>string</code> | A string identifying the audio file or microphone channel instance |


#### IsPlayingResponse

Response for tracking player state as a boolean

| Prop        | Type                 | Description                   |
| ----------- | -------------------- | ----------------------------- |
| **`value`** | <code>boolean</code> | Value of tracked player state |


#### VolumeResponse

Response for tracking channel volume

| Prop         | Type                | Description                     |
| ------------ | ------------------- | ------------------------------- |
| **`volume`** | <code>number</code> | Value of tracked channel volume |


#### ChannelPropertyRequest

Request to get info about channel properties such as current volume, EQ, etc.

| Prop            | Type                                            | Description                                           |
| --------------- | ----------------------------------------------- | ----------------------------------------------------- |
| **`inputType`** | <code><a href="#inputtype">InputType</a></code> | Type of input on which properties are being requested |


#### EqResponse

Response for tracking channel EQ

| Prop                  | Type                | Description                                                     |
| --------------------- | ------------------- | --------------------------------------------------------------- |
| **`bassGain`**        | <code>number</code> | Bass gain for channel - Range: -36 to +15 dB                    |
| **`bassFrequency`**   | <code>number</code> | Bass frequency for channel - Suggested range: 20Hz to 499Hz     |
| **`midGain`**         | <code>number</code> | Mid gain for channel - Range: -36 to +15 dB                     |
| **`midFrequency`**    | <code>number</code> | Mid frequency for channel - Suggested range: 500Hz to 1499Hz    |
| **`trebleGain`**      | <code>number</code> | Treble gain for channel - Range: -36 to +15 dB                  |
| **`trebleFrequency`** | <code>number</code> | Treble frequency for channel - Suggested range: 1.5kHz to 20kHz |


#### InitResponse

Response for initialization of channel

| Prop        | Type                | Description                 |
| ----------- | ------------------- | --------------------------- |
| **`value`** | <code>string</code> | Initialized channel audioId |


#### InitChannelRequest

Request used to initialize a channel on the mixer

| Prop                       | Type                | Description                                                                                                                                                              |
| -------------------------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **`filePath`**             | <code>string</code> | A string identifying the path to the audio file on device. Unused if initializing microphone channel                                                                     |
| **`elapsedTimeEventName`** | <code>string</code> | A string identifying the elapsed time event name. This will automatically set the event and setElapsedTimeEvent is not needed. Unused if initializing microphone channel |
| **`channelNumber`**        | <code>number</code> | The channel number being initialized for microphone. Unused if initializing audio file                                                                                   |
| **`bassGain`**             | <code>number</code> | Optional bass gain setting for initialization: -36dB to +15 dB Default: 0dB                                                                                              |
| **`bassFrequency`**        | <code>number</code> | Optional init eq setting for bass EQ band iOS Default: 115Hz Android Default: 200Hz                                                                                      |
| **`midGain`**              | <code>number</code> | Optional mid gain setting for initialization: -36dB to +15 dB Default: 0dB                                                                                               |
| **`midFrequency`**         | <code>number</code> | Optional init setting for mid EQ band iOS Default: 500Hz Android Default: 1499Hz                                                                                         |
| **`trebleGain`**           | <code>number</code> | Optional treble gain setting for initialization: -36dB to +15 dB Default: 0dB                                                                                            |
| **`trebleFrequency`**      | <code>number</code> | Optional init eq setting for treble EQ band iOS Default: 1.5kHz Android Default: 20kHz                                                                                   |
| **`volume`**               | <code>number</code> | Optional init setting for volume Default: 1 Range: 0 - 1                                                                                                                 |
| **`channelListenerName`**  | <code>string</code> | Required name used to set listener for volume metering Subscribed event returns VolumeMeterEvent Note: if empty string is passed, metering will be disabled on channel   |


#### AdjustVolumeRequest

For mixer requests manipulating volume level

| Prop            | Type                                            | Description                                                |
| --------------- | ----------------------------------------------- | ---------------------------------------------------------- |
| **`volume`**    | <code>number</code>                             | A number between 0 and 1 specifying volume level being set |
| **`inputType`** | <code><a href="#inputtype">InputType</a></code> | Type of input on which volume is being adjusted            |


#### AdjustEqRequest

For mixer requests manipulating EQ

| Prop            | Type                                            | Description                                                                                                                                                                                                                                                                 |
| --------------- | ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`eqType`**    | <code><a href="#eqtype">EqType</a></code>       | Identifies EQ band to adjust: Bass, Mid, Treble                                                                                                                                                                                                                             |
| **`gain`**      | <code>number</code>                             | A number between -36dB and +15dB identifying EQ band gain                                                                                                                                                                                                                   |
| **`frequency`** | <code>number</code>                             | A number identifying cutoff/central frequency for EQ band Bass: - iOS implemented as a low shelf - Android implemented as a high pass filter Mid: - implemented as a parametric 'bump' Treble: - iOS implemented as a high shelf - Android implemented as a low pass filter |
| **`inputType`** | <code><a href="#inputtype">InputType</a></code> | Type of input on which EQ is being adjusted                                                                                                                                                                                                                                 |


#### SetEventRequest

Request to set an event listener

| Prop            | Type                | Description                                                                                                            |
| --------------- | ------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **`eventName`** | <code>string</code> | The name of the event that will be subscribed to Subscribed event returns <a href="#mixertimeevent">MixerTimeEvent</a> |


#### ChannelCountResponse

Response for channel count of requested audio port

| Prop               | Type                | Description                                    |
| ------------------ | ------------------- | ---------------------------------------------- |
| **`channelCount`** | <code>number</code> | Number of channels found                       |
| **`deviceName`**   | <code>string</code> | Name of the device at the requested audio port |


#### InitAudioSessionResponse

Response for initalizing audio session

| Prop                            | Type                                                                  | Description                                                        |
| ------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------ |
| **`preferredInputPortType`**    | <code><a href="#audiosessionporttype">AudioSessionPortType</a></code> | Type found when initializing audio session                         |
| **`preferredInputPortName`**    | <code>string</code>                                                   | Device name found when initializing audio session                  |
| **`preferredIOBufferDuration`** | <code>number</code>                                                   | iOS only Preferred buffer duration when initializing audio session |


#### InitAudioSessionRequest

Request to initialize an audio session

| Prop                           | Type                                                                  | Description                                                                                                                                 |
| ------------------------------ | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| **`inputPortType`**            | <code><a href="#audiosessionporttype">AudioSessionPortType</a></code> | An enum describing input hardware device to be used                                                                                         |
| **`ioBufferDuration`**         | <code>number</code>                                                   | iOS only The preferred duration of the input buffer (0.05 recommended as a starting point, change may be observed as output latency)        |
| **`audioSessionListenerName`** | <code>string</code>                                                   | The name of the audio session event that will be subscribed to. Subscribed event returns <a href="#audiosessionevent">AudioSessionEvent</a> |


#### DestroyResponse

Response for destroying a channel

| Prop                       | Type                | Description                                                                                |
| -------------------------- | ------------------- | ------------------------------------------------------------------------------------------ |
| **`listenerName`**         | <code>string</code> | The name of the volume metering event Note: If no event is found, empty string is returned |
| **`elapsedTimeEventName`** | <code>string</code> | The name of the elapsed time event Note: If no event is found, empty string is returned    |


### Type Aliases


#### MixerTimeEvent

Event response for handling current elapsed time

<code><a href="#mixertimeresponse">MixerTimeResponse</a></code>


#### PlayerState

Possible states of player

<code>"play" | "pause" | "stop" | "not implemented"</code>


### Enums


#### ResponseStatus

| Members       | Value                  |
| ------------- | ---------------------- |
| **`SUCCESS`** | <code>"success"</code> |
| **`ERROR`**   | <code>"error"</code>   |


#### AudioSessionHandlerTypes

| Members                         | Value                                    | Description                                                                                                                 |
| ------------------------------- | ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **`INTERRUPT_BEGAN`**           | <code>"INTERRUPT_BEGAN"</code>           | Invoked when another audio session has started This can cause your audio to be 'ducked', or silenced with the audio session |
| **`INTERRUPT_ENDED`**           | <code>"INTERRUPT_ENDED"</code>           | Invoked when another audio session has ended Your audio session should resume                                               |
| **`ROUTE_DEVICE_DISCONNECTED`** | <code>"ROUTE_DEVICE_DISCONNECTED"</code> | Invoked when the device you're currently connected to is disconnected from the audio session                                |
| **`ROUTE_DEVICE_RECONNECTED`**  | <code>"ROUTE_DEVICE_RECONNECTED"</code>  | Invoked when previously-used device is reconnected to the audio session                                                     |
| **`ROUTE_NEW_DEVICE_FOUND`**    | <code>"ROUTE_NEW_DEVICE_FOUND"</code>    | Invoked when previously-UNUSED device is connected to the audio session                                                     |


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

| Members                 | Value                          | Description |
| ----------------------- | ------------------------------ | ----------- |
| **`HDMI`**              | <code>"hdmi"</code>            |             |
| **`AIRPLAY`**           | <code>"airplay"</code>         | iOS only    |
| **`BLUETOOTH_A2DP`**    | <code>"bluetoothA2DP"</code>   |             |
| **`BLUETOOTH_HFP`**     | <code>"bluetoothHFP"</code>    |             |
| **`BLUETOOTH_LE`**      | <code>"bluetoothLE"</code>     | iOS only    |
| **`BUILT_IN_MIC`**      | <code>"builtInMic"</code>      |             |
| **`HEADSET_MIC_WIRED`** | <code>"headsetMicWired"</code> | iOS only    |
| **`HEADSET_MIC_USB`**   | <code>"headsetMicUsb"</code>   |             |
| **`LINE_IN`**           | <code>"lineIn"</code>          |             |
| **`THUNDERBOLT`**       | <code>"thunderbolt"</code>     | iOS only    |
| **`USB_AUDIO`**         | <code>"usbAudio"</code>        |             |
| **`VIRTUAL`**           | <code>"virtual"</code>         |             |

</docgen-api>