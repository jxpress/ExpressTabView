//
//  ExpressTabView.swift
//  ExpressTabViewDemo
//
//  Created by moaible on 2019/06/15.
//  Copyright © 2019 jxpress. All rights reserved.
//

import Foundation
import UIKit

open class ExpressTabView: UIView {

    // MARK: - Properties

    // MARK: Views
    
    fileprivate var tabScrollView: UIScrollView!
    fileprivate var contentScrollView: UIScrollView!
    
    // MARK: Configuration
    
    fileprivate var cache = Cache()
    fileprivate var tabLayout = TabLayout()
    open var tabViews: (() -> [UIView]) = { [] }
    private var tabWidth: ((Int) -> CGFloat) = { _ in 0 }
    open var pagingEnabled: Bool = true {
        didSet {
            contentScrollView.isPagingEnabled = pagingEnabled
        }
    }

    // MARK: - Initialize

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    fileprivate func initialize() {
        // bind configure action
        tabWidth = { [weak self] idx in
            self?.tabViews()[idx].frame.width ?? 0
        }

        // init views
        tabScrollView = UIScrollView()
        contentScrollView = UIScrollView()
        // TODO: arrowView的な扱いをどうするか考える
//        arrowView = ArrowView(frame: CGRect(x: 0, y: 0, width: 30, height: 10))
        
        self.addSubview(tabScrollView)
        self.addSubview(contentScrollView)
        // TODO: arrowView的な扱いをどうするか考える
//        self.addSubview(arrowView)

        tabScrollView.isPagingEnabled = false
        tabScrollView.showsHorizontalScrollIndicator = false
        tabScrollView.showsVerticalScrollIndicator = false
        tabScrollView.delegate = self
        contentScrollView.isPagingEnabled = pagingEnabled
        contentScrollView.showsHorizontalScrollIndicator = false
        contentScrollView.showsVerticalScrollIndicator = false
        contentScrollView.delegate = self
    }

    // MARK: - Layout
    
    open override func layoutSubviews() {
        super.layoutSubviews()
    }

    // MARK: - Configure
    
    open func reloadData() {
        build()
        loadContents()
    }

    // MARK: Build

    func build() {
        cache.count = tabViews().count
        cache.removeAll()
        (tabScrollView.subviews + contentScrollView.subviews).forEach {
            $0.removeFromSuperview()
        }
        guard cache.count > 0 else {
            return
        }
        let source = buildTabContent()
        cache.source = source.source
        tabLayout.height = source.height
        let contentHeight = frame.height - tabLayout.height
        configureTabViews { [weak self] barContentWidth in
            self?.configureScrollViews(with:
                .init(width: barContentWidth, height: contentHeight))
        }
    }

    func buildTabContent() -> (source: [Int : UIView], height: CGFloat) {
        return (0 ..< cache.count)
            .reduce(into: ([Int : UIView](), CGFloat(0)), { [weak self] source, idx in
                guard let strongSelf = self else {
                    return
                }
                let views = strongSelf.tabViews()
                let tabView = views[idx]
                source.0[idx] = tabView
                source.1 = max(strongSelf.tabLayout.height, tabView.frame.height)
            })
    }

    func configureTabViews(completion: (CGFloat) -> Void) {
        var reducedTabWidth: CGFloat = 0
        for idx in 0 ..< cache.count {
            if let tabView = cache.source[idx] {
                tabView.frame = CGRect(
                    origin: CGPoint(
                        x: reducedTabWidth,
                        y: tabLayout.height - tabView.frame.height),
                    size: tabView.frame.size)
                
                // bind event
                tabView.tag = idx
                tabView.isUserInteractionEnabled = true
                // TODO: ExpressTabView専用のメソッドを指定するように置換する
//                tabView.addGestureRecognizer(UITapGestureRecognizer(
//                    target: self, action: #selector(ACTabScrollView.tabViewDidClick(_:))))
                tabScrollView.addSubview(tabView)
            }
            reducedTabWidth += tabWidth(idx)
        }
        completion(reducedTabWidth)
    }

    func configureScrollViews(with contentSize: CGSize) {
        // reset the fixed size of tab section
        tabScrollView.frame = CGRect(x: 0, y: 0, width: frame.width, height: tabLayout.height)
        // TODO: 正しいメソッドを紐づける
//        tabScrollView.addGestureRecognizer(UITapGestureRecognizer(
//            target: self, action: #selector(ACTabScrollView.tabSectionScrollViewDidClick(_:))))
        tabScrollView.contentInset = UIEdgeInsets(
            top: 0,
            left: (frame.width / 2) - (tabWidth(0) / 2),
            bottom: 0,
            right: (frame.width / 2) - (tabWidth(tabViews().count - 1) / 2))
        tabScrollView.contentSize = CGSize(width: contentSize.width, height: tabLayout.height)
        // reset the fixed size of content section
        contentScrollView.frame = CGRect(x: 0, y: tabLayout.height, width: frame.width, height: contentSize.height)

        // TODO: 扱いをどうするか考える
        // reset the origin of arrow view
//        arrowView.frame.origin = CGPoint(x: (self.frame.width - arrowView.frame.width) / 2, y: tabSectionHeight)
    }

    // MARK: Load

    func loadContents() {
        guard tabViews().count > 0 else {
            return
        }
        let offset = 1
//        let leftBoundIndex =
        // WIP:
    }
}

// MARK: - ExpressTabView.Cache

extension ExpressTabView {

    struct Cache {
        var count = 0
        var source = [Int: UIView]()
        var sourceQueue = CacheQueue<Int, UIView>()
        var preloadFrames = 3
    }
}

extension ExpressTabView.Cache {

    mutating func removeAll() {
        source.removeAll()
        sourceQueue.removeAll()
    }
}

// MARK: - ExpressTabView.Layout

extension ExpressTabView {
    
    struct TabLayout {
        var height: CGFloat = 0
    }
}

extension ExpressTabView: UIScrollViewDelegate {

    
}
