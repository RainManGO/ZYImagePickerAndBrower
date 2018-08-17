//
//  ZYPhotoClipViewController.swift
//  ZYImagePickerAndBrower
//
//  Created by Nvr on 2018/8/17.
//  Copyright © 2018年 ZY. All rights reserved.
//

import UIKit

class ZYPhotoClipViewController: ZYBaseViewController, UIScrollViewDelegate {
    
    var clipBounds: CGSize = CGSize(width: ZYScreenWidth, height: ZYScreenWidth) {
        didSet {
            self.photoImageScrollView.frame = CGRect(origin: CGPoint(x: (ZYScreenWidth-clipBounds.width)/2, y: (ZYScreenHeight-clipBounds.height)/2), size: clipBounds)
        }
    }
    
    //  完成闭包
    var sureClicked: ((_ clipPhoto: UIImage?) -> Void)?
    
    private lazy var photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        
        return imageView
    }()
    
    private lazy var photoImageScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        var frame = CGRect(origin: CGPoint(x: 0, y: (ZYScreenHeight-ZYScreenWidth)/2), size: self.clipBounds)
        scrollView.frame = frame
        scrollView.layer.borderColor = UIColor.white.cgColor
        scrollView.layer.borderWidth = 1
        scrollView.clipsToBounds = false
        scrollView.delegate = self
        scrollView.isUserInteractionEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.maximumZoomScale = self._maxScale
        scrollView.minimumZoomScale = self._minScale
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap(doubleTapGestureRecognizer:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(doubleTapGestureRecognizer)
        scrollView.addSubview(self.photoImageView)
        return scrollView
    }()
    
    private lazy var maskView: ZYPhotoClipMaskView = {
        let view = ZYPhotoClipMaskView(frame: self.view.frame, clipBounds: self.clipBounds)
        return view
    }()
    private var bottomView = ZYAlbumBottomView()
    
    private var currentScale: CGFloat = 1
    private let _maxScale: CGFloat = 3
    private let _minScale: CGFloat = 1
    
    private var setContent = false
    // 图片设置
    var photoImage: UIImage? {
        didSet {
            self.photoImageView.asyncSetImage(photoImage)
            guard let size = self.photoImage?.size, !setContent else {
                return
            }
            setContent = true
            let imageHeight = ZYScreenWidth*size.height/size.width
            self.photoImageView.frame = CGRect(x: 0, y: 0, width: ZYScreenWidth, height: imageHeight)
            self.photoImageScrollView.contentSize = self.photoImageView.frame.size
            if imageHeight > clipBounds.height {
                self.photoImageScrollView.contentOffset.y = (imageHeight-clipBounds.height)/2
            } else {
                self.photoImageView.center.y = clipBounds.height/2
            }
            if ZYScreenWidth > clipBounds.width {
                self.photoImageScrollView.contentOffset.x = (ZYScreenWidth-clipBounds.width)/2
            } else {
                self.photoImageView.center.x = clipBounds.width/2
            }
        }
    }
    
    // 初始缩放大小
    var defaultScale: CGFloat = 1 {
        didSet {
            self.photoImageScrollView.setZoomScale(defaultScale, animated: false)
        }
    }
    
    deinit {
        if ZYPhotoAlbumEnableDebugOn {
            print("=====================\(self)未内存泄露")
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.black
        self.automaticallyAdjustsScrollViewInsets = false
        self.view.clipsToBounds = true
        self.naviView.isHidden = true
        self.view.addSubview(self.photoImageScrollView)
        self.view.addSubview(self.maskView)
        self.setBottomView()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.setStatusBarStyle(.lightContent, animated: true)
    }
    
    //  MARK:- private method
    private func setBottomView() {
        self.bottomView.leftButtonTitle = "取消"
        self.bottomView.rightButtonTitle = "完成"
        self.bottomView.buttonIsEnabled = true
        self.bottomView.leftClicked = { [unowned self] in
            self.navigationController?.popViewController(animated: true)
        }
        self.bottomView.rightClicked = { [unowned self] in
            let clipImage = self.getClipImage()
            if self.sureClicked != nil {
                self.sureClicked!(clipImage)
            }
        }
        self.view.addSubview(self.bottomView)
    }
    
    private func getClipImage() -> UIImage? {
        guard let originImageSize = self.photoImage?.size else {
            return nil
        }
        let widthScale = originImageSize.width/self.photoImageView.frame.width
        let heightScale = originImageSize.height/self.photoImageView.frame.height
        var clipImagePoint = CGPoint(x: self.photoImageScrollView.contentOffset.x*widthScale, y: self.photoImageScrollView.contentOffset.y*heightScale)
        var clipImageSize = CGSize(width: self.clipBounds.width*widthScale, height: self.clipBounds.height*heightScale)
        if clipImagePoint.x < 0 {clipImagePoint.x = 0}
        if clipImagePoint.y < 0 {clipImagePoint.y = 0}
        if clipImageSize.width > originImageSize.width {clipImageSize.width = originImageSize.width}
        if clipImageSize.height > originImageSize.height {clipImageSize.height = originImageSize.height}
        if let croppedImage = self.photoImage?.cgImage?.cropping(to: CGRect(origin: clipImagePoint, size: clipImageSize)) {
            return UIImage(cgImage: croppedImage)
        }
        return nil
    }
    
    // 双击手势
    @objc func doubleTap(doubleTapGestureRecognizer: UITapGestureRecognizer) {
        //当前倍数等于最大放大倍数
        //双击默认为缩小到原图
        let aveScale = _minScale + (_maxScale - _minScale) / _maxScale //中间倍数
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
        var xcenter = scrollView.center.x-(ZYScreenWidth-clipBounds.width)/2 , ycenter = scrollView.center.y-(ZYScreenHeight-clipBounds.height)/2
        //目前contentsize的width是否大于原scrollview的contentsize，如果大于，设置imageview中心x点为contentsize的一半，以固定imageview在该contentsize中心。如果不大于说明图像的宽还没有超出屏幕范围，可继续让中心x点为屏幕中点，此种情况确保图像在屏幕中心。
        xcenter = scrollView.contentSize.width > scrollView.frame.size.width ? scrollView.contentSize.width/2 : xcenter;
        ycenter = scrollView.contentSize.height > scrollView.frame.size.height ? scrollView.contentSize.height/2 : ycenter;
        self.photoImageView.center = CGPoint(x: xcenter, y: ycenter)
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.currentScale = scale
    }
}

fileprivate class ZYPhotoClipMaskView: UIView {
    
    convenience init() {
        self.init(frame: CGRect())
    }
    
    convenience override init(frame: CGRect) {
        self.init(frame: frame, clipBounds: CGSize(width: ZYScreenWidth, height: ZYScreenWidth))
    }
    
    init(frame: CGRect, clipBounds: CGSize) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.isUserInteractionEnabled = true
        let path = UIBezierPath(rect: self.bounds)
        path.append(UIBezierPath(rect: CGRect(origin: CGPoint(x: (ZYScreenWidth-clipBounds.width)/2, y: (ZYScreenHeight-clipBounds.height)/2), size: clipBounds)).reversing())
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor(white: 0, alpha: 0.7).cgColor
        shapeLayer.path = path.cgPath
        self.layer.addSublayer(shapeLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }
}
