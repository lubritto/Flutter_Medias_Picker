package com.example.mediaspicker;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.UUID;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Environment;

import droidninja.filepicker.FilePickerBuilder;
import droidninja.filepicker.FilePickerConst;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * MediasPickerPlugin
 */
public class MediasPickerPlugin implements MethodCallHandler, PluginRegistry.ActivityResultListener {
  /**
   * Plugin registration.
   */

  private Activity activity;
  private Result result;
  private int maxWidth, quality;

  private MediasPickerPlugin(Activity activity) {
    this.activity = activity;
  }

  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "medias_picker");
    MediasPickerPlugin plugin = new MediasPickerPlugin(registrar.activity());
    channel.setMethodCallHandler(plugin);
    registrar.addActivityResultListener(plugin);
  }


  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("pickMedias")) {

      int quantity = call.argument("quantity");
      maxWidth = call.argument("maxWidth");
      quality = call.argument("quality");

      this.result = result;
      FilePickerBuilder.getInstance().setMaxCount(quantity)
              .enableVideoPicker(true)
              .enableImagePicker(true)
              .pickPhoto(activity);


    } else if (call.method.equals("deleteAllTempFiles")) {
      DeleteAllTempFiles();
    } else if (call.method.equals("compressImages")) {
      maxWidth = call.argument("maxWidth");
      quality = call.argument("quality");
      ArrayList<String> imgPaths = call.argument("imgPaths");
      ArrayList<String> newImgPaths = new ArrayList<>();

      for (String path : imgPaths) {
        String newPath = CompressImage(path, maxWidth, quality);

        if (newPath != null && newPath != "")
          newImgPaths.add(newPath);
          
      }

      this.result.success(newImgPaths);

    } else {
      result.notImplemented();
    }
  }

  public String CompressImage(String filename, int maxWidth, int quality) {
    // we'll start with the original picture already open to a file
    File imgFileOrig = new File(filename); //change "getPic()" for whatever you need to open the image file.
    Bitmap b = BitmapFactory.decodeFile(imgFileOrig.getAbsolutePath());
    // original measurements
    int origWidth = b.getWidth();
    int origHeight = b.getHeight();

    final int destWidth = maxWidth <= 0 ? origWidth : maxWidth;//or the width you need

    if(origWidth >= destWidth){
      // picture is wider than we want it, we calculate its target height
      double scale =  origWidth / (double)destWidth;
      int destHeight = (int)(origHeight/scale);
      // we create an scaled bitmap so it reduces the image, not just trim it
      Bitmap b2 = Bitmap.createScaledBitmap(b, destWidth, destHeight, false);
      ByteArrayOutputStream outStream = new ByteArrayOutputStream();
      // compress to the format you want, JPEG, PNG...
      // 70 is the 0-100 quality percentage
      b2.compress(Bitmap.CompressFormat.JPEG, quality , outStream);
      // we save the file, at least until we have made use of it
      String tempDirPath = Environment.getExternalStorageDirectory()
              + File.separator + "TempImgs" + File.separator;
      String path = tempDirPath + UUID.randomUUID().toString() + ".jpg";

      File tempDir = new File(tempDirPath);

      File f = new File(path);
      try {
        if (!tempDir.exists())
          tempDir.mkdirs();

        f.createNewFile();

        //write the bytes in file
        FileOutputStream fo = new FileOutputStream(f);
        fo.write(outStream.toByteArray());
        // remember close de FileOutput
        fo.close();

        return path;
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
    else
    {
      return filename;
    }
    return "";
  }

  public void DeleteAllTempFiles(){
    String tempDirPath = Environment.getExternalStorageDirectory()
            + File.separator + "TempImgs" + File.separator;

    File tempDir = new File(tempDirPath);
    if (tempDir.exists()){
      if (tempDir.delete())
        result.success(true);
      else
        result.success(false);
    } else {
      result.success(false);
    }
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent intent) {

    if (requestCode == FilePickerConst.REQUEST_CODE_PHOTO){

      ArrayList<String> docPaths = new ArrayList<>();

      if (intent != null){
        ArrayList<String> paths = intent.getStringArrayListExtra(FilePickerConst.KEY_SELECTED_MEDIA);

        for(String item: paths){

          String path = CompressImage(item, maxWidth, quality);

          if (path != null)
            docPaths.add(path);
        }
      }
    
      this.result.success(docPaths);
    
      return true;
    }

    return false;
  }
}
