//
//  PagingViewController.swift
//  SimpleImageViewer
//
//  Created by Jonathan Sahoo on 7/31/18.
//  Copyright © 2018 aFrogleap. All rights reserved.
//

import UIKit

public class PagingViewController: UIPageViewController {

    public var images = [UIImage]() {
        didSet {
            images.forEach { image in
                let configuration = ImageViewerConfiguration { config in
                    config.image = image
                }
                pages.append(ImageViewerController(configuration: configuration))
            }

        }
    }

    var pages = [UIViewController]() {
        didSet {
            if let firstVC = pages.first {
                setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
            }
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
    }
}

extension PagingViewController: UIPageViewControllerDataSource {
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {

        guard let viewControllerIndex = pages.index(of: viewController) else { return nil }

        let previousIndex = viewControllerIndex - 1

        guard previousIndex >= 0 else { return pages.last }

        guard pages.count > previousIndex else { return nil }

        return pages[previousIndex]
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.index(of: viewController) else { return nil }

        let nextIndex = viewControllerIndex + 1

        guard nextIndex < pages.count else { return pages.first }

        guard pages.count > nextIndex else { return nil }

        return pages[nextIndex]
    }
}
