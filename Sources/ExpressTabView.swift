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
    
    // MARK: State
    
    fileprivate var activedScrollView: UIScrollView?
    fileprivate var isStarted = false
    fileprivate var hasChangePageCompletion = false
    fileprivate var changePageCompletion: (() -> Void)?
    
    // MARK: Cache
    
    var pageCache = PageCache()
    var loadCache = LoadCache()
    fileprivate var indexCache = IndexCache()
    
    // MARK: Configuration
    
    open var defaultPageIndex = 0
    open var contentViews: (() -> [UIView]) = { [] }
    open var tabViews: (() -> [UIView]) = { [] }
    open var pagingEnabled: Bool = true {
        didSet {
            contentScrollView.isPagingEnabled = pagingEnabled
        }
    }
    open var tabScrollInterlocked: Bool = false

    open var tabLayout = TabLayout()
    open var contentLayout = ContentLayout()
    fileprivate var tabWidth: ((Int) -> CGFloat) = { _ in 0 }
    
    // MARK: Action
    
    open var movingTab: (Int) -> () = { _ in }
    open var scrollingTab: (Int) -> () = { _ in }
    
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
        
        // reset status and stop scrolling immediately
        if isStarted {
            isStarted = false
            stopScrolling()
        }
        
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
            self.switchPage(with: self.indexCache.page ?? self.defaultPageIndex)
            self.isStarted = true
            
            // load pages
            self.loadContents()
        }
    }
    
    // MARK: -
    
    open func changePage(to index: Int, animated: Bool) {
        activedScrollView = tabScrollView
        move(to: index, animated: animated)
    }
    
    open func changePage(to index: Int, animated: Bool, completion: @escaping (() -> Void)) {
        hasChangePageCompletion = true
        changePageCompletion = completion
        changePage(to: index, animated: animated)
    }
    
    open func reloadData() {
        build()
        loadContents()
    }
    
    func build() {
        loadCache.maxLimit = tabViews().count
        pageCache.removeAll()
        (tabScrollView.subviews + contentScrollView.subviews).forEach {
            $0.removeFromSuperview()
        }
        guard loadCache.maxLimit > 0 else {
            return
        }
        let tabSource = buildTabViews()
        pageCache.source = tabSource.source
        tabLayout.height = tabSource.height
        let contentHeight = frame.height - tabLayout.height
        configureTabViews { [weak self] barContentWidth in
            self?.configureScrollViews(with: .init(width: barContentWidth,
                                                   height: contentHeight))
        }
    }
    
    func buildTabViews() -> (source: [Int : UIView], height: CGFloat) {
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
                tabView.addGestureRecognizer(UITapGestureRecognizer(
                    target: self, action: #selector(ExpressTabView.tabViewDidClick(_:))))
                tabScrollView.addSubview(tabView)
            }
            reducedTabWidth += tabWidth(idx)
        }
        completion(reducedTabWidth)
    }
    
    func configureScrollViews(with contentSize: CGSize) {
        // reset the fixed size of tab section
        tabScrollView.frame = CGRect(x: 0, y: 0, width: frame.width, height: tabLayout.height)
        tabScrollView.addGestureRecognizer(UITapGestureRecognizer(
            target: self, action: #selector(ExpressTabView.tabSectionScrollViewDidClick(_:))))
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
    
    fileprivate func move(to index: Int, animated: Bool) {
        guard 0 <= index, index < loadCache.maxLimit else {
            return
        }
        if (pagingEnabled) {
            // force stop
            stopScrolling()
            if activedScrollView != contentScrollView {
                activedScrollView = contentScrollView
                contentScrollView.scrollRectToVisible(.init(
                    origin: CGPoint(x: frame.width * CGFloat(index), y: 0),
                    size: frame.size), animated: true)
            }
        }
        if (indexCache.lastMarkPage != index) {
            indexCache.lastMarkPage = index
            
            // callback
            movingTab(index)
        }
    }
    
    // MARK: - Tab Action
    
    @objc func tabViewDidClick(_ recognizer: UITapGestureRecognizer) {
        activedScrollView = tabScrollView
        move(to: recognizer.view!.tag, animated: true)
    }
    
    @objc func tabSectionScrollViewDidClick(_ recognizer: UITapGestureRecognizer) {
        activedScrollView = tabScrollView
        move(to: indexCache.page, animated: true)
    }
    
    // MARK: Load
    
    func loadContents() {
        guard tabViews().count > 0 else {
            return
        }
        let offset = 1
        let leftBoundIndex = indexCache.page - offset > 0 ? indexCache.page - offset : 0
        let rightBoundIndex = indexCache.page + offset < loadCache.maxLimit ? indexCache.page + offset : loadCache.maxLimit - 1
        
        var currentContentWidth: CGFloat = 0.0
        for i in 0 ..< loadCache.maxLimit {
            let width = frame.width
            if (i >= leftBoundIndex && i <= rightBoundIndex) {
                let pageFrame = CGRect(
                    x: currentContentWidth,
                    y: 0,
                    width: width,
                    height: contentScrollView.frame.size.height)
                insertPage(at: i, frame: pageFrame)
            }
            currentContentWidth += width
        }
        contentScrollView.contentSize = CGSize(width: currentContentWidth, height: contentScrollView.frame.height)
        
        // remove older caches
        while (pageCache.sourceQueue.count > loadCache.preloadLimit()) {
            if let (_, view) = pageCache.sourceQueue.popFirst() {
                view.removeFromSuperview()
            }
        }
    }
    
    // MARK: Private
    
    fileprivate func currentPageIndex() -> Int {
        let width = frame.width
        let currentPageIndex = Int((contentScrollView.contentOffset.x + (0.5 * width)) / width)
        guard currentPageIndex > 0 else {
            return 0
        }
        guard currentPageIndex < loadCache.maxLimit else {
            return loadCache.maxLimit - 1
        }
        return currentPageIndex
    }
    
    fileprivate func insertPage(at index: Int, frame: CGRect) {
        if (pageCache.sourceQueue[index] == nil) {
            let contents = contentViews()
            guard contents.indices.contains(index) else {
                return
            }
            let page = contents[index]
            page.frame = frame
            pageCache.sourceQueue[index] = page
            contentScrollView.addSubview(page)
        } else {
            pageCache.sourceQueue.awake(index)
        }
    }
    
    fileprivate func stopScrolling() {
        tabScrollView.setContentOffset(tabScrollView.contentOffset, animated: false)
        contentScrollView.setContentOffset(contentScrollView.contentOffset, animated: false)
    }
    
    fileprivate func switchPage(with index: Int) {
        // set pageIndex
        indexCache.switch(with: index)
        
        // init UI
        guard loadCache.maxLimit > 0 else {
            return
        }
        
        // WIP:
        var tabOffsetX = 0 as CGFloat
        var contentOffsetX = 0 as CGFloat
        for idx in 0 ..< index {
            tabOffsetX += tabWidth(idx)
            contentOffsetX += frame.width
        }
        // set default position of tabs and contents
        tabScrollView.contentOffset = CGPoint(x: tabOffsetX - (frame.width - tabWidth(index)) / 2,
                                              y: tabScrollView.contentOffset.y)
        contentScrollView.contentOffset = CGPoint(x: contentOffsetX, y: contentScrollView.contentOffset.y)
        // TODO2: styleの更新をしてそう、あとで対応
//        updateTabAppearance(animated: false)
    }
}

// MARK: - ExpressTabView Extensions

public extension ExpressTabView {
    
    // MARK: Cache
    
    public struct PageCache {
        var source = [Int: UIView]()
        var sourceQueue = CacheQueue<Int, UIView>()
    }
    
    public struct LoadCache {
        
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
    
    public struct IndexCache {
        
        var page: Int!
        
        /// show / tab tap
        var lastMarkPage: Int?
    }
    
    // MARK: Layout
    
    public struct TabLayout {
        var height: CGFloat = 0
        var backgroundColor: UIColor = .white
    }
    
    public struct ContentLayout {
        var backgroundColor: UIColor = .white
    }
}

extension ExpressTabView.PageCache {
    
    mutating func removeAll() {
        source.removeAll()
        sourceQueue.removeAll()
    }
}

extension ExpressTabView.IndexCache {
    
    mutating func `switch`(with index: Int) {
        page = index
        lastMarkPage = page
    }
}

extension ExpressTabView: UIScrollViewDelegate {
    
    // scrolling animation begin by dragging
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // stop current scrolling before start another scrolling
        stopScrolling()
        // set the activedScrollView
        activedScrollView = scrollView
    }
    
    // scrolling animation stop with decelerating
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        move(to: currentPageIndex(), animated: true)
    }
    
    // scrolling animation stop without decelerating
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            move(to: currentPageIndex(), animated: true)
        }
    }
    
    // scrolling animation stop programmatically
    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard hasChangePageCompletion else {
            return
        }
        hasChangePageCompletion = false
        changePageCompletion?()
    }
    
    // scrolling
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // TODO3: scrollViewDidScroll
        let currentIndex = currentPageIndex()
        if scrollView == activedScrollView {
            let speed = frame.width / tabWidth(currentIndex)
            let halfWidth = frame.width * 0.5
            let total: (tabWidth: CGFloat, contentWidth: CGFloat) = (0 ..< currentIndex).reduce(
                into: (CGFloat(0), CGFloat(0)),
                { [weak self] total, idx in
                    guard let strongSelf = self else {
                        return
                    }
                    total.0 += strongSelf.tabWidth(idx)
                    total.1 += strongSelf.frame.width
            })
            if scrollView == tabScrollView, tabScrollInterlocked {
                contentScrollView.contentOffset.x = ((tabScrollView.contentOffset.x + halfWidth - total.tabWidth) * speed)
                    + total.contentWidth - halfWidth
            }
            if scrollView == contentScrollView {
                tabScrollView.contentOffset.x = ((contentScrollView.contentOffset.x + halfWidth - total.contentWidth) / speed)
                    + total.tabWidth - halfWidth
            }
            // TODO2: デザインの微調整？
//            updateTabAppearance()
        }
        
        if isStarted && indexCache.page != currentIndex {
            // set index
            indexCache.page = currentIndex
            
            // lazy loading
            loadContents()
            
            // callback
            scrollingTab(currentIndex)
        }
    }
}
