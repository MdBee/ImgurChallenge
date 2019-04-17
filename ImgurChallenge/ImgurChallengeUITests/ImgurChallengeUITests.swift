//
//  ImgurChallengeUITests.swift
//  ImgurChallengeUITests
//
//  Created by Matt Bearson on 4/8/19.
//  Copyright © 2019 Matt Bearson. All rights reserved.
//

import XCTest

class ImgurChallengeUITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testToolbarButtonTitleToggle() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let sut = XCUIApplication()

        let nsfwButton = sut.toolbars["Toolbar"].buttons["nsfw is filtered out"]
        nsfwButton.tap()
        
        // If title has changed button won't be found.
        XCTAssertFalse(nsfwButton.exists)
    }

}
