//
//  ViewController.swift
//  ZYImagePickerAndBrower
//
//  Created by Nvr on 2018/8/17.
//  Copyright © 2018年 ZY. All rights reserved.
//

import UIKit

class ViewController: UIViewController,ZYPhotoAlbumProtocol {

    @IBOutlet weak var imagePickerView: ZYImagePickerLayoutView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func selectPhotoBtnClick(_ sender: UIButton) {
       goPickerController()
    }
    
    func photoAlbum(selectPhotos: [ZYPhotoModel]) {
        imagePickerView.dataSource = selectPhotos
        imagePickerView.numberOfLine = 4
        imagePickerView.reloadView()
        imagePickerView.addCallBack = { () in
            self.goPickerController()
        }
    }
    
    func  goPickerController() {
        let photoAlbumVC = ZYPhotoNavigationViewController(photoAlbumDelegate: self, photoAlbumType: .selectPhoto)    //初始化需要设置代理对象
        photoAlbumVC.maxSelectCount = 9   //最大可选择张数
        self.navigationController?.present(photoAlbumVC, animated: true, completion: nil)
    }
}

