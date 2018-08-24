//
//  ZYPhotoNavigationViewController.swift
//  ZYImagePickerAndBrower
//
//  Created by Nvr on 2018/8/17.
//  Copyright © 2018年 ZY. All rights reserved.
//

import UIKit
import Photos

@objc public protocol ZYPhotoAlbumProtocol: NSObjectProtocol {
    //返回图片原资源，需要用PHCachingImageManager或者我封装的ZYCachingImageManager进行解析处理
    @available(iOS 8.0, *)
    /// 选择照片完成代理方法
    ///
    /// - Parameter selectPhotoAssets: 选择照片源
    /// - Returns: Void
    @objc optional func photoAlbum(selectPhotoAssets: [PHAsset]) -> Void
    
    //返回ZYPhotoModel数组，其中包含选择的缩略图和预览图
    @available(iOS 8.0, *)
    /// 选择照片完成代理方法
    ///
    /// - Parameter selectPhotoAssets: 选择照片Model
    /// - Returns: Void
    @objc optional func photoAlbum(selectPhotos: [ZYPhotoModel]) -> Void
    
    // 返回裁剪后图片
    @available(iOS 8.0, *)
    /// 裁剪照片回调代理方法
    ///
    /// - Parameter clipPhoto: 裁剪图
    /// - Returns: Void
    @objc optional func photoAlbum(clipPhoto: UIImage?) -> Void
}


/// 相册SDK类型枚举
///
/// - selectPhoto: 选择照片
/// - clipPhoto: 裁剪照片
public enum ZYPhotoAlbumType {
    case selectPhoto, clipPhoto
}

public class ZYPhotoNavigationViewController: UINavigationController {
    
    /// 最大选择张数
    public var maxSelectCount = 0 {
        didSet {
            self.photoAlbumVC.maxSelectCount = maxSelectCount
        }
    }
    
    /// 裁剪大小
    public var clipBounds: CGSize = CGSize(width: ZYScreenWidth, height: ZYScreenWidth) {
        didSet {
            self.photoAlbumVC.clipBounds = clipBounds
        }
    }
    
    private let photoAlbumVC = ZYPhotoAlbumViewController()
    
    private convenience init() {
        self.init(photoAlbumDelegate: nil, photoAlbumType: .selectPhoto)
    }
    
    /// 接入SDK照片列表构造方法
    ///
    /// - Parameters:
    ///   - photoAlbumDelegate: 代理回调方法
    ///   - photoAlbumType: 相册类型
    public init(photoAlbumDelegate: ZYPhotoAlbumProtocol?, photoAlbumType: ZYPhotoAlbumType) {
        let photoAlbumListVC = ZYPhotoAlbumListViewController()
        photoAlbumListVC.photoAlbumDelegate = photoAlbumDelegate
        photoAlbumListVC.type = photoAlbumType
        super.init(rootViewController: photoAlbumListVC)
        self.isNavigationBarHidden = true
        photoAlbumVC.photoAlbumDelegate = photoAlbumDelegate
        photoAlbumVC.type = photoAlbumType
        self.pushViewController(photoAlbumVC, animated: false)
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if ZYPhotoAlbumEnableDebugOn {
            print("=====================\(self)未内存泄露")
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    class func zyGetSelectView() -> UIView {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        view.backgroundColor = ZYPhotoAlbumSkinColor
        view.image = UIImage.zyImageFromeBundle(named: "album_select_blue.png")
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.masksToBounds = true
        return view
    }
    
    class func zyGetSelectNuberView(index:String) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        view.backgroundColor = ZYPhotoAlbumSkinColor
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        
        let indexLabel = UILabel()
        indexLabel.frame = view.bounds
        indexLabel.layer.cornerRadius = 16
        indexLabel.layer.masksToBounds = true
        indexLabel.textColor = UIColor.white
        indexLabel.text = index
        indexLabel.textAlignment = .center
        indexLabel.font = UIFont.systemFont(ofSize: 20)
        
        view.addSubview(indexLabel)
        return view
    }
}


/// 主题色
public var ZYPhotoAlbumSkinColor = UIColor(red: 0, green: 147/255.0, blue: 1, alpha: 1) {
    didSet {
        ZYSelectSkinImage = UIImage.zyCreateImageWithView(view: ZYPhotoNavigationViewController.zyGetSelectView())!
    }
}
var ZYSelectSkinImage: UIImage = UIImage.zyCreateImageWithView(view: ZYPhotoNavigationViewController.zyGetSelectView())!
