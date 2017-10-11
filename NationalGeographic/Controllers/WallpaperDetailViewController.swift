//
//  WallpaperDetailViewController.swift
//  NationalGeographic
//
//  Created by Chaosky on 2016/11/20.
//  Copyright © 2016年 ChaosVoid. All rights reserved.
//

import UIKit
import Kingfisher
import MBProgressHUD

class WallpaperDetailViewController: UIViewController, UIScrollViewDelegate {
    
    var wallpaperModel: UnsplashModel!

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupViews()
    }
    
    func setupViews() {
        scrollView.delegate = self
        scrollView.maximumZoomScale = 2
        
        if let url = wallpaperModel.full_url {
            imageView.kf.setImage(with: URL(string: url), placeholder:#imageLiteral(resourceName: "unsplash_loading"), options: [.transition(.fade(0.5))])
        }
        
        let tapGesture = UITapGestureRecognizer { (gesture) in
            self.scrollView.zoomScale = self.scrollView.zoomScale == 1 ? 2 : 1;
        }
        tapGesture.numberOfTapsRequired = 2
        self.scrollView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollView.zoomScale = 1
        self.view.layoutIfNeeded()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveImageTapped(_ sender: UIButton) {
        if let saveImage = imageView.image {
            Utils.writeImageToPhotosAlbum(saveImage)
        }
    }
    
    // MARK: - UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
