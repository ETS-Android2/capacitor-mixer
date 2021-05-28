#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(Mixer, "Mixer",
           CAP_PLUGIN_METHOD(echo, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(play, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(stop, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(isPlaying, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(initAudioFile, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(adjustVolume, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(getCurrentVolume, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(adjustEQ, CAPPluginReturnPromise);
)
