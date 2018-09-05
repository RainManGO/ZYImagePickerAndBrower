//
//  ZYPhotoPreviewViewController.swift
//  ZYImagePickerAndBrower
//
//  Created by Nvr on 2018/8/17.
//  Copyright © 2018年 ZY. All rights reserved.
//

import UIKit
import Photos

class ZYPhotoPreviewViewController: ZYBaseViewController, UICollectionViewDelegate, UICollectionViewDataSource ,UICollectionViewDelegateFlowLayout{
    
    var currentSelectIndexPath:IndexPath?
    var maxSelectCount = 0
    var selectStyle:SelectStyle = .number
    var isFristLoadCell = false
    var fristLoadSelectIndex = 0
    var currentIndex = 0
    var from:Int = 0  // 0是全部预览   1选择预览
    //  数据源(预览选择时用)
    var photoData = ZYPhotoDataSource()
    //  浏览数据源
    var previewPhotoArray = [PHAsset]()
    //  完成闭包
    var sureClicked: ((_ view: UIView, _ selectPhotos: [PHAsset]) -> Void)?
    
    private let cellIdentifier = "PreviewCollectionCell"
    
    private var scrollDistance: CGFloat = 0
    private var willDisplayCellAndIndex: (cell: ZYPreviewCollectionViewCell, indexPath: IndexPath)?
    private var isFirstCell = true
    
    private var requestIDs = [PHImageRequestID]()
    
