//
//  DetailViewController.swift
//  NationalGeographic
//
//  Created by Chaosky on 2016/11/15.
//  Copyright © 2016年 ChaosVoid. All rights reserved.
//

import UIKit
import Alamofire
import MBProgressHUD
import SnapKit
import YYCategories

class AlbumDetailViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var albumID: String? = nil
    
    var pictureListModel: PictureListModel!
    
    var currentIndex = 0
    
    @IBOutlet weak var picNameLabel: UILabel!
    
    @IBOutlet weak var picIndexLabel: UILabel!
    
    @IBOutlet weak var contentWebView: UIWebView!
    
    @IBOutlet var showOrHideViews: [UIView]!
    
    var pageViewController: UIPageViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupViews()
        requestAlbumDetail()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setupViews() {
        let tapGesture = UITapGestureRecognizer { (gesture) in
            self.showOrHideViewsTapped()
        }
        self.view.addGestureRecognizer(tapGesture)
    }
    
    func initialPageViewController() {
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        self.addChildViewController(pageViewController)
        self.view.addSubview(pageViewController.view)
        pageViewController.view.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.view)
        }
        self.view.sendSubview(toBack: pageViewController.view)
        let initPictureDetail = self.createPictureDetail()
        initPictureDetail.pictureModel = self.pictureListModel.picture![0]
        self.pageViewController.setViewControllers([initPictureDetail], direction: .forward, animated: false, completion: nil)
    }
    
    func showOrHideViewsTapped() {
        UIView.animate(withDuration: 0.5, animations: {
            for view in self.showOrHideViews {
                view.alpha = view.alpha == 0 ? 1 : 0;
            }
        })
    }
    
    func requestAlbumDetail() {
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.mode = .indeterminate
        if albumID != nil {
            Alamofire.request("http://dili.bdatu.com/jiekou/albums/a\(albumID!).html").responseString(queue: nil, encoding: String.Encoding.utf8, completionHandler: { (response) in
                
                guard let JSON = response.result.value else {
                    
                    let error = response.result.error
                    
                    hud.mode = .text
                    hud.label.text = "加载失败"
                    hud.detailsLabel.text = "错误描述：\(error?.localizedDescription ?? "")"
                    hud.hide(animated: true, afterDelay: 1)
                    
                    return
                }
                
                let handleJSON = JSON.removeControlCharacters()
                guard let model = PictureListModel.yy_model(withJSON: handleJSON) else {
                    hud.hide(animated: true)
                    return
                }
                self.pictureListModel = model
                DispatchQueue.main.async {
                    self.initialPageViewController()
                    self.updateViews()
                    hud.hide(animated: true)
                }
                
            })
        }
        
    }
    
    func createPictureDetail() -> PictureDetailViewController {
        let pictureDetail = self.storyboard?.instantiateViewController(withIdentifier: "PictureDetailViewController") as! PictureDetailViewController
        return pictureDetail
    }
    
    func updateViews() {
        
        if let count = pictureListModel?.counttotal {
            picIndexLabel.text = "\(currentIndex+1)/\(count)"
        }
        
        if let currentPic = pictureListModel?.picture?[currentIndex] {
            picNameLabel.text = currentPic.title
            let html = "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\"><link href=\"jianjie.css\" type=\"text/css\" rel=\"stylesheet\"  /></head><body><p>\(currentPic.content!)（摄像：\(currentPic.author!)）</p></body></html>"
            contentWebView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
        }
    }
    
    func nextViewController(_ viewController: PictureDetailViewController, before: Bool) -> PictureDetailViewController? {
        if let index = pictureListModel.picture?.index(of: viewController.pictureModel!) {
            let nextIndex = before ? index - 1 : index + 1
            if nextIndex < 0 || nextIndex >= (pictureListModel.picture?.count)! {
                return nil
            }
            else {
                let detailVC = self.createPictureDetail()
                detailVC.pictureModel = pictureListModel.picture?[nextIndex]
                return detailVC
            }
        }
        else {
            return nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func shareTapped(_ sender: UIButton) {
        guard let pictureModel = pictureListModel?.picture?[currentIndex] else {
            return
        }
        
        ShareManager.share(text: pictureModel.content, thumbImages: pictureModel.url, images: pictureModel.url, url: nil, title: pictureModel.title, type: .auto)
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        guard let currentPictureDetail = pageViewController.viewControllers?.first as? PictureDetailViewController else {
            return
        }
        
        if let image = currentPictureDetail.imageView.image {
            if !image.isEqual(UIImage(named: "nopic")) {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
    
    func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeMutableRawPointer) {
        if error == nil {
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            hud.mode = .text
            hud.label.text = "已保存至相册"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                hud.hide(animated: true)
            })
        }
    }
    
    @IBAction func backTapped(_ sender: UIButton) {
        _ = navigationController?.popViewController(animated: true)
        
    }
    
    // MARK: - UIPageViewControllerDataSource
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return nextViewController(viewController as! PictureDetailViewController, before: true)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return nextViewController(viewController as! PictureDetailViewController, before: false)
    }
    
    // MARK: - UIPageViewControllerDelegate
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let visiableVC = pageViewController.viewControllers?.first as? PictureDetailViewController {
            currentIndex = (pictureListModel.picture?.index(of: visiableVC.pictureModel))!
            updateViews()
        }
    }

}