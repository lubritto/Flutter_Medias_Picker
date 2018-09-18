package com.example.mediaspicker;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.UUID;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.media.ExifInterface;
import android.os.Environment;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;

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
public class MediasPickerPlugin implements MethodCallHandler, PluginRegistry.ActivityResultListener, PluginRegistry.RequestPermissionsResultListener {
  /**
   * Plugin registration.
   */


  private Activity activity;
  private Result result;
  private int maxWidth, maxHeight, quality;
  private boolean isPhoto;

  private MediasPickerPlugin(Activity activity) {
    this.activity = activity;
  }

  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "medias_picker");
    MediasPickerPlugin plugin = new MediasPickerPlugin(registrar.activity());
    channel.setMethodCallHandler(plugin);

    registrar.addActivityResultListener(plugin);
    registrar.addRequestPermissionsResultListener(plugin);
  }


  @Override
  public void onMethodCall(MethodCall call, Result result) {

    if (call.method.equals("pickImages")) {

      isPhoto = true;

      int quantity = call.argument("quantity");
      maxWidth = call.argument("maxWidth");
      maxHeight = call.argument("maxHeight");
      quality = call.argument("quality");

      this.result = result;
      FilePickerBuilder.getInstance().setMaxCount(quantity)
              .enableVideoPicker(false)
              .enableImagePicker(true)
              .pickPhoto(activity);


    } else if (call.method.equals("pickVideos")) {

      isPhoto = false;

      int quantity = call.argument("quantity");

      this.result = result;
      FilePickerBuilder.getInstance().setMaxCount(quantity)
              .enableVideoPicker(true)
              .enableImagePicker(false)
              .pickPhoto(activity);

    } else if (call.method.equals("deleteAllTempFiles")) {
      this.result = result;
      DeleteAllTempFiles();
    } else if (call.method.equals("compressImages")) {
      maxWidth = call.argument("maxWidth");
      maxHeight = call.argument("maxHeight");
      quality = call.argument("quality");
      ArrayList<String> imgPaths = call.argument("imgPaths");
      ArrayList<String> newImgPaths = new ArrayList<>();

      for (String path : imgPaths) {
        String newPath = CompressImage(path, maxWidth, maxHeight, quality);

        if (newPath != null && newPath != "")
          newImgPaths.add(newPath);
          
      }
      this.result = result;
      this.result.success(newImgPaths);

    } else if (call.method.equals("checkPermission")) {
        result.success(checkPermission());
    } else if (call.method.equals("requestPermission")) {
        this.result = result;
        requestPermission();
    } else {
      result.notImplemented();
    }
  }

  public static int calculateInSampleSize(BitmapFactory.Options options, int reqWidth, int reqHeight) {
    final int height = options.outHeight;
    final int width = options.outWidth;
    int inSampleSize = 1;

    if (height > reqHeight || width > reqWidth) {
      final int heightRatio = Math.round((float) height / (float) reqHeight);
      final int widthRatio = Math.round((float) width / (float) reqWidth);
      inSampleSize = heightRatio < widthRatio ? heightRatio : widthRatio;
    }
    final float totalPixels = width * height;
    final float totalReqPixelsCap = reqWidth * reqHeight * 2;
    while (totalPixels / (inSampleSize * inSampleSize) > totalReqPixelsCap) {
      inSampleSize++;
    }
    return inSampleSize;
  }

    public String CompressImage(String filename, int maxWidth, int maxHeight, int quality) {

        Bitmap scaledBitmap = null;
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        Bitmap bmp = BitmapFactory.decodeFile(filename, options);

        int actualHeight = options.outHeight;
        int actualWidth = options.outWidth;

        float imgRatio = (float) actualWidth / (float) actualHeight;
        float maxRatio = (float)maxWidth / (float)maxHeight;

        if (actualHeight > maxHeight || actualWidth > maxWidth) {
            if (imgRatio < maxRatio) {
                imgRatio = (float)maxHeight / actualHeight;
                actualWidth = (int) (imgRatio * actualWidth);
                actualHeight = maxHeight;
            } else if (imgRatio > maxRatio) {
                imgRatio = (float)maxWidth / actualWidth;
                actualHeight = (int) (imgRatio * actualHeight);
                actualWidth = maxWidth;
            }
        }

        options.inSampleSize = calculateInSampleSize(options, actualWidth, actualHeight);
        options.inJustDecodeBounds = false;
        options.inDither = false;
        options.inPurgeable = true;
        options.inInputShareable = true;
        options.inTempStorage = new byte[16 * 1024];

        try {
            bmp = BitmapFactory.decodeFile(filename, options);
        } catch (OutOfMemoryError exception) {
            exception.printStackTrace();
        }
        try {
            scaledBitmap = Bitmap.createBitmap(actualWidth, actualHeight, Bitmap.Config.RGB_565);
        } catch (OutOfMemoryError exception) {
            exception.printStackTrace();
        }

        float ratioX = actualWidth / (float) options.outWidth;
        float ratioY = actualHeight / (float) options.outHeight;
        float middleX = actualWidth / 2.0f;
        float middleY = actualHeight / 2.0f;

        Matrix scaleMatrix = new Matrix();
        scaleMatrix.setScale(ratioX, ratioY, middleX, middleY);
        Canvas canvas = new Canvas(scaledBitmap);
        canvas.setMatrix(scaleMatrix);
        canvas.drawBitmap(bmp, middleX - bmp.getWidth() / 2, middleY - bmp.getHeight() / 2, new Paint(Paint.FILTER_BITMAP_FLAG));

        if (bmp != null) {
            bmp.recycle();
        }

        ExifInterface exif;

        try {
            exif = new ExifInterface(filename);
            int orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, 0);
            Matrix matrix = new Matrix();
            if (orientation == 6) {
                matrix.postRotate(90);
            } else if (orientation == 3) {
                matrix.postRotate(180);
            } else if (orientation == 8) {
                matrix.postRotate(270);
            }
            scaledBitmap = Bitmap.createBitmap(scaledBitmap, 0, 0, scaledBitmap.getWidth(), scaledBitmap.getHeight(), matrix, true);
        } catch (IOException e) {
            e.printStackTrace();
        }

        ByteArrayOutputStream outStream = new ByteArrayOutputStream();
        // compress to the format you want, JPEG, PNG...
        // 70 is the 0-100 quality percentage
        scaledBitmap.compress(Bitmap.CompressFormat.JPEG, quality , outStream);

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

        return filename;
    }


  public void DeleteAllTempFiles(){
    String tempDirPath = Environment.getExternalStorageDirectory()
            + File.separator + "TempImgs" + File.separator;

    File tempDir = new File(tempDirPath);
    if (tempDir.exists()){

      String[] children = tempDir.list();
      for (int i = 0; i < children.length; i++)
      {
        new File(tempDir, children[i]).delete();
      }

      if (tempDir.delete())
        this.result.success(true);
      else
        this.result.success(false);
    } else {
      this.result.success(true);
    }
  }

    private void requestPermission() {
        String[] perm = {Manifest.permission.WRITE_EXTERNAL_STORAGE, Manifest.permission.CAMERA};
        ActivityCompat.requestPermissions(activity, perm, 0);
    }

    private boolean checkPermission() {
        return PackageManager.PERMISSION_GRANTED == ContextCompat.checkSelfPermission(activity, Manifest.permission.WRITE_EXTERNAL_STORAGE)
                && PackageManager.PERMISSION_GRANTED == ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA);
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        boolean res = false;

        if (requestCode == 0 && grantResults.length > 0) {
            res = true;

            for (int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    res = false;
                }
            }

            result.success(res);
        }
        return res;
    }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent intent) {

    if (requestCode == FilePickerConst.REQUEST_CODE_PHOTO){

      ArrayList<String> docPaths = new ArrayList<>();

      if (intent != null){
        ArrayList<String> paths = intent.getStringArrayListExtra(FilePickerConst.KEY_SELECTED_MEDIA);

        if (isPhoto) {
          for(String item: paths){

            String path = CompressImage(item, maxWidth, maxHeight , quality);

            if (path != null)
              docPaths.add(path);
          }
        } else {
          docPaths = paths;
        }

      }
    
      this.result.success(docPaths);
    
      return true;
    }

    return false;
  }
}
