import UIKit
import SDWebImage

public final class ImageViewerController: UIViewController {

    @IBOutlet fileprivate var scrollView: UIScrollView!
    @IBOutlet fileprivate var imageView: UIImageView!
    @IBOutlet fileprivate var overlayView: UIView!
    @IBOutlet fileprivate var activityIndicator: UIActivityIndicatorView!

    private let thresholdVelocity: CGFloat = 500 // The speed of swipe needs to be at least this amount of pixels per second for the swipe to finish dismissal.
    private let swipeToDismissRecognizer = UIPanGestureRecognizer()

    private var image: UIImage?
    private var swipingToDismiss = false
    private var swipeToDismissTransition: GallerySwipeToDismissTransition?

    var controllerIsSwipingToDismiss: ((_ distanceToEdge: CGFloat) -> Void)?
    var controllerDidDismissViaSwipe: (() -> Void)?
    
    public init(image: UIImage) {
        self.image = image
        super.init(nibName: String(describing: type(of: self)), bundle: Bundle(for: type(of: self)))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
        
        setupScrollView()
        setupGestureRecognizers()

        // Disable scrolling when fully zoomed out (which we are by default)
        scrollView.isScrollEnabled = false
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        overlayView.alpha = PagingViewController.overlayIsHidden ? 0 : 1
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Reset zoom when view disappears
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
    }

    deinit {
        self.scrollView?.removeObserver(self, forKeyPath: "contentOffset")
    }
}

private extension ImageViewerController {
    func setupScrollView() {
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.addObserver(self, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    func setupGestureRecognizers() {
        let doubleTapGestureRecognizer = UITapGestureRecognizer()
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.addTarget(self, action: #selector(handleDoubleTap))
        scrollView.addGestureRecognizer(doubleTapGestureRecognizer)

        let singleTapGestureRecognizer = UITapGestureRecognizer()
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        singleTapGestureRecognizer.addTarget(self, action: #selector(handleSingleTap))
        scrollView.addGestureRecognizer(singleTapGestureRecognizer)
        singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)

        swipeToDismissRecognizer.addTarget(self, action: #selector(handleSwipe))
        swipeToDismissRecognizer.delegate = self
        view.addGestureRecognizer(swipeToDismissRecognizer)
        swipeToDismissRecognizer.require(toFail: doubleTapGestureRecognizer)
    }
    
    @IBAction func closeButtonPressed() {
        dismiss(animated: true)
    }

    @objc func handleSingleTap(recognizer: UITapGestureRecognizer) {
        let targetAlpha: CGFloat = overlayView.alpha == 1 ? 0 : 1
        UIView.animate(withDuration: 0.15, animations: { [weak self] in
            self?.overlayView.alpha = targetAlpha
        })
        PagingViewController.overlayIsHidden = targetAlpha == 0
    }
    
    @objc func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
            var zoomRect = CGRect.zero
            zoomRect.size.height = imageView.frame.size.height / scale
            zoomRect.size.width  = imageView.frame.size.width  / scale
            let newCenter = scrollView.convert(center, from: imageView)
            zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
            zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
            return zoomRect
        }

        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            scrollView.isScrollEnabled = false
        } else {
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: recognizer.location(in: recognizer.view)), animated: true)
            scrollView.isScrollEnabled = true
        }
    }
}

extension ImageViewerController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard let image = imageView.image else { return }
        let imageViewSize = Utilities.aspectFitRect(forSize: image.size, insideRect: imageView.frame)
        let verticalInsets = -(scrollView.contentSize.height - max(imageViewSize.height, scrollView.bounds.height)) / 2
        let horizontalInsets = -(scrollView.contentSize.width - max(imageViewSize.width, scrollView.bounds.width)) / 2
        scrollView.contentInset = UIEdgeInsets(top: verticalInsets, left: horizontalInsets, bottom: verticalInsets, right: horizontalInsets)
    }
}

// MARK: - Swipe To Dismiss

extension ImageViewerController: UIGestureRecognizerDelegate {

    // We only want the swipeToDismissRecognizer to handle vertical swipes. Horizontal swipes should be disregarded so that the UIPageViewController can handle it for paging
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == swipeToDismissRecognizer else { return false }
        let velocity = swipeToDismissRecognizer.velocity(in: swipeToDismissRecognizer.view)
        return abs(velocity.y) > abs(velocity.x)
    }

    @objc func handleSwipe(_ recognizer: UIPanGestureRecognizer) {
        /// A deliberate UX decision...you have to zoom back in to scale 1 to be able to swipe to dismiss. It is difficult for the user to swipe to dismiss from images larger then screen bounds because almost all the time it's not swiping to dismiss but instead panning a zoomed in picture on the canvas.
        guard scrollView.zoomScale == scrollView.minimumZoomScale else { return }

        let currentVelocity = recognizer.velocity(in: self.view)
        let currentTouchPoint = recognizer.translation(in: view)

        swipingToDismiss = true

        switch recognizer.state {
        case .began:
            swipeToDismissTransition = GallerySwipeToDismissTransition(scrollView: self.scrollView)
        case .changed:
            swipeToDismissTransition?.updateInteractiveTransition(verticalOffset: -currentTouchPoint.y)
        case .ended:
            self.handleSwipeToDismissEnded(finalVelocity: currentVelocity, finalTouchPoint: currentTouchPoint)
        default:
            break
        }
    }

    func handleSwipeToDismissEnded(finalVelocity velocity: CGPoint, finalTouchPoint touchPoint: CGPoint) {

        let swipeToDismissCompletionBlock = { [weak self] in
            UIApplication.applicationWindow.windowLevel = UIWindowLevelNormal
            self?.swipingToDismiss = false
            self?.controllerDidDismissViaSwipe?()
        }

        switch velocity {
        // Swiping Up
        case _ where velocity.y < -thresholdVelocity:
            swipeToDismissTransition?.finishInteractiveTransition(touchPoint: touchPoint.y,
                                                                  targetOffset: (view.bounds.height / 2) + (imageView.bounds.height / 2),
                                                                  escapeVelocity: velocity.y,
                                                                  completion: swipeToDismissCompletionBlock)
        // Swiping Down
        case _ where thresholdVelocity < velocity.y:
            swipeToDismissTransition?.finishInteractiveTransition(touchPoint: touchPoint.y,
                                                                  targetOffset: -(view.bounds.height / 2) - (imageView.bounds.height / 2),
                                                                  escapeVelocity: velocity.y,
                                                                  completion: swipeToDismissCompletionBlock)
        // If none of the above select cases, we cancel.
        default:
            swipeToDismissTransition?.cancelTransition() { [weak self] in
                self?.swipingToDismiss = false
            }
        }
    }

    // Reports the continuous progress of Swipe To Dismiss to the Paging View Controller
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard swipingToDismiss, keyPath == "contentOffset" else { return }
        let distanceToEdge: CGFloat = (scrollView.bounds.height / 2) + (imageView.bounds.height / 2)
        let percentDistance: CGFloat = fabs(scrollView.contentOffset.y / distanceToEdge)
        controllerIsSwipingToDismiss?(percentDistance)
    }
}

extension UIApplication {
    static var applicationWindow: UIWindow {
        return (UIApplication.shared.delegate?.window?.flatMap { $0 })!
    }
}

