//
//  ZoomingImageView.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 5/21/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

import UIKit
import FLAnimatedImage

fileprivate let ZoomScaleEpsilon: CGFloat = 0.01

@objc(AXZoomingImageView) class ZoomingImageView: UIScrollView, UIScrollViewDelegate {
    
    var image: UIImage? {
        set(value) {
            self.updateImageView(image: value, animatedImage: nil)
        }
        get {
            return self.imageView.image
        }
    }
    
    var animatedImage: FLAnimatedImage? {
        set(value) {
            self.updateImageView(image: nil, animatedImage: value)
        }
        get {
            return self.imageView.animatedImage
        }
    }
    
    public override var frame: CGRect {
        didSet {
            self.updateZoomScale()
        }
    }
    
    fileprivate(set) var doubleTapGestureRecognizer = UITapGestureRecognizer()
    fileprivate(set) var imageView = FLAnimatedImageView()
    
    fileprivate var needsUpdateImageView = false

    public init() {
        super.init(frame: .zero)
        
        self.doubleTapGestureRecognizer.numberOfTapsRequired = 2
        self.doubleTapGestureRecognizer.addTarget(self, action: #selector(doubleTapAction(_:)))
        self.doubleTapGestureRecognizer.isEnabled = false
        self.addGestureRecognizer(self.doubleTapGestureRecognizer)
        
        self.imageView.layer.masksToBounds = true
        self.imageView.contentMode = .scaleAspectFit
        self.addSubview(self.imageView)
        
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.isScrollEnabled = false
        self.bouncesZoom = true
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func updateImageView(image: UIImage?, animatedImage: FLAnimatedImage?) {
        self.imageView.transform = .identity
        var imageSize: CGSize = .zero
        
        if let animatedImage = animatedImage {
            if self.imageView.animatedImage != animatedImage {
                self.imageView.animatedImage = animatedImage
            }
            imageSize = animatedImage.size
        } else if let image = image {
            if self.imageView.image != image {
                self.imageView.image = image
            }
            imageSize = image.size
        } else {
            self.imageView.animatedImage = nil
            self.imageView.image = nil
        }
        
        self.imageView.frame = CGRect(origin: .zero, size: imageSize)
        self.contentSize = imageSize
        self.updateZoomScale()
        
        self.doubleTapGestureRecognizer.isEnabled = (image != nil || animatedImage != nil)
        
        self.needsUpdateImageView = false
    }
    
    override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        
        if subview === self.imageView {
            self.needsUpdateImageView = true
        }
    }
    
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        
        if subview === self.imageView && self.needsUpdateImageView {
            self.updateImageView(image: self.imageView.image, animatedImage: self.imageView.animatedImage)
        }
    }
    
    // MARK: - UIScrollViewDelegate
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.isScrollEnabled = true
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ?
            (scrollView.bounds.size.width - scrollView.contentSize.width) / 2 : 0
        let offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ?
            (scrollView.bounds.size.height - scrollView.contentSize.height) / 2 : 0
        self.imageView.center = CGPoint(x: offsetX + (scrollView.contentSize.width / 2), y: offsetY + (scrollView.contentSize.height / 2))
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard abs(scale - self.minimumZoomScale) <= ZoomScaleEpsilon else {
            return
        }
        
        scrollView.isScrollEnabled = false
    }
    
    // MARK: - Zoom scale
    fileprivate func updateZoomScale() {
        guard let imageSize = self.imageView.image?.size ?? self.imageView.animatedImage?.size else {
            return
        }
        
        let scaleWidth = self.bounds.size.width / imageSize.width
        let scaleHeight = self.bounds.size.height / imageSize.height
        self.minimumZoomScale = min(scaleWidth, scaleHeight)
        self.maximumZoomScale = self.minimumZoomScale * 3.5
        
        // if the zoom scale is the same, change it to force the UIScrollView to
        // recompute the scroll view's content frame
        if abs(self.zoomScale - self.minimumZoomScale) <= .ulpOfOne {
            self.zoomScale = self.minimumZoomScale + 0.1
        }
        self.zoomScale = self.minimumZoomScale
        
        self.isScrollEnabled = false
    }
    
    // MARK: - UITapGestureRecognizer
    @objc fileprivate func doubleTapAction(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: self.imageView)
        
        var zoomScale = self.maximumZoomScale
        if self.zoomScale >= self.maximumZoomScale || abs(self.zoomScale - self.maximumZoomScale) <= ZoomScaleEpsilon {
            zoomScale = self.minimumZoomScale
        }
        
        let width = self.bounds.size.width / zoomScale
        let height = self.bounds.size.height / zoomScale
        let originX = point.x - (width / 2)
        let originY = point.y - (height / 2)
        
        let zoomRect = CGRect(x: originX, y: originY, width: width, height: height)
        self.zoom(to: zoomRect, animated: true)
    }

}
