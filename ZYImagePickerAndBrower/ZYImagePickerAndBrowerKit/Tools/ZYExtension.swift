//
//  ZYExtension.swift
//  ZYImagePickerAndBrower
//
//  Created by Nvr on 2018/8/17.
//  Copyright © 2018年 ZY. All rights reserved.
//

import UIKit
import Security

public extension DispatchQueue {
    
    private static var _onceTracker = [String]()
    
    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.
     
     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    public class func once(token: String, handle:()->Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if _onceTracker.contains(token) {
            return
        }
        
        _onceTracker.append(token)
        handle()
    }
}

extension UIImage {
    class func zyImageFromeBundle(named: String) -> UIImage? {
        if let cacheImageData = ZYCachingImageManager.default().getImageMemoryCache(key: named) {
            return UIImage(data: cacheImageData, scale: UIScreen.main.scale)
        }
        let pathName = "/Frameworks/ZYImagePickerAndBrower.framework/\(named)"
        if let fullImagePath = Bundle.main.resourcePath?.appending(pathName) {
            guard let image = UIImage.init(contentsOfFile: fullImagePath) else {return nil}
            if let imageData = UIImagePNGRepresentation(image) {
                ZYCachingImageManager.default().setImageMemoryCache(key: named, data: imageData)
            }
            return image
        }
        return nil
    }
    
    class func zyCreateImageWithColor(color: UIColor, size: CGSize) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    class func zyCreateImageWithView(view: UIView) -> UIImage? {
        let size = view.bounds.size;
        // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了，关键就是第三个参数。
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

struct ImageConst{
    static let bytesPerPixel = 4
    static let bitsPerComponent = 8
}

extension UIImage {
    //解压缩来提高效率
    func zyDecodedImage() -> UIImage? {
        guard let cgImage = self.cgImage else{
            return nil
        }
        guard let colorspace = cgImage.colorSpace else {
            return nil
        }
        let alpha = cgImage.alphaInfo
        let anyAlpha = (alpha == .first ||
            alpha == .last ||
            alpha == .premultipliedFirst ||
            alpha == .premultipliedLast)
        // do not decode images with alpha
        if anyAlpha {
            return self;
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = ImageConst.bytesPerPixel * width
        let ctx = CGContext(data: nil,
                            width: width,
                            height: height,
                            bitsPerComponent: ImageConst.bitsPerComponent,
                            bytesPerRow: bytesPerRow,
                            space: colorspace,
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let context = ctx else {
            return nil
        }
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: rect)
        guard let drawedImage = context.makeImage() else{
            return nil
        }
        let result = UIImage(cgImage: drawedImage, scale:self.scale , orientation: self.imageOrientation)
        return result
    }
}

extension UIImage {
    func zySetRoundedCorner(radius: CGFloat) -> UIImage? {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: self.size)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        context?.addPath(UIBezierPath(roundedRect: rect, byRoundingCorners: UIRectCorner.allCorners, cornerRadii: CGSize(width: radius, height: radius)).cgPath)
        context?.clip()
        
        self.draw(in: rect)
        context?.drawPath(using: .fillStroke)
        let output = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return output
    }
}

extension UIImageView {
    func asyncSetImage(_ image:UIImage?){
        DispatchQueue.global(qos: .userInteractive).async {
            let decodeImage = image?.zyDecodedImage()
            DispatchQueue.main.async {
                self.image = decodeImage
            }
        }
    }
    /**
     *设置web图片
     *url:图片路径
     *defaultImage:默认缺省图片
     *isCache：是否进行缓存的读取
     */
    func setWebImage(url:String?, defaultImage:UIImage?, isCache:Bool, downloadSuccess: ((_ image: UIImage?) -> Void)?) {
        var zyImage:UIImage?
        guard url != nil else {return}
        //设置默认图片
        if defaultImage != nil {
            self.asyncSetImage(defaultImage)
        }
        
        if isCache {
            var data: Data? = ZYCachingImageManager.default().readCacheFromUrl(url: url!)
            if data != nil {
                zyImage = UIImage(data: data!)
                self.asyncSetImage(zyImage)
                if downloadSuccess != nil {
                    downloadSuccess!(zyImage)
                }
            }else{
                let dispath = DispatchQueue.global(qos: .utility)
                dispath.async(execute: { () -> Void in
                    do {
                        guard let imageURL = URL(string: url!) else {return}
                        data = try Data(contentsOf: imageURL)
                        if data != nil {
                            zyImage = UIImage(data: data!)
                            //写缓存
                            ZYCachingImageManager.default().writeCacheToUrl(url: url!, data: data!)
                            DispatchQueue.main.async(execute: { () -> Void in
                                //刷新主UI
                                self.asyncSetImage(zyImage)
                                if downloadSuccess != nil {
                                    downloadSuccess!(zyImage)
                                }
                            })
                        }
                    }
                    catch {
                        if ZYPhotoAlbumEnableDebugOn {
                            print(error)
                        }
                    }
                })
            }
        }else{
            let dispath = DispatchQueue.global(qos: .utility)
            dispath.async(execute: { () -> Void in
                do {
                    guard let imageURL = URL(string: url!) else {return}
                    let data = try Data(contentsOf: imageURL)
                    zyImage = UIImage(data: data)
                    DispatchQueue.main.async(execute: { () -> Void in
                        //刷新主UI
                        self.asyncSetImage(zyImage)
                        if downloadSuccess != nil {
                            downloadSuccess!(zyImage)
                        }
                    })
                }
                catch {
                    if ZYPhotoAlbumEnableDebugOn {
                        print(error)
                    }
                }
            })
        }
    }
}

extension UIButton{
    func asyncSetImage(_ image:UIImage?, for state:UIControlState){
        DispatchQueue.global(qos: .userInteractive).async {
            let decodeImage = image?.zyDecodedImage()
            DispatchQueue.main.async {
                self.setImage(decodeImage, for: state)
            }
        }
    }
}


