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
    
    fileprivate var pageCache = PageCache()
    fileprivate var loadCache = LoadCache()
    fileprivate var tabLayout = TabLayout()
    fileprivate var contentLayout = ContentLayout()
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
        // TODO1: arrowView的な扱いをどうするか考える
//        arrowView = ArrowView(frame: CGRect(x: 0, y: 0, width: 30, height: 10))
        
        self.addSubview(tabScrollView)
        self.addSubview(contentScrollView)
        // TODO1: arrowView的な扱いをどうするか考える
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

        // set custom attrs
        tabScrollView.backgroundColor = tabLayout.backgroundColor
        contentScrollView.backgroundColor = contentLayout.backgroundColor
        // TODO1: 扱いどうするか考える
//        arrowView.arrorBackgroundColor = self.tabSectionBackgroundColor
//        arrowView.isHidden = !arrowIndicator
        
        // first time setup pages
        build()

        // async necessarily
        DispatchQueue.main.async {
            // first time set defaule pageIndex
            // TODO3: 開始状態の調査
            // TODO3: pageIndexの正体調査
//            self.initWithPageIndex(self.pageIndex ?? self.defaultPage)
//            self.isStarted = true
            
            // load pages
            self.loadContents()
        }
    }

    // MARK: - Configure
    
    open func reloadData() {
        build()
        loadContents()
    }

    // MARK: Build

    func build() {
        loadCache.maxLimit = tabViews().count
        pageCache.removeAll()
        (tabScrollView.subviews + contentScrollView.subviews).forEach {
            $0.removeFromSuperview()
        }
        guard loadCache.maxLimit > 0 else {
            return
        }
        let source = buildTabContent()
        pageCache.source = source.source
        tabLayout.height = source.height
        let contentHeight = frame.height - tabLayout.height
        configureTabViews { [weak self] barContentWidth in
            self?.configureScrollViews(with: .init(width: barContentWidth,
                                                   height: contentHeight))
        }
    }

    func buildTabContent() -> (source: [Int : UIView], height: CGFloat) {
        return (0 ..< loadCache.maxLimit)
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
        for idx in 0 ..< loadCache.maxLimit {
            if let tabView = pageCache.source[idx] {
                tabView.frame = CGRect(
                    origin: CGPoint(
                        x: reducedTabWidth,
                        y: tabLayout.height - tabView.frame.height),
                    size: tabView.frame.size)
                
                // bind event
                tabView.tag = idx
                tabView.isUserInteractionEnabled = true
                // TODO3: ExpressTabView専用のメソッドを指定するように置換する
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
        // TODO3: 正しいメソッドを紐づける
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

        // TODO1: 扱いをどうするか考える
        // reset the origin of arrow view
//        arrowView.frame.origin = CGPoint(x: (self.frame.width - arrowView.frame.width) / 2, y: tabSectionHeight)
    }

    // MARK: Load

    func loadContents() {
        guard tabViews().count > 0 else {
            return
        }
        let offset = 1

        // WIP:
//        let leftBoundIndex = pageIndex - offset > 0 ? pageIndex - offset : 0
//        let rightBoundIndex = pageIndex + offset < cacheCount ? pageIndex + offset : cacheCount - 1
//
//        var currentContentWidth: CGFloat = 0.0
//        for i in 0 ..< cacheCount {
//            let width = frame.width
//            if (i >= leftBoundIndex && i <= rightBoundIndex) {
//                let pageFrame = CGRect(
//                    x: currentContentWidth,
//                    y: 0,
//                    width: width,
//                    height: contentScrollView.frame.size.height)
//                insertPageAtIndex(i, frame: pageFrame)
//            }
//            currentContentWidth += width
//        }
//        contentScrollView.contentSize = CGSize(width: currentContentWidth, height: contentScrollView.frame.height)
        
        // remove older caches
        while (pageCache.sourceQueue.count > loadCache.preloadLimit()) {
            if let (_, view) = pageCache.sourceQueue.popFirst() {
                view.removeFromSuperview()
            }
        }
    }
}

// MARK: - ExpressTabView Extensions

extension ExpressTabView {

    // MARK: Cache

    struct PageCache {
        var source = [Int: UIView]()
        var sourceQueue = CacheQueue<Int, UIView>()
    }
    
    struct LoadCache {

        static var minimum: Int {
            return 3
        }

        var maxLimit = 0
        var preload = LoadCache.minimum

        func preloadLimit() -> Int {
            guard preload > LoadCache.minimum else {
                return LoadCache.minimum
            }
            guard preload > 1 else {
                return maxLimit
            }
            return preload
        }
    }

    // MARK: Layout
    
    struct TabLayout {
        var height: CGFloat = 0
        var backgroundColor: UIColor = .white
    }
    
    struct ContentLayout {
        var backgroundColor: UIColor = .white
    }
}

extension ExpressTabView.PageCache {

    mutating func removeAll() {
        source.removeAll()
        sourceQueue.removeAll()
    }
}

extension ExpressTabView: UIScrollViewDelegate {

    
}

    }
    
    struct ContentLayout {
        var backgroundColor: UIColor = .white
    }
}

extension ExpressTabView: UIScrollViewDelegate {

    
}