    private lazy var photoCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        flowLayout.itemSize = CGSize(width: ZYScreenWidth+10, height: ZYScreenHeight)
        flowLayout.scrollDirection = .horizontal
        //  collectionView
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: ZYScreenWidth+10, height: ZYScreenHeight), collectionViewLayout: flowLayout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.isPagingEnabled = true
        //  添加协议方法
        collectionView.delegate = self
        collectionView.dataSource = self
        //  设置 cell
        collectionView.register(ZYPreviewCollectionViewCell.self, forCellWithReuseIdentifier: self.cellIdentifier)
        return collectionView
    }()
    
    private lazy var thumbnailCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        //        flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        //        flowLayout.minimumInteritemSpacing = 10
        //        flowLayout.minimumLineSpacing = 0
        //        flowLayout.itemSize = CGSize(width: 70, height: 70)
        flowLayout.scrollDirection = .horizontal
        flowLayout.headerReferenceSize = CGSize(width: 10, height: 70)
        //  collectionView
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: ZYScreenHeight-ZYHomeBarHeight-44 - 81, width: ZYScreenWidth, height: 80), collectionViewLayout: flowLayout)
        collectionView.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        collectionView.isPagingEnabled = false
        //  添加协议方法
        collectionView.delegate = self
        collectionView.dataSource = self
        //  设置 cell
        collectionView.register(PreviewSmallCollectionViewCell.self, forCellWithReuseIdentifier: "PreviewSmallCollectionViewCellId")
        return collectionView
    }()
    
    private lazy var bottomView = ZYAlbumBottomView(type: .noPreview)
    
    deinit {
        if ZYPhotoAlbumEnableDebugOn {
            print("=====================\(self)未内存泄露")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.black
        self.automaticallyAdjustsScrollViewInsets = false
        self.view.addSubview(self.photoCollectionView)
        self.view.addSubview(self.thumbnailCollectionView)
        self.initNavigation()
        self.setBottomView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.photoCollectionView.selectItem(at: IndexPath(item: self.currentIndex, section: 0), animated: false, scrollPosition: .left)
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        if parent == nil {
            for id in self.requestIDs {
                ZYCachingImageManager.default().cancelImageRequest(id)
            }
        }
    }
    
    //  MARK:- private method
    private func initNavigation() {
        self.setBackNav()
        if let index = self.photoData.assetArray.index(of: self.previewPhotoArray[currentIndex]) {
            var image:UIImage?
            if let selectIndex = self.photoData.seletedAssetArray.index(of: self.previewPhotoArray[currentIndex]){
                if selectStyle == .number{
                    image = UIImage.zyCreateImageWithView(view: ZYPhotoNavigationViewController.zyGetSelectNuberView(index: "\(selectIndex + 1)"))
                }else{
                    image = ZYSelectSkinImage
                }
            }
            self.setRightImageButton(normalImage: UIImage.zyImageFromeBundle(named: "album_select_gray.png"), selectedImage: image, isSelected: self.photoData.divideArray[index])
        }
        self.view.bringSubview(toFront: self.naviView)
    }
    
    private func setBottomView() {
        //        self.bottomView.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        self.bottomView.rightClicked = { [unowned self] in
            if self.sureClicked != nil {
                self.sureClicked!(self.view, self.photoData.seletedAssetArray)
            }
        }
        self.view.addSubview(self.bottomView)
        self.completedButtonShow()
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
    
    private func setPreviewImage(cell: ZYPreviewCollectionViewCell, asset: PHAsset) {
        let pixelScale = CGFloat(asset.pixelWidth)/CGFloat(asset.pixelHeight)
        let id = ZYCachingImageManager.default().requestPreviewImage(for: asset, progressHandler: { (progress: Double, error: Error?, pointer: UnsafeMutablePointer<ObjCBool>, dictionry: Dictionary?) in
            //下载进度
            DispatchQueue.main.async {
                let progressView = ZYProgressView.showZYProgressView(in: cell.contentView, frame: CGRect(x: cell.frame.width-20-12, y: cell.frame.midY+(cell.frame.width/pixelScale-20)/2-12, width: 20, height: 20))
                progressView.progress = progress
            }
        }, resultHandler: { (image: UIImage?, dictionry: Dictionary?) in
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
                cell.photoImage = photoImage
            }
        })
        self.requestIDs.append(id)
    }
    
    // handle events
    override func rightButtonClick(button: UIButton) {
        
        if let index = self.photoData.assetArray.index(of: self.previewPhotoArray[currentIndex]) {
            //            button.isSelected = !button.isSelected
            self.photoData.divideArray[index] = !self.photoData.divideArray[index]
            if self.photoData.divideArray[index] {
                if self.maxSelectCount != 0, self.photoData.seletedAssetArray.count >= self.maxSelectCount {
                    button.isSelected = false
                    //超过最大数
                    self.photoData.divideArray[index] = !self.photoData.divideArray[index]
                    let alert = UIAlertController(title: nil, message: "您最多只能选择\(maxSelectCount)张照片", preferredStyle: .alert)
                    let action = UIAlertAction(title: "我知道了", style: .cancel, handler: nil)
                    alert.addAction(action)
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                self.photoData.seletedAssetArray.append(self.previewPhotoArray[currentIndex])
                self.rightButton.isSelected = true
            } else {
                self.rightButton.isSelected = false
            }
            
            let selectIndex = self.photoData.seletedAssetArray.index(of: self.previewPhotoArray[currentIndex])
            if selectIndex != nil{
                self.rightButton.asyncSetImage(UIImage.zyCreateImageWithView(view: ZYPhotoNavigationViewController.zyGetSelectNuberView(index: "\(selectIndex! + 1)")), for: .selected)
            }
            
            if selectIndex != nil{
                if self.rightButton.isSelected == false {
                    let indexPath = IndexPath.init(row: selectIndex!, section: 0)
                    self.photoData.seletedAssetArray.remove(at: self.photoData.seletedAssetArray.index(of: self.previewPhotoArray[currentIndex])!)
                    thumbnailCollectionView.deleteItems(at: [indexPath])
                }else{
                    let indexPath = IndexPath.init(row: selectIndex!, section: 0)
                    thumbnailCollectionView.insertItems(at: [indexPath])
                    thumbnailCollectionView.reloadItems(at: [indexPath])
                    thumbnailCollectionViewCellToggeleSelect(indexPath: indexPath)
                }
            }
            
            self.completedButtonShow()
        }
    }
    
    func thumbnailCollectionViewCellToggeleSelect(indexPath:IndexPath){
        if currentSelectIndexPath != nil {
            let befrorecell = thumbnailCollectionView.cellForItem(at: currentSelectIndexPath!)
            befrorecell?.contentView.layer.borderColor = UIColor.clear.cgColor
            befrorecell?.contentView.layer.borderWidth = 0
        }
        
        currentSelectIndexPath = indexPath
        let cell = thumbnailCollectionView.cellForItem(at: indexPath)
        cell?.contentView.layer.borderColor = ZYPhotoAlbumSkinColor.cgColor
        cell?.contentView.layer.borderWidth = 2
        
    }
    
    func thumbnailCollectionViewCellClearAllSelect(){
        for index in 0...self.photoData.seletedAssetArray.count {
            let cell = thumbnailCollectionView.cellForItem(at: IndexPath.init(row: index, section: 0))
            cell?.contentView.layer.borderColor = UIColor.clear.cgColor
            cell?.contentView.layer.borderWidth = 0
        }
    }
    
    // MARK:- delegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == thumbnailCollectionView {
            return self.photoData.seletedAssetArray.count
        }
        return self.previewPhotoArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == thumbnailCollectionView {
            let smallCell = collectionView.dequeueReusableCell(withReuseIdentifier: "PreviewSmallCollectionViewCellId", for: indexPath) as! PreviewSmallCollectionViewCell
            let  asset = self.photoData.seletedAssetArray[indexPath.row]
            
            // 新建一个默认类型的图像管理器imageManager
            let imageManager = PHImageManager.default()
            // 新建一个PHImageRequestOptions对象
            let imageRequestOption = PHImageRequestOptions()
            // PHImageRequestOptions是否有效
            imageRequestOption.isSynchronous = true
            // 缩略图的压缩模式设置为无
            imageRequestOption.resizeMode = .none
            // 缩略图的质量为高质量，不管加载时间花多少
            imageRequestOption.deliveryMode = .highQualityFormat
            // 按照PHImageRequestOptions指定的规则取出图片
            imageManager.requestImage(for: asset, targetSize: CGSize.init(width: 140, height: 140), contentMode: .aspectFill, options: imageRequestOption, resultHandler: {
                (result, _) -> Void in
                smallCell.photoImage = result!
            })
            
            if isFristLoadCell == false{
                if let selectIndex = self.photoData.seletedAssetArray.index(of: self.previewPhotoArray[currentIndex]),selectIndex == indexPath.row{
                    fristLoadSelectIndex = selectIndex
                    smallCell.contentView.layer.borderColor = ZYPhotoAlbumSkinColor.cgColor
                    smallCell.contentView.layer.borderWidth = 2
                    currentSelectIndexPath = IndexPath.init(row: selectIndex, section: 0)
                    isFristLoadCell = true
                }
            }
            
            return smallCell
            
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ZYPreviewCollectionViewCell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if  collectionView == thumbnailCollectionView {
            
        }else{
            let asset = self.previewPhotoArray[indexPath.row]
            
            let id = ZYCachingImageManager.default().requestThumbnailImage(for: asset) { (image: UIImage?, dictionry: Dictionary?) in
                (cell as! ZYPreviewCollectionViewCell).photoImage = image ?? UIImage()
            }
            self.requestIDs.append(id)
            
            self.willDisplayCellAndIndex = (cell as! ZYPreviewCollectionViewCell, indexPath)
            if indexPath.row == self.currentIndex && self.isFirstCell {
                self.isFirstCell = false
                self.setPreviewImage(cell: cell as! ZYPreviewCollectionViewCell, asset: asset)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if  collectionView == thumbnailCollectionView {
            
        }else{
            (cell as! ZYPreviewCollectionViewCell).defaultScale = 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if  collectionView == thumbnailCollectionView {
            return 10
        }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if  collectionView == thumbnailCollectionView {
            return CGSize(width: 70, height: 70)
        }else{
            return CGSize(width: ZYScreenWidth+10, height: ZYScreenHeight)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if thumbnailCollectionView == collectionView {
            thumbnailCollectionViewCellToggeleSelect(indexPath: indexPath)
            var index = 0
            if from == 0{
                let asset = self.photoData.seletedAssetArray[indexPath.row]
                index = self.photoData.assetArray.index(of: asset)!
            }else{
                index = indexPath.row
            }
            
            self.photoCollectionView.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: .left)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if thumbnailCollectionView == collectionView {
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.contentView.layer.borderColor = UIColor.clear.cgColor
            cell?.contentView.layer.borderWidth = 0
        }else{
            
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView == photoCollectionView {
            self.scrollDistance = scrollView.contentOffset.x
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == photoCollectionView{
            self.currentIndex = Int(round(scrollView.contentOffset.x/scrollView.bounds.width))
            if self.currentIndex >= self.previewPhotoArray.count {
                self.currentIndex = self.previewPhotoArray.count-1
            } else if self.currentIndex < 0 {
                self.currentIndex = 0
            }
            
            if let selectIndex = self.photoData.seletedAssetArray.index(of: self.previewPhotoArray[currentIndex]){
                self.rightButton.asyncSetImage(UIImage.zyCreateImageWithView(view: ZYPhotoNavigationViewController.zyGetSelectNuberView(index: "\(selectIndex + 1)")), for: .selected)
                self.rightButton.isSelected = true
                let selectIndexPath = IndexPath.init(row: selectIndex, section: 0)
                thumbnailCollectionViewCellClearAllSelect()
                thumbnailCollectionViewCellToggeleSelect(indexPath: selectIndexPath)
                if selectIndex >= 2{
                    let offSetX:Int = selectIndex - 2
                    thumbnailCollectionView.contentOffset = CGPoint(x:offSetX * 80, y: 0)
                }else{
                    thumbnailCollectionView.contentOffset = CGPoint(x:0, y: 0)
                }
            }else{
                if currentSelectIndexPath != nil{
                    self.collectionView(thumbnailCollectionView, didDeselectItemAt: currentSelectIndexPath!)
                }
                self.rightButton.isSelected = false
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == photoCollectionView{
            if scrollView.contentOffset.x != self.scrollDistance {
                let currentCell = self.photoCollectionView.cellForItem(at: IndexPath(item: self.currentIndex, section: 0)) as! ZYPreviewCollectionViewCell
                let asset = self.previewPhotoArray[self.currentIndex]
                self.setPreviewImage(cell: currentCell, asset: asset)
            }
        }
    }
    
}

