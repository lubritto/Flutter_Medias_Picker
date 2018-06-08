import Flutter
import UIKit
import Gallery
import Photos
import SVProgressHUD

public class SwiftMediasPickerPlugin: NSObject, FlutterPlugin, GalleryControllerDelegate {
    private var result: FlutterResult?
    private var viewController: UIViewController?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "medias_picker", binaryMessenger: registrar.messenger())
        let viewController: UIViewController? = UIApplication.shared.delegate?.window??.rootViewController
        let instance = SwiftMediasPickerPlugin(viewController: viewController)
        registrar.addMethodCallDelegate(instance as FlutterPlugin, channel: channel)
    }
    
    init(viewController: UIViewController?) {
        super.init()
        
        Config.Camera.imageLimit = 10
        Config.Camera.recordLocation = true
        Config.tabsToShow = [.imageTab, .cameraTab, .videoTab]
        
        self.viewController = viewController
        
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (self.result != nil) {
            self.result!(FlutterError(code: "multiple_request", message: "Cancelled by a second request", details: nil))
            self.result = nil
        }
        if ("pickMedias" == call.method) {
            
            let gallery = GalleryController()
            gallery.delegate = self
            
            self.result = result
            
            viewController?.present(gallery, animated: true)

        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        DispatchQueue.global(qos: .userInitiated).async {
            let resultUrls : NSMutableArray = NSMutableArray()
            
            for image in images {
                
                let manager = PHImageManager.default()
                let requestOptions = PHImageRequestOptions()
                requestOptions.resizeMode = .exact
                requestOptions.deliveryMode = .highQualityFormat;
                requestOptions.isNetworkAccessAllowed = true;
                requestOptions.isSynchronous = true
                requestOptions.progressHandler = { (progress, error, stop, info) in
                    if(progress == 1.0){
                        DispatchQueue.main.async {
                            SVProgressHUD.dismiss()
                        }
                        print("Finished")
                    } else {
                        DispatchQueue.main.async {
                            SVProgressHUD.showProgress(Float(progress), status: "Downloading from iCloud")
                        }
                        print("Downloading from cloud")
                    }
                }
                
                // Request Image
                manager.requestImageData(for: image.asset, options: requestOptions, resultHandler: { (data, str, orientation, info) in
                    if let info = info {
                        if info.keys.contains(NSString(string: "PHImageFileURLKey")) {
                            if let url = info[NSString(string: "PHImageFileURLKey")] as? NSURL {
                                print(url)
                                resultUrls.add(url.path ?? "")
                            }
                        }
                    }
                })
            }
            
            self.result!(resultUrls)
            controller.dismiss(animated: true, completion: nil)
        }
        
        
    }
    
    public func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        
    }
    
    public func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
        
    }
    
    public func galleryControllerDidCancel(_ controller: GalleryController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

