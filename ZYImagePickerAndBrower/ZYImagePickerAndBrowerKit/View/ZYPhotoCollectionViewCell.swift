//
//  ZYPhotoCollectionViewCell.swift
//  ZYImagePickerAndBrower
//
//  Created by Nvr on 2018/8/17.
//  Copyright © 2018年 ZY. All rights reserved.
//

import UIKit

class ZYPhotoCollectionViewCell: UICollectionViewCell {
    lazy var selectButton: UIButton = {
        let button = UIButton()
        let contenViewSize = self.contentView.bounds.size
        button.frame = CGRect(x: contenViewSize.width * 2 / 3 - 2, y: 2, width: contenViewSize.width / 3, height: contenViewSize.width / 3)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: contenViewSize.width/3 - contenViewSize.width/4, bottom: contenViewSize.width/3 - contenViewSize.width/4, right: 0)
        button.asyncSetImage(UIImage.zyImageFromeBundle(named: "album_select_gray.png"), for: .normal)
        button.addTarget(self, action: #selector(selelctButtonClick(button:)), for: .touchUpInside)
        return button
    }()
    
    lazy var photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = self.contentView.bounds
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    var selectNumber = 0 {
        didSet {
            self.selectButton.isSelected = true
        }
    }
    
    //  cell 是否被选择
    var isChoose = false {
        didSet {
            self.selectButton.isSelected = isChoose
        }
    }
    
    // 图片选中闭包
    var selectPhotoCompleted: (() -> Void)?
    
    // 图片设置
    var photoImage: UIImage? {
        didSet {
            self.photoImageView.image = photoImage
        }
    }
    
    convenience init() {
        self.init(frame: CGRect.init())
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.photoImageView)
        self.contentView.addSubview(self.selectButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func selelctButtonClick(button: UIButton) {
        //        self.isChoose = !self.isChoose
        if selectPhotoCompleted != nil {
            selectPhotoCompleted!()
        }
    }
}


class PreviewSmallCollectionViewCell: UICollectionViewCell {
    
    lazy var photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = self.contentView.bounds
        imageView.contentMode = .scaleAspectFill
        imageView.frame = self.bounds
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // 图片设置
    var photoImage: UIImage? {
        didSet {
            self.photoImageView.image = photoImage
        }
    }
    
    
    convenience init() {
        self.init(frame: CGRect.init())
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.photoImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
