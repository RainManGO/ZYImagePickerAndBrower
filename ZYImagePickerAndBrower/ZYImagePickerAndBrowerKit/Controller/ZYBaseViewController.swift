//
//  ZYBaseViewController.swift
//  ZYImagePickerAndBrower
//
//  Created by Nvr on 2018/8/17.
//  Copyright © 2018年 ZY. All rights reserved.
//

import UIKit

public class ZYBaseViewController: UIViewController {
    
    let naviView = UIView(frame: CGRect(x: 0, y: 0, width: ZYScreenWidth, height: ZYNavigationTotalHeight))
    lazy var rightButton: UIButton = {
        let rightButton = UIButton()
        rightButton.frame = CGRect(x: ZYScreenWidth-50, y: ZYStatusBarHeight, width: 50, height: ZYNavigationHeight)
        rightButton.backgroundColor = UIColor.clear
        rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        rightButton.addTarget(self, action: #selector(rightButtonClick(button:)), for: .touchUpInside)
        return rightButton
    }()
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(frame: CGRect(x: ZYScreenWidth/2-50, y: ZYStatusBarHeight, width: 100, height: ZYNavigationHeight))
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        return titleLabel
    }()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationController?.navigationBar.isHidden = true
        self.setNavigationView()
    }
    
    fileprivate func setNavigationView() {
        naviView.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        self.view.addSubview(naviView)
    }
    
    func setBackNav() {
        let backImage = UIImage.zyImageFromeBundle(named: "icon_back_white.png")
        let backButton = UIButton(frame: CGRect(x: 0, y: ZYStatusBarHeight, width: 50, height: ZYNavigationHeight))
        backButton.backgroundColor = UIColor.clear
        backButton.imageView?.contentMode = .center
        backButton.asyncSetImage(backImage, for: .normal)
        backButton.addTarget(self, action: #selector(backClick(button:)), for: .touchUpInside)
        naviView.addSubview(backButton)
    }
    
    func setNavTitle(title: String) {
        titleLabel.text = title
        if !titleLabel.isDescendant(of: naviView) {
            naviView.addSubview(titleLabel)
        }
    }
    
    func setRightTextButton(text: String, color: UIColor) {
        rightButton.setTitle(text, for: .normal)
        rightButton.setTitleColor(color, for: .normal)
        naviView.addSubview(rightButton)
    }
    
    func setRightImageButton(normalImage: UIImage?, selectedImage: UIImage?, isSelected: Bool) {
        rightButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 13, bottom: 10, right: 13)
        rightButton.asyncSetImage(normalImage, for: .normal)
        rightButton.asyncSetImage(selectedImage, for: .selected)
        rightButton.isSelected = isSelected
        naviView.addSubview(rightButton)
    }
    
    @objc func backClick(button: UIButton) {
        self.navigationController!.popViewController(animated: true)
    }
    
    @objc func rightButtonClick(button: UIButton) {
        
    }
    
}

