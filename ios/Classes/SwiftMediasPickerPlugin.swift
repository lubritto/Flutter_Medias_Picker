import Flutter
import UIKit
import Gallery
import Photos
import SVProgressHUD

public class SwiftMediasPickerPlugin: NSObject, FlutterPlugin, GalleryControllerDelegate {
    private var result: FlutterResult?
    private var viewController: UIViewController?
    private var maxWidth: Int?
    private var quality: Int?
    
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
            
            guard let args = call.arguments as? [String: Int] else {
                fatalError("args are formatted badly")
            }
            let quantity = args["quantity"]
            maxWidth = args["maxWidth"]
            quality = args["quality"]
            
            Config.Camera.imageLimit = quantity!

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
            let fileManager:FileManager = FileManager()
            
            SVProgressHUD.show()
            
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
                manager.requestImageData(for: image.asset, options: requestOptions) { data, _, _, _ in
                    if let data = data {
                        var img = UIImage(data: data)
                        img = self.ResizeImage(image: img!, targetSize: CGSize(width: Double(self.maxWidth!), height: 0.0))
                        let nData = UIImageJPEGRepresentation(img!, (CGFloat(self.quality!) / CGFloat(100)))
                        let guid = NSUUID().uuidString
                        let tmpFile = String(format: "image_picker_%@.jpg", guid)
                        let tmpDirec = NSTemporaryDirectory()
                        let tmpPath = (tmpDirec as NSString).appendingPathComponent(tmpFile)
                        
                        if fileManager.createFile(atPath: tmpPath, contents: nData, attributes: nil) {
                            print(tmpPath)
                            resultUrls.add(tmpPath)
                        } else {
                            print("Erro")
                        }
                        
                    }
                }
            }
            
            self.result!(resultUrls)
            SVProgressHUD.dismiss()
            controller.dismiss(animated: true, completion: nil)
        }
        
        
    }
    
    func ResizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let destHeight = targetSize.height / (image.size.width / targetSize.width)
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = destHeight / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    public func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        
    }
    
    public func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
        
    }
    
    public func galleryControllerDidCancel(_ controller: GalleryController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

