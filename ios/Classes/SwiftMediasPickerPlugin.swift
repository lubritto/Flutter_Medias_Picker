import Flutter
import UIKit
import Gallery
import Photos
import SVProgressHUD

public class SwiftMediasPickerPlugin: NSObject, FlutterPlugin, GalleryControllerDelegate {
    private var result: FlutterResult?
    private var viewController: UIViewController?
    private var maxWidth: Int?
    private var maxHeight: Int?
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
        
        self.viewController = viewController
        
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (self.result != nil) {
            self.result!(FlutterError(code: "multiple_request", message: "Cancelled by a second request", details: nil))
            self.result = nil
        }
        if ("pickImages" == call.method) {
            
            guard let args = call.arguments as? [String: Int] else {
                fatalError("args are formatted badly")
            }
            let quantity = args["quantity"]
            maxWidth = args["maxWidth"]
            maxHeight = args["maxHeight"]
            quality = args["quality"]
            
            Config.Camera.imageLimit = quantity!
            Config.tabsToShow = [.imageTab, .cameraTab]

            let gallery = GalleryController()
            gallery.delegate = self
            
            self.result = result
            
            viewController?.present(gallery, animated: true)

        } else if ("pickVideos" == call.method) {
            guard let args = call.arguments as? [String: Int] else {
                fatalError("args are formatted badly")
            }
            let quantity = args["quantity"]
            
            Config.Camera.imageLimit = quantity!
            Config.tabsToShow = [.videoTab]
            
            let gallery = GalleryController()
            gallery.delegate = self
            
            self.result = result
            
            viewController?.present(gallery, animated: true)
            
        } else if ("compressImages" == call.method) {
            var args = call.arguments as? [String: Any?]
            
            maxWidth = args!["maxWidth"] as? Int
            maxHeight = args!["maxHeight"] as? Int
            quality = args!["quality"] as? Int
            
            let imgPaths = args!["imgPaths"] as! [String]
            
            let resultUrls : NSMutableArray = NSMutableArray()
            let fileManager:FileManager = FileManager()
            
            for path in imgPaths {
                let newPath = self.CompressImage(fileName: path, targetSize: CGSize(width: Double(self.maxWidth!), height: Double(self.maxHeight!)), fileManager: fileManager)
                
                if (newPath != "") {
                    resultUrls.add(newPath)
                }
            }
            self.result = result
            
            self.result!(resultUrls)
            
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
                manager.requestImageData(for: image.asset, options: requestOptions, resultHandler: { (data, _, _, _) in
                    if data != nil {
                        var img = UIImage(data: data!)
                        img = self.ResizeImage(image: img!, targetSize: CGSize(width: Double(self.maxWidth!), height: Double(self.maxHeight!)))
                        let nData = img!.jpegData(compressionQuality: (CGFloat(self.quality!) / CGFloat(100)))
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
                })
            }
            
            self.result!(resultUrls)
            SVProgressHUD.dismiss()
            controller.dismiss(animated: true, completion: nil)
        }
        
        
    }
    
    func CompressImage(fileName: String, targetSize: CGSize, fileManager: FileManager) -> String {
        
        var imgData : Data? = nil;
        
        do {
            imgData = try Data(contentsOf: URL(fileURLWithPath: fileName))
            
        } catch {
            print(error)
        }
        
        let image = UIImage(data: imgData!)!
        
        let size = image.size
        
        let destHeight = targetSize.height <= 0 ? size.height : targetSize.height;
        let destWidth = targetSize.width <= 0 ? size.width : targetSize.width;
        
        let widthRatio  = destWidth / size.width
        let heightRatio = destHeight / size.height
        
        if (size.width >= destWidth || size.height >= destHeight) {
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
            
            let nData = newImage!.jpegData(compressionQuality: (CGFloat(self.quality!) / CGFloat(100)))
            let guid = NSUUID().uuidString
            let tmpFile = String(format: "image_picker_%@.jpg", guid)
            let tmpDirec = NSTemporaryDirectory()
            let tmpPath = (tmpDirec as NSString).appendingPathComponent(tmpFile)
            
            if fileManager.createFile(atPath: tmpPath, contents: nData, attributes: nil) {
                print(tmpPath)
                return tmpPath
            } else {
                print("Erro")
                return ""
            }
        }
        else {
            return fileName
        }
        
        
    }
    
    func ResizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let destHeight = targetSize.height <= 0 ? size.height : targetSize.height;
        let destWidth = targetSize.width <= 0 ? size.width : targetSize.width;
        
        let widthRatio  = destWidth / size.width
        let heightRatio = destHeight / size.height
        
        if (size.width > destWidth || size.height > destHeight) {
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
        } else {
            return image
        }
    }
    
    public func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        DispatchQueue.global(qos: .userInitiated).async {
        
            let manager = PHImageManager.default()
            
            let fileManager:FileManager = FileManager()
            let resultUrls : NSMutableArray = NSMutableArray()
            
            let requestOptions = PHVideoRequestOptions()
            requestOptions.version = .original
            requestOptions.deliveryMode = .highQualityFormat;
            requestOptions.isNetworkAccessAllowed = true;
            
            
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
        
            let semaphore = DispatchSemaphore(value: 0)
            
            manager.requestAVAsset(forVideo: video.asset, options: requestOptions, resultHandler: { (asset, audioMix, info) in
                if asset != nil, let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl = urlAsset.url
                    var nData : Data? = nil;
                    
                    do {
                        nData = try Data(contentsOf: localVideoUrl)
                        
                    } catch {
                        print(error)
                    }
                    
                    let guid = NSUUID().uuidString
                    let tmpFile = String(format: "image_picker_%@.mp4", guid)
                    let tmpDirec = NSTemporaryDirectory()
                    let tmpPath = (tmpDirec as NSString).appendingPathComponent(tmpFile)
                    
                    if fileManager.createFile(atPath: tmpPath, contents: nData, attributes: nil) {
                        print(tmpPath)
                        resultUrls.add(tmpPath)
                    } else {
                        print("Erro")
                    }
                }
                
                semaphore.signal()
            })
            
            semaphore.wait(timeout: .distantFuture)
            
            self.result!(resultUrls)
            SVProgressHUD.dismiss()
            controller.dismiss(animated: true, completion: nil)
        }

    }
    
    public func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
        
    }
    
    public func galleryControllerDidCancel(_ controller: GalleryController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

