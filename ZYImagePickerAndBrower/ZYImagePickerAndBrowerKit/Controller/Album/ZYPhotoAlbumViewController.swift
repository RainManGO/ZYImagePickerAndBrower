//
//  WQPhotoAlbumViewController.swift
//  ZYImagePickerAndBrower
//
//  Created by Nvr on 2018/8/17.
//  Copyright © 2018年 ZY. All rights reserved.
//

import UIKit
import Photos

enum SelectStyle:Int{
    case check
    case number
}

class ZYPhotoAlbumViewController: ZYBaseViewController, PHPhotoLibraryChangeObserver, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var assetsFetchResult: PHFetchResult<PHAsset>?
    
    var maxSelectCount = 0
    
    var selectStyle:SelectStyle = .number
    
    var type: ZYPhotoAlbumType = .selectPhoto
    
    // 剪裁大小
    var clipBounds: CGSize = CGSize(width: ZYScreenWidth, height: ZYScreenWidth)
    
    weak var photoAlbumDelegate: ZYPhotoAlbumProtocol?
    
    private let cellIdentifier = "PhotoCollectionCell"
    private lazy var photoCollectionView: UICollectionView = {
        // 竖屏时每行显示4张图片
        let shape: CGFloat = 5
        let cellWidth: CGFloat = (ZYScreenWidth - 5 * shape) / 4
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsetsMake(ZYNavigationTotalHeight, shape, self.type == .selectPhoto ? 44+ZYHomeBarHeight:0, shape)
        flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        flowLayout.minimumLineSpacing = shape
        flowLayout.minimumInteritemSpacing = shape
        //  collectionView
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: ZYScreenWidth, height: ZYScreenHeight), collectionViewLayout: flowLayout)
        collectionView.backgroundColor = UIColor.white
        collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(ZYNavigationTotalHeight, 0, 44+ZYHomeBarHeight, 0)
        //  添加协议方法
        collectionView.delegate = self
        collectionView.dataSource = self
        //  设置 cell
        collectionView.register(ZYPhotoCollectionViewCell.self, forCellWithReuseIdentifier: self.cellIdentifier)
        return collectionView
    }()
    
    private var bottomView = ZYAlbumBottomView()
    private lazy var loadingView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: ZYNavigationTotalHeight, width: ZYScreenWidth, height: ZYScreenHeight-ZYNavigationTotalHeight))
        view.backgroundColor = UIColor.clear
        let loadingBackView = UIImageView(frame: CGRect(x: view.frame.width/2-54, y: view.frame.height/2-32-54, width: 108, height: 108))
        loadingBackView.image = UIImage.zyCreateImageWithColor(color: UIColor(white: 0, alpha: 0.8), size: CGSize(width: 108, height: 108))?.zySetRoundedCorner(radius: 6)
        view.addSubview(loadingBackView)
        let loading = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        loading.center = CGPoint(x: 54, y: 54)
        loading.startAnimating()
        loadingBackView.addSubview(loading)
        return view
    }()
    
    //  数据源
    private var photoData = ZYPhotoDataSource()
    
    deinit {
        if ZYPhotoAlbumEnableDebugOn {
            print("=====================\(self)未内存泄露")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            self.photoCollectionView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        self.view.addSubview(self.photoCollectionView)
        self.initNavigation()
        if type == .selectPhoto {
            self.setBottomView()
        }
        self.getAllPhotos()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.setStatusBarStyle(.lightContent, animated: true)
        if self.photoData.dataChanged {
            self.photoCollectionView.reloadData()
            self.completedButtonShow()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.photoData.dataChanged = false
    }
    
    //  MARK:- private method
    private func initNavigation() {
        self.setNavTitle(title: "所有图片")
        self.setBackNav()
        self.setRightTextButton(text: "取消", color: UIColor.white)
        self.view.bringSubview(toFront: self.naviView)
    }
    
    private func setBottomView() {
        self.bottomView.leftClicked = { [unowned self] in
            self.gotoPreviewViewController(previewArray: self.photoData.seletedAssetArray, currentIndex: 0,souceType:1)
        }
        self.bottomView.rightClicked = { [unowned self] in
            self.selectSuccess(fromeView: self.view, selectAssetArray: self.photoData.seletedAssetArray)
        }
        self.view.addSubview(self.bottomView)
    }
    
    private func getAllPhotos() {
        //  注意点！！-这里必须注册通知，不然第一次运行程序时获取不到图片，以后运行会正常显示。体验方式：每次运行项目时修改一下 Bundle Identifier，就可以看到效果。
        PHPhotoLibrary.shared().register(self)
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .restricted || status == .denied {
            // 无权限
            // do something...
            if ZYPhotoAlbumEnableDebugOn {
                print("无相册访问权限")
            }
            let alert = UIAlertController(title: nil, message: "请打开相册访问权限", preferredStyle: .alert)
            let cancleAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alert.addAction(cancleAction)
            let goAction = UIAlertAction(title: "设置", style: .default, handler: { (action) in
                if let url = URL(string: UIApplicationOpenSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.openURL(url)
                }
            })
            alert.addAction(goAction)
            self.present(alert, animated: true, completion: nil)
            return;
        }
        DispatchQueue.global(qos: .userInteractive).async {
            //  获取所有系统图片信息集合体
            let allOptions = PHFetchOptions()
            //  对内部元素排序，按照时间由远到近排序
            allOptions.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]
            //  将元素集合拆解开，此时 allResults 内部是一个个的PHAsset单元
            let fetchAssets = self.assetsFetchResult ?? PHAsset.fetchAssets(with: allOptions)
            self.photoData.assetArray = fetchAssets.objects(at: IndexSet.init(integersIn: 0..<fetchAssets.count))
            if self.photoData.divideArray.count == 0 {
                self.photoData.divideArray = Array(repeating: false, count: self.photoData.assetArray.count)
                self.photoData.dataChanged = false
            }
            DispatchQueue.main.async {
                self.photoCollectionView.reloadData()
            }
        }
    }
    
    private func completedButtonShow() {
        if self.photoData.seletedAssetArray.count > 0 {
            self.bottomView.rightButtonTitle = "完成(\(self.photoData.seletedAssetArray.count))"
            self.bottomView.buttonIsEnabled = true
        } else {
            self.bottomView.rightButtonTitle = "完成"
            self.bottomView.buttonIsEnabled = false
        }
    }
    
    private func showLoadingView(inView: UIView) {
        inView.addSubview(loadingView)
    }
    private func hideLoadingView() {
        loadingView.removeFromSuperview()
    }
    
    // MARK:- handle events
    private func gotoPreviewViewController(previewArray: [PHAsset], currentIndex: Int,souceType:Int) {
        let previewVC = ZYPhotoPreviewViewController()
        previewVC.selectStyle = self.selectStyle
        previewVC.maxSelectCount = maxSelectCount
        previewVC.currentIndex = currentIndex
        previewVC.photoData = self.photoData
        previewVC.from = souceType
        previewVC.previewPhotoArray = previewArray
        previewVC.sureClicked = { [unowned self] (view: UIView, selectPhotos: [PHAsset]) in
            self.selectSuccess(fromeView: view, selectAssetArray: selectPhotos)
        }
        self.navigationController?.pushViewController(previewVC, animated: true)
    }
    
    private func gotoClipViewController(photoImage: UIImage) {
        let clipVC = ZYPhotoClipViewController()
        clipVC.clipBounds = self.clipBounds
        clipVC.photoImage = photoImage
        clipVC.sureClicked = { [unowned self] (clipPhoto: UIImage?) in
            if self.photoAlbumDelegate != nil, self.photoAlbumDelegate!.responds(to: #selector(ZYPhotoAlbumProtocol.photoAlbum(clipPhoto:))) {
                self.photoAlbumDelegate?.photoAlbum!(clipPhoto: clipPhoto)
            }
            self.dismiss(animated: true, completion: nil)
        }
        self.navigationController?.pushViewController(clipVC, animated: true)
    }
    
    private func selectPhotoCell(cell: ZYPhotoCollectionViewCell, index: Int) {
        photoData.divideArray[index] = !photoData.divideArray[index]
        let asset = photoData.assetArray[index]
        if photoData.divideArray[index] {
            if maxSelectCount != 0, photoData.seletedAssetArray.count >= maxSelectCount {
                //超过最大数
                cell.isChoose = false
                photoData.divideArray[index] = !photoData.divideArray[index]
                let alert = UIAlertController(title: nil, message: "您最多只能选择\(maxSelectCount)张照片", preferredStyle: .alert)
                let action = UIAlertAction(title: "我知道了", style: .cancel, handler: nil)
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
                photoCollectionView.reloadData()
                return
            }
            photoData.seletedAssetArray.append(asset)
        } else {
            if let removeIndex = photoData.seletedAssetArray.index(of: asset) {
                photoData.seletedAssetArray.remove(at: removeIndex)
            }
        }
        photoCollectionView.reloadData()
        self.completedButtonShow()
    }
    
    private func selectSuccess(fromeView: UIView, selectAssetArray: [PHAsset]) {
        self.showLoadingView(inView: fromeView)
        var selectPhotos: [ZYPhotoModel] = Array(repeating: ZYPhotoModel(), count: selectAssetArray.count)
        let group = DispatchGroup()
        for i in 0 ..< selectAssetArray.count {
            let asset = selectAssetArray[i]
            group.enter()
            let photoModel = ZYPhotoModel()
            _ = ZYCachingImageManager.default().requestThumbnailImage(for: asset, resultHandler: { (image: UIImage?, dictionry: Dictionary?) in
                photoModel.thumbnailImage = image
            })
            _ = ZYCachingImageManager.default().requestPreviewImage(for: asset, progressHandler: nil, resultHandler: { (image: UIImage?, dictionry: Dictionary?) in
                var downloadFinined = true
                if let cancelled = dictionry![PHImageCancelledKey] as? Bool {
                    downloadFinined = !cancelled
                }
                if downloadFinined, let error = dictionry![PHImageErrorKey] as? Bool {
                    downloadFinined = !error
                }
                if downloadFinined, let resultIsDegraded = dictionry![PHImageResultIsDegradedKey] as? Bool {
                    downloadFinined = !resultIsDegraded
                }
                if downloadFinined, let photoImage = image {
                    photoModel.originImage = photoImage
                    selectPhotos[i] = photoModel
                    group.leave()
                }
            })
        }
        group.notify(queue: DispatchQueue.main, execute: {
            self.hideLoadingView()
            if self.photoAlbumDelegate != nil {
                if self.photoAlbumDelegate!.responds(to: #selector(ZYPhotoAlbumProtocol.photoAlbum(selectPhotoAssets:))){
                    self.photoAlbumDelegate?.photoAlbum!(selectPhotoAssets: selectAssetArray)
                }
                if self.photoAlbumDelegate!.responds(to: #selector(ZYPhotoAlbumProtocol.photoAlbum(selectPhotos:))) {
                    self.photoAlbumDelegate?.photoAlbum!(selectPhotos: selectPhotos)
                }
            }
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    override func rightButtonClick(button: UIButton) {
        self.navigationController?.dismiss(animated: true)
    }
    
    // MARK:- delegate
    //  PHPhotoLibraryChangeObserver  第一次获取相册信息，这个方法只会进入一次
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard self.photoData.assetArray.count == 0 else {return}
        DispatchQueue.main.async {
            self.getAllPhotos()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photoData.assetArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? ZYPhotoCollectionViewCell, self.photoData.assetArray.count > indexPath.row else {return ZYPhotoCollectionViewCell()}
        let asset = self.photoData.assetArray[indexPath.row]
      
        // 新建一个默认类型的图像管理器imageManager
        let imageManager = PHImageManager.default()
        // 新建一个PHImageRequestOptions对象
        let imageRequestOption = PHImageRequestOptions()
        // PHImageRequestOptions是否有效
        imageRequestOption.isSynchronous = true
        // 缩略图的压缩模式设置为无
        imageRequestOption.resizeMode = .none
        // 缩略图的质量为快速
        imageRequestOption.deliveryMode = .fastFormat
        // 按照PHImageRequestOptions指定的规则取出图片
        imageManager.requestImage(for: asset, targetSize: CGSize.init(width: 140, height: 140), contentMode: .aspectFill, options: imageRequestOption, resultHandler: {
            (result, _) -> Void in
            cell.photoImage = result!
        })
        
        if type == .selectPhoto {
            
            if selectStyle == .number {
                if let Index = photoData.seletedAssetArray.index(of: asset) {
                    cell.layer.mask = nil
                    cell.selectNumber = Index
                    cell.selectButton.asyncSetImage(UIImage.zyCreateImageWithView(view: ZYPhotoNavigationViewController.zyGetSelectNuberView(index: "\(Index + 1)")), for: .selected)
                }else{
                    cell.selectButton.isSelected = false
                    if maxSelectCount != 0, photoData.seletedAssetArray.count >= maxSelectCount
                    {
                        let maskLayer = CALayer()
                        maskLayer.frame = cell.bounds
                        maskLayer.backgroundColor = UIColor.init(white: 1, alpha: 0.5).cgColor
                        cell.layer.mask = maskLayer
                    }else{
                        cell.layer.mask = nil
                    }
                }
            }else{
                cell.isChoose = self.photoData.divideArray[indexPath.row]
            }
            cell.selectPhotoCompleted = { [weak self] in
                guard let strongSelf = self else {return}
                strongSelf.selectPhotoCell(cell: cell, index: indexPath.row)
            }
        } else {
            cell.selectButton.isHidden = true
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.type == .selectPhoto {
            self.gotoPreviewViewController(previewArray: self.photoData.assetArray, currentIndex: indexPath.row,souceType:0)
        } else {
            self.showLoadingView(inView: self.view)
            let asset = self.photoData.assetArray[indexPath.row]
            _ = ZYCachingImageManager.default().requestPreviewImage(for: asset, progressHandler: nil, resultHandler: { (image: UIImage?, dictionry: Dictionary?) in
                var downloadFinined = true
                if let cancelled = dictionry![PHImageCancelledKey] as? Bool {
                    downloadFinined = !cancelled
                }
                if downloadFinined, let error = dictionry![PHImageErrorKey] as? Bool {
                    downloadFinined = !error
                }
                if downloadFinined, let resultIsDegraded = dictionry![PHImageResultIsDegradedKey] as? Bool {
                    downloadFinined = !resultIsDegraded
                }
                if downloadFinined, let photoImage = image {
                    self.hideLoadingView()
                    self.gotoClipViewController(photoImage: photoImage)
                }
            })
        }
    }
}


// 相册底部view
class ZYAlbumBottomView: UIView {
    
    private lazy var previewButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 12, y: 2, width: 60, height: 40))
        button.backgroundColor = UIColor.clear
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.setTitle("预览", for: .normal)
        button.setTitleColor(UIColor(white: 0.5, alpha: 1), for: .disabled)
        button.setTitleColor(UIColor.white, for: .normal)
        button.addTarget(self, action: #selector(previewClick(button:)), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    private lazy var sureButton: UIButton = {
        let button = UIButton(frame: CGRect(x: ZYScreenWidth-12-64, y: 6, width: 64, height: 32))
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitle("完成", for: .normal)
        button.setBackgroundImage(UIImage.zyCreateImageWithColor(color: ZYPhotoAlbumSkinColor, size: CGSize(width: 64, height: 32))?.zySetRoundedCorner(radius: 4), for: .normal)
        button.setBackgroundImage(UIImage.zyCreateImageWithColor(color: ZYPhotoAlbumSkinColor.withAlphaComponent(0.5), size: CGSize(width: 64, height: 32))?.zySetRoundedCorner(radius: 4), for: .disabled)
        button.setTitleColor(UIColor(white: 0.5, alpha: 1), for: .disabled)
        button.setTitleColor(UIColor.white, for: .normal)
        button.addTarget(self, action: #selector(sureClick(button:)), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    var leftButtonTitle: String? {
        didSet {
            self.previewButton.setTitle(leftButtonTitle, for: .normal)
        }
    }
    
    var rightButtonTitle: String? {
        didSet {
            self.sureButton.setTitle(rightButtonTitle, for: .normal)
        }
    }
    
    var buttonIsEnabled = false {
        didSet {
            self.previewButton.isEnabled = buttonIsEnabled
            self.sureButton.isEnabled = buttonIsEnabled
        }
    }
    
    // 预览闭包
    var leftClicked: (() -> Void)?
    
    // 完成闭包
    var rightClicked: (() -> Void)?
    
    enum ZYAlbumBottomViewType {
        case normal, noPreview
    }
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: ZYScreenHeight-ZYHomeBarHeight-44, width: ZYScreenWidth, height: 44+ZYHomeBarHeight), type: .normal)
    }
    
    convenience init(type: ZYAlbumBottomViewType) {
        self.init(frame: CGRect(x: 0, y: ZYScreenHeight-ZYHomeBarHeight-44, width: ZYScreenWidth, height: 44+ZYHomeBarHeight), type: type)
    }
    
    convenience override init(frame: CGRect) {
        self.init(frame: frame, type: .normal)
    }
    
    init(frame: CGRect, type: ZYAlbumBottomViewType) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        if type == .normal {
            self.addSubview(self.previewButton)
        }
        
        self.addSubview(self.sureButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: handle events
    @objc func previewClick(button: UIButton) {
        if leftClicked != nil {
            leftClicked!()
        }
    }
    
    @objc func sureClick(button: UIButton) {
        if rightClicked != nil {
            rightClicked!()
        }
    }
}
