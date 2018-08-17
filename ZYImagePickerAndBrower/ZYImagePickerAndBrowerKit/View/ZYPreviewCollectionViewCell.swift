//
//  ZYPreviewCollectionViewCell.swift
//  ZYImagePickerAndBrower
//
//  Created by Nvr on 2018/8/17.
//  Copyright © 2018年 ZY. All rights reserved.
//

import UIKit

class ZYPreviewCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate {
    
    var oneTapClosure: ((UITapGestureRecognizer) -> Void)?
    
    lazy var photoImageView: UIImageView = {
        let imageView = UIImageView()
        var frame = self.contentView.bounds
        frame.size.width -= 10
        imageView.frame = frame
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        
        return imageView
    }()
    
    private lazy var photoImageScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        var frame = self.contentView.bounds
        frame.size.width -= 10
        scrollView.frame = frame
        scrollView.delegate = self
        scrollView.isUserInteractionEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.maximumZoomScale = self._maxScale
        scrollView.minimumZoomScale = self._minScale
        let oneTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(oneTap(oneTapGestureRecognizer:)))
        oneTapGestureRecognizer.numberOfTapsRequired = 1
        oneTapGestureRecognizer.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(oneTapGestureRecognizer)
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap(doubleTapGestureRecognizer:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(doubleTapGestureRecognizer)
        oneTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        //        scrollView.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleHeight]
        return scrollView
    }()
    
    private var currentScale: CGFloat = 1
    private let _maxScale: CGFloat = 2
    private let _minScale: CGFloat = 1
    
    // 图片设置
    var photoImage: UIImage? {
        didSet {
            self.photoImageView.image = photoImage
            guard let size = self.photoImage?.size else {
                return
            }
            let imageHeight = ZYScreenWidth*size.height/size.width
            let frame = CGRect(x: 0, y: 0, width: ZYScreenWidth, height: imageHeight)
            self.photoImageView.frame = frame
            self.photoImageView.center = self.photoImageScrollView.center
            self.photoImageScrollView.contentSize = self.photoImageView.frame.size
        }
    }
    
    // 初始缩放大小
    var defaultScale: CGFloat = 1 {
        didSet {
            self.photoImageScrollView.setZoomScale(defaultScale, animated: false)
        }
    }
    
    convenience init() {
        self.init(frame: CGRect.init())
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.photoImageScrollView.addSubview(self.photoImageView)
        self.contentView.addSubview(self.photoImageScrollView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 单击手势
    @objc func oneTap(oneTapGestureRecognizer: UITapGestureRecognizer) {
        if oneTapClosure != nil {
            oneTapClosure!(oneTapGestureRecognizer)
        }
    }
    
    // 双击手势
    @objc func doubleTap(doubleTapGestureRecognizer: UITapGestureRecognizer) {
        //当前倍数等于最大放大倍数
        //双击默认为缩小到原图
        let aveScale = _minScale + (_maxScale - _minScale) / 2.0 //中间倍数
        if currentScale >= aveScale {
            currentScale = _minScale
            self.photoImageScrollView.setZoomScale(currentScale, animated: true)
        } else if currentScale < aveScale {
            currentScale = _maxScale
            let touchPoint = doubleTapGestureRecognizer.location(in: doubleTapGestureRecognizer.view)
            self.photoImageScrollView.zoom(to: CGRect(x: touchPoint.x, y: touchPoint.y, width: 10, height: 10), animated: true)
        }
    }
    
    //MARK: -UIScrollView delegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.photoImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        var xcenter = scrollView.center.x , ycenter = scrollView.center.y
        //目前contentsize的width是否大于原scrollview的contentsize，如果大于，设置imageview中心x点为contentsize的一半，以固定imageview在该contentsize中心。如果不大于说明图像的宽还没有超出屏幕范围，可继续让中心x点为屏幕中点，此种情况确保图像在屏幕中心。
        xcenter = scrollView.contentSize.width > scrollView.frame.size.width ? scrollView.contentSize.width/2 : xcenter;
        ycenter = scrollView.contentSize.height > scrollView.frame.size.height ? scrollView.contentSize.height/2 : ycenter;
        self.photoImageView.center = CGPoint(x: xcenter, y: ycenter)
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.currentScale = scale
    }
}
