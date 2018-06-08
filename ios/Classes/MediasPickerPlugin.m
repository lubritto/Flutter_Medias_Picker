#import "MediasPickerPlugin.h"
#import <medias_picker/medias_picker-Swift.h>

@implementation MediasPickerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMediasPickerPlugin registerWithRegistrar:registrar];
}
@end
