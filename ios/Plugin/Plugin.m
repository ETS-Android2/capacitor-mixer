#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(Mixer, "Mixer",
           CAP_PLUGIN_METHOD(playOrPause, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(stop, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(isPlaying, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(initAudioFile, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(adjustVolume, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(getCurrentVolume, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(adjustEq, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(getCurrentEq, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(setElapsedTimeEvent, CAPPluginReturnCallback);
           CAP_PLUGIN_METHOD(getElapsedTime, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(getTotalTime, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(initMicInput, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(getInputChannelCount, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(initAudioSession, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(getAudioSessionPreferredInputPortType, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(destroyMicInput, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(destroyAudioFile, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(deinitAudioSession, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(resetPlugin, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(requestMixerPermissions, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(validateFileUri, CAPPluginReturnPromise);
)
