//
//  ImgurChallengeTests.swift
//  ImgurChallengeTests
//
//  Created by Matt Bearson on 4/8/19.
//  Copyright © 2019 Matt Bearson. All rights reserved.
//

import XCTest
@testable import ImgurChallenge

class ImgurChallengeTests: XCTestCase {

    func testMessageLabelTextForHidden() {
        let sut = MasterViewController()
        let str = sut.textForMessageLabel(state: .hidden)
        
        XCTAssertEqual(str, "", "Method should return an empty string for .hidden state.")
    }

}
