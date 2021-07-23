package com.skylabs.mixer;
import android.content.ContentUris;
import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.database.Cursor;
import android.media.AudioAttributes;
import android.media.MediaPlayer;
import android.media.audiofx.DynamicsProcessing;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.os.ParcelFileDescriptor;
import android.os.StrictMode;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import android.util.Log;
import android.media.audiofx.DynamicsProcessing.Eq;
import android.media.audiofx.DynamicsProcessing.EqBand;

import com.getcapacitor.JSObject;

import java.io.File;
import java.net.URI;
import java.util.HashMap;
import java.util.Map;

public class AudioFile implements MediaPlayer.OnPreparedListener, MediaPlayer.OnCompletionListener {
    Mixer _parent;
    private MediaPlayer player;
    private Eq eq;
    private DynamicsProcessing dp;
    private float currentVolume;


    public AudioFile(Mixer parent) {
        _parent = parent;
        player = new MediaPlayer();
        player.setOnCompletionListener(this);
        player.setOnPreparedListener(this);
    }

    public void setupAudio(String audioFilePath, ChannelSettings channelSettings) {
        try {
            Uri uri = Uri.parse(audioFilePath);
            String filePath = getPath(_parent._context, uri);
            File file = new File(new URI(filePath));
            ParcelFileDescriptor pfd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY);
            AssetFileDescriptor afd = new AssetFileDescriptor(pfd, 0, -1);
            player.setAudioAttributes(new AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
            );
            player.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
            player.prepare();
            setupEq(channelSettings);
        }
        catch(Exception ex) {
            Log.e("setupAudio", "Exception thrown in setupAudio: " + ex);
        }
    }

    private void setupEq(ChannelSettings channelSettings) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            EqBand bassEq = new EqBand(true, 200, 0);
            EqBand midEq = new EqBand(true, 1499, 0);
            EqBand trebleEq = new EqBand(true, 20000, 0);
            eq = new Eq(true, true, 3);
            eq.setBand(0, bassEq);
            eq.setBand(1, midEq);
            eq.setBand(2, trebleEq);
            dp = new DynamicsProcessing(player.getAudioSessionId());
            dp.setPostEqAllChannelsTo(eq);
        }
        configureEngine(channelSettings);
    }

    private void configureEngine(ChannelSettings channelSettings) {
        dp.setEnabled(true);
        currentVolume = (float)channelSettings.volume;
        player.setVolume(currentVolume, currentVolume);
    }

    public void scheduleAudioFile() {

    }

    public void handleMetering() {

    }

    public void setElapsedTimeEvent(String eventName) {

    }

    public String playOrPause() {
        if (player.isPlaying()) {
            player.pause();
            return "pause";
        } else {
            player.start();
            return "play";
        }
    }

    public String stop() {
        player.stop();
        player.seekTo(0);
        return "stop";
    }

    public boolean isPlaying() {
        return player.isPlaying();
    }

    public void adjustVolume(double volume) {
        currentVolume = (float)volume;
        player.setVolume(currentVolume, currentVolume);
        // TODO: ? get values as floats?
    }

    public double getCurrentVolume() {
        return currentVolume;
    }

    public void adjustEq(String type, double gain, double freq) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            if (eq.getBandCount() < 1) {
                return;
            }
            switch (type) {
                case "bass":
                    EqBand bassEq = eq.getBand(0);
                    bassEq.setGain((float)gain);
                    bassEq.setCutoffFrequency((float)freq);
                case "mid":
                    EqBand midEq = eq.getBand(1);
                    midEq.setGain((float)gain);
                    midEq.setCutoffFrequency((float)freq);
                case "treble":
                    EqBand trebleEq = eq.getBand(2);
                    trebleEq.setGain((float)gain);
                    trebleEq.setCutoffFrequency((float)freq);
                default:
                    System.out.println("adjustEq: invalid eq type");
            }
        }
    }

    public EqSettings getCurrentEq() {
//        Map<String, Object> currentEq = new HashMap<String, Object>();
        EqSettings currentEq = new EqSettings();
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
//            for (int i = 0; i < eq.getBandCount(); i++) {
//                currentEq.put("gain", eq.getBand(i).getGain());
//                currentEq.put("frequency", eq.getBand(i).getCutoffFrequency());
//            }
//            currentEq.put("bassGain", eq.getBand(0).getGain());
//            currentEq.put("bassFreq", eq.getBand(0).getCutoffFrequency());
//            currentEq.put("midGain", eq.getBand(1).getGain());
//            currentEq.put("midFreq", eq.getBand(1).getCutoffFrequency());
//            currentEq.put("trebleGain", eq.getBand(2).getGain());
//            currentEq.put("trebleFreq", eq.getBand(2).getCutoffFrequency());

            // implemented as EqSettings. Changes in Mixer.getCurrentEq reflect this
            currentEq.bassGain = eq.getBand(0).getGain();
            currentEq.bassFrequency = eq.getBand(0).getGain();
            currentEq.midGain = eq.getBand(1).getGain();
            currentEq.midFrequency = eq.getBand(1).getGain();
            currentEq.trebleGain = eq.getBand(2).getGain();
            currentEq.trebleFrequency = eq.getBand(2).getGain();
        }
        return currentEq;
    }

    public Map<String, Object> getElapsedTime() {
        // Is there an event I can subscribe to?
        Map<String, Object> elapsedTime = timeToDictionary(player.getCurrentPosition());
        return elapsedTime;
    }

    public Map<String, Object> getTotalTime() {
        Map<String, Object> totalTime = timeToDictionary(player.getDuration());
        return totalTime;
    }

    public Map<String, String> destroy() {
        return new HashMap<String, String>();
    }

    @Override
    public void onCompletion(MediaPlayer mediaPlayer) {
        try {
            stop();
        }
        catch (Exception ex) {
            Log.e("onCompletion AudioFile", "An error occurred in onCompletion. Exception: " + ex.getLocalizedMessage());
        }
    }

    @Override
    public void onPrepared(MediaPlayer mediaPlayer) {
        try {
            player.seekTo(0);
        }
        catch (Exception ex) {
            Log.e("onPrepared AudioFile", "An error occurred in onPrepared. Exception: " + ex.getLocalizedMessage());
        }
    }

    private Map<String, Object> timeToDictionary(int time) {
        final int milliSeconds = (int) Math.floor(time);
        final int seconds = time % 60;
        final int minutes = (time / 60) % 60;
        final int hours = (time / 3600);

        Map<String, Object> timeDictionary = new HashMap<String, Object>();
        timeDictionary.put("milliSeconds", milliSeconds);
        timeDictionary.put("seconds", seconds);
        timeDictionary.put("minutes", minutes);
        timeDictionary.put("hours", hours);
        return timeDictionary;
    }
    /**
     * Get a file path from a Uri. This will get the the path for Storage Access
     * Framework Documents, as well as the _data field for the MediaStore and
     * other file-based ContentProviders.
     *
     * @param context The context.
     * @param uri The Uri to query.
     * @author paulburke
     */
    public static String getPath(final Context context, final Uri uri) {

        final boolean isKitKat = Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT;

        // DocumentProvider
        if (isKitKat && DocumentsContract.isDocumentUri(context, uri)) {
            // ExternalStorageProvider
            if (isExternalStorageDocument(uri)) {
                final String docId = DocumentsContract.getDocumentId(uri);
                final String[] split = docId.split(":");
                final String type = split[0];

                if ("primary".equalsIgnoreCase(type)) {
                    return Environment.getExternalStorageDirectory() + "/" + split[1];
                }

                // TODO handle non-primary volumes
            }
            // DownloadsProvider
            else if (isDownloadsDocument(uri)) {

                final String id = DocumentsContract.getDocumentId(uri);
                final Uri contentUri = ContentUris.withAppendedId(
                        Uri.parse("content://downloads/public_downloads"), Long.valueOf(id));

                return getDataColumn(context, contentUri, null, null);
            }
            // MediaProvider
            else if (isMediaDocument(uri)) {
                final String docId = DocumentsContract.getDocumentId(uri);
                final String[] split = docId.split(":");
                final String type = split[0];

                Uri contentUri = null;
                if ("image".equals(type)) {
                    contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
                } else if ("video".equals(type)) {
                    contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI;
                } else if ("audio".equals(type)) {
                    contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
                }

                final String selection = "_id=?";
                final String[] selectionArgs = new String[] {
                        split[1]
                };

                return getDataColumn(context, contentUri, selection, selectionArgs);
            }
        }
        // MediaStore (and general)
        else if ("content".equalsIgnoreCase(uri.getScheme())) {
            return getDataColumn(context, uri, null, null);
        }
        // File
        else if ("file".equalsIgnoreCase(uri.getScheme())) {
            return uri.getPath();
        }

        return null;
    }

    /**
     * Get the value of the data column for this Uri. This is useful for
     * MediaStore Uris, and other file-based ContentProviders.
     *
     * @param context The context.
     * @param uri The Uri to query.
     * @param selection (Optional) Filter used in the query.
     * @param selectionArgs (Optional) Selection arguments used in the query.
     * @return The value of the _data column, which is typically a file path.
     */
    public static String getDataColumn(Context context, Uri uri, String selection,
                                       String[] selectionArgs) {

        Cursor cursor = null;
        final String column = "_data";
        final String[] projection = {
                column
        };

        try {
            cursor = context.getContentResolver().query(uri, projection, selection, selectionArgs,
                    null);
            if (cursor != null && cursor.moveToFirst()) {
                final int column_index = cursor.getColumnIndexOrThrow(column);
                return cursor.getString(column_index);
            }
        } finally {
            if (cursor != null)
                cursor.close();
        }
        return null;
    }


    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is ExternalStorageProvider.
     */
    public static boolean isExternalStorageDocument(Uri uri) {
        return "com.android.externalstorage.documents".equals(uri.getAuthority());
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is DownloadsProvider.
     */
    public static boolean isDownloadsDocument(Uri uri) {
        return "com.android.providers.downloads.documents".equals(uri.getAuthority());
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is MediaProvider.
     */
    public static boolean isMediaDocument(Uri uri) {
        return "com.android.providers.media.documents".equals(uri.getAuthority());
    }
}
