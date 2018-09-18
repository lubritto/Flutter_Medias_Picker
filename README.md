# medias_picker

A new Flutter plugin to get pictures and videos.

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

**This Plugin is under development, but alredy works in IOS and Android**

For help on editing plugin code, view the [documentation](https://flutter.io/platform-plugins/#edit-code).

You need to put these styles to plugin works

```sh
  <style name="LibAppTheme" parent="Theme.AppCompat.Light.NoActionBar">
      <!-- Customize your theme here. -->
      <item name="colorPrimary">@color/colorPrimary</item>
      <item name="colorPrimaryDark">@color/colorPrimaryDark</item>
      <item name="colorAccent">@color/colorAccent</item>
      <item name="android:colorBackground">@android:color/background_light</item>
      <item name="android:windowBackground">@android:color/white</item>
  </style>

  <style name="PickerTabLayout" parent="Widget.Design.TabLayout">
      <item name="tabBackground">@color/colorPrimary</item>
      <item name="tabGravity">fill</item>
      <item name="tabMaxWidth">0dp</item>
  </style>

  <style name="SmoothCheckBoxStyle">
      <item name="color_checked">@color/checkbox_color</item>
      <item name="color_unchecked">@android:color/white</item>
      <item name="color_unchecked_stroke">@color/checkbox_unchecked_color</item>
      <item name="color_tick">@android:color/white</item>
  </style>
```

add <uses-permission android:name="android.permission.CAMERA"/> in manifest

and in your podfile 

```sh
platform :ios, '9.0'
use_frameworks!
```
