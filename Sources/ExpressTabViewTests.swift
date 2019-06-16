//
//  ExpressTabViewTests.swift
//  ExpressTabViewDemoTests
//
//  Created by moaible on 2019/06/16.
//  Copyright © 2019 jxpress. All rights reserved.
//

import Foundation
import XCTest
@testable import ExpressTabViewDemo

let iPhoneXSize: CGSize = .init(width: 414,
                                height: 896)

func tabView(with size: CGSize) -> ExpressTabView {
    return ExpressTabView(frame: .init(origin: .zero,
                                       size: size))
}

func show(with tabView: ExpressTabView,
          completion: @escaping () -> Void)
{
    tabView.bootsequence {
        completion()
    }
}

class ExpressTabViewTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInitialize() {
        let view = tabView(with: iPhoneXSize)
        XCTAssertNotNil(view.tabScrollView)
        XCTAssertNotNil(view.contentScrollView)

        // tab
        XCTAssertFalse(view.tabScrollView.isPagingEnabled)
        XCTAssertEqual(view.tabScrollView.delegate as? UIView,
                       view)
        XCTAssertEqual(view.tabScrollView.frame, .zero)
        
        // content
        XCTAssertTrue(view.contentScrollView.isPagingEnabled)
        XCTAssertEqual(view.contentScrollView.delegate as? UIView,
                       view)
        XCTAssertEqual(view.contentScrollView.frame, .zero)
    }

    func testFirstShoing() {
        let view = tabView(with: iPhoneXSize)
        show(with: view) {
            // tab
            XCTAssertEqual(
                view.tabScrollView.frame,
                .init(origin: .zero,
                      size: .zero))
            // content
//            XCTAssertEqual(view.contentScrollView.frame, .zero)
        }
        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func testPerformanceExample() {
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
