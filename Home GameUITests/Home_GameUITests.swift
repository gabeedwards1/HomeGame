//
//  Home_GameUITests.swift
//  Home GameUITests
//
//  Created by Gabe Edwards on 8/1/26.
//

import XCTest

final class Home_GameUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    /// Launches the app with a clean in-memory SwiftData store so every test
    /// starts from a blank slate regardless of prior runs, and never touches
    /// the real local game data on the device/simulator.
    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
        return app
    }

    private func setUpChipsAndBlinds(app: XCUIApplication) {
        let blindFields = app.textFields.matching(identifier: "Amount")
        blindFields.element(boundBy: 0).tap()
        blindFields.element(boundBy: 0).typeText("0.10")
        blindFields.element(boundBy: 1).tap()
        blindFields.element(boundBy: 1).typeText("0.25")
        app.staticTexts["Chip & Blind Setup"].tap()

        let colorField = app.textFields["New Chip Color"]
        let priceField = app.textFields["New Chip Price"]
        let addChipButton = app.buttons["Add Chip"]
        let chips: [(color: String, price: String)] = [
            ("White", "0.05"), ("Red", "0.10"), ("Green", "0.25"), ("Blue", "0.50"), ("Black", "1.00")
        ]
        for chip in chips {
            colorField.tap()
            colorField.typeText(chip.color)
            priceField.tap()
            priceField.typeText(chip.price)
            app.staticTexts["Chip & Blind Setup"].tap()
            addChipButton.tap()
        }
    }

    private func addPlayer(app: XCUIApplication, name: String, amount: String) {
        let nameField = app.textFields["Name"]
        let buyInField = app.textFields["New Player Buy-in"]
        nameField.tap()
        nameField.typeText(name)
        buyInField.tap()
        buyInField.typeText(amount)
        app.staticTexts["Add Players"].tap()
        app.buttons["Add Player"].tap()
    }

    private func settleUp(app: XCUIApplication, playerName: String, blackChipCount: String) {
        app.staticTexts[playerName].tap()
        app.buttons["Settle Up"].tap()
        let countFields = app.textFields.matching(identifier: "0")
        let blackField = countFields.element(boundBy: 4) // White, Red, Green, Blue, Black
        blackField.tap()
        blackField.typeText(blackChipCount)
        app.staticTexts["Count Your Chips"].tap()
        app.buttons["Confirm Settle Up"].tap()
    }

    @MainActor
    func testAppLaunchesToStartScreen() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Home Game"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["New Game"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testChipSetupAndAddPlayersValidation() throws {
        let app = launchApp()

        app.buttons["New Game"].tap()
        XCTAssertTrue(app.navigationBars["Chip & Blind Setup"].waitForExistence(timeout: 5))

        let chipSetupContinue = app.buttons["Continue"]
        let addChipButton = app.buttons["Add Chip"]
        XCTAssertFalse(chipSetupContinue.isEnabled, "Continue should start disabled")
        XCTAssertFalse(addChipButton.isEnabled, "Add Chip should start disabled")

        let colorField = app.textFields["New Chip Color"]
        let priceField = app.textFields["New Chip Price"]
        colorField.tap()
        colorField.typeText("White")
        XCTAssertFalse(addChipButton.isEnabled, "Add Chip still disabled without a price")
        priceField.tap()
        priceField.typeText("0.05")
        app.staticTexts["Chip & Blind Setup"].tap()
        XCTAssertTrue(addChipButton.isEnabled)
        addChipButton.tap()

        XCTAssertFalse(chipSetupContinue.isEnabled, "Continue should stay disabled until blinds are set")

        let blindFields = app.textFields.matching(identifier: "Amount")
        blindFields.element(boundBy: 0).tap()
        blindFields.element(boundBy: 0).typeText("0.10")
        blindFields.element(boundBy: 1).tap()
        blindFields.element(boundBy: 1).typeText("0.25")
        app.staticTexts["Chip & Blind Setup"].tap()
        XCTAssertTrue(chipSetupContinue.isEnabled, "Continue should enable once at least one chip and blinds are set")

        chipSetupContinue.tap()
        XCTAssertTrue(app.navigationBars["Add Players"].waitForExistence(timeout: 5))

        let addPlayersContinue = app.buttons["Continue"]
        let addButton = app.buttons["Add Player"]
        XCTAssertFalse(addPlayersContinue.isEnabled, "Continue should start disabled with 0 players")
        XCTAssertFalse(addButton.isEnabled, "Add Player should start disabled")

        let nameField = app.textFields["Name"]
        let buyInField = app.textFields["New Player Buy-in"]
        nameField.tap()
        nameField.typeText("Gabe")
        XCTAssertFalse(addButton.isEnabled, "Add Player still disabled without a buy-in amount")
        buyInField.tap()
        buyInField.typeText("20")
        app.staticTexts["Add Players"].tap()
        XCTAssertTrue(addButton.isEnabled)
        addButton.tap()

        XCTAssertFalse(addPlayersContinue.isEnabled, "Continue should stay disabled with only 1 player")

        nameField.tap()
        nameField.typeText("Sam")
        buyInField.tap()
        buyInField.typeText("20")
        app.staticTexts["Add Players"].tap()
        addButton.tap()

        XCTAssertTrue(addPlayersContinue.isEnabled, "Continue should enable once 2 players are added")
    }

    @MainActor
    func testBuyInAmountIsEditableAfterAdding() throws {
        let app = launchApp()

        app.buttons["New Game"].tap()
        XCTAssertTrue(app.navigationBars["Chip & Blind Setup"].waitForExistence(timeout: 5))
        setUpChipsAndBlinds(app: app)
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.navigationBars["Add Players"].waitForExistence(timeout: 5))
        addPlayer(app: app, name: "Gabe", amount: "28") // typo -- meant to type 20
        addPlayer(app: app, name: "Sam", amount: "20")

        // Gabe was added first, so his row's field is index 0
        let rowBuyInField = app.textFields.matching(identifier: "Amount").element(boundBy: 0)
        XCTAssertEqual(rowBuyInField.value as? String, "28", "Row should reflect the mistyped amount")

        // Fix the typo directly in the row: double-tap selects the existing number, replacing it
        rowBuyInField.doubleTap()
        rowBuyInField.typeText("20")
        app.staticTexts["Add Players"].tap()

        app.buttons["Continue"].tap()
        XCTAssertTrue(app.navigationBars["Review"].waitForExistence(timeout: 5))

        XCTAssertTrue(app.staticTexts["Gabe"].waitForExistence(timeout: 5))
        // Both players should now show the corrected $20.00 buy-in
        XCTAssertEqual(app.staticTexts.matching(identifier: "$20.00").count, 2, "Corrected buy-in should carry through to Review")
        XCTAssertFalse(app.staticTexts["$28.00"].exists, "Original mistyped amount should be fully replaced")
    }

    @MainActor
    func testChipRowIsEditable() throws {
        let app = launchApp()

        app.buttons["New Game"].tap()
        XCTAssertTrue(app.navigationBars["Chip & Blind Setup"].waitForExistence(timeout: 5))

        let blindFields = app.textFields.matching(identifier: "Amount")
        blindFields.element(boundBy: 0).tap()
        blindFields.element(boundBy: 0).typeText("0.10")
        blindFields.element(boundBy: 1).tap()
        blindFields.element(boundBy: 1).typeText("0.25")
        app.staticTexts["Chip & Blind Setup"].tap()

        let newColorField = app.textFields["New Chip Color"]
        let newPriceField = app.textFields["New Chip Price"]
        newColorField.tap()
        newColorField.typeText("White")
        newPriceField.tap()
        newPriceField.typeText("0.05")
        app.staticTexts["Chip & Blind Setup"].tap()
        app.buttons["Add Chip"].tap()

        XCTAssertTrue(app.staticTexts["Chips (1)"].waitForExistence(timeout: 5))

        // Navigate forward (mounting Add Players' own @Query on ChipDenomination) and back,
        // to confirm editing still works safely once two screens observe the same data --
        // this is exactly the scenario that caused a text-duplication bug previously.
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.navigationBars["Add Players"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["BackButton"].tap()
        XCTAssertTrue(app.navigationBars["Chip & Blind Setup"].waitForExistence(timeout: 5))

        let rowColorField = app.textFields["Color"]
        let rowPriceField = app.textFields["Price"]
        XCTAssertEqual(rowColorField.value as? String, "White", "Existing entry should survive the round trip unchanged")
        XCTAssertEqual(rowPriceField.value as? String, "0.05")

        // Edit both fields directly in the row
        rowColorField.tap()
        rowColorField.typeText(" Chip")
        rowPriceField.tap()
        rowPriceField.typeText("5")
        app.staticTexts["Chip & Blind Setup"].tap()

        XCTAssertEqual(rowColorField.value as? String, "White Chip", "Editing the row should update the model, not duplicate it")
        // Price field is right-aligned, so a tap lands the cursor near the start of the short
        // existing text, not the end -- "5" + "0.05" = "50.05". The point here is just that the
        // edit landed exactly once (not duplicated), not the exact cursor position.
        XCTAssertEqual(rowPriceField.value as? String, "50.05")
    }

    @MainActor
    func testChipBreakdownIsEvenAcrossDenominations() throws {
        let app = launchApp()

        app.buttons["New Game"].tap()
        XCTAssertTrue(app.navigationBars["Chip & Blind Setup"].waitForExistence(timeout: 5))
        setUpChipsAndBlinds(app: app)
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.navigationBars["Add Players"].waitForExistence(timeout: 5))
        addPlayer(app: app, name: "Gabe", amount: "20")

        // Denominations: White .05, Red .10, Green .25, Blue .50, Black 1.00 (sum 1.90).
        // $20 / $1.90 = 10 complete sets ($19.00), +1 extra Black chip for the last $1.00 --
        // should read as an even 10-count across colors, not lopsided toward the biggest chip.
        XCTAssertTrue(
            app.staticTexts["11× Black, 10× Blue, 10× Green, 10× Red, 10× White"].waitForExistence(timeout: 5),
            "Chip breakdown should be an even count per denomination, topped off from the largest chip"
        )
    }

    @MainActor
    func testEditBuyInsOnTable() throws {
        let app = launchApp()

        app.buttons["New Game"].tap()
        XCTAssertTrue(app.navigationBars["Chip & Blind Setup"].waitForExistence(timeout: 5))
        setUpChipsAndBlinds(app: app)
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.navigationBars["Add Players"].waitForExistence(timeout: 5))
        addPlayer(app: app, name: "Gabe", amount: "20")
        addPlayer(app: app, name: "Sam", amount: "20")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.navigationBars["Review"].waitForExistence(timeout: 5))
        app.buttons["Start Game"].tap()
        XCTAssertTrue(app.navigationBars["Table"].waitForExistence(timeout: 5))

        // Give Gabe a rebuy so there are two buy-in events to edit
        app.staticTexts["Gabe"].tap()
        app.buttons["Add Rebuy"].tap()
        XCTAssertTrue(app.navigationBars["Add Rebuy"].waitForExistence(timeout: 5))
        let rebuyField = app.textFields["Amount"]
        rebuyField.tap()
        rebuyField.typeText("20")
        app.buttons["Add"].tap()
        XCTAssertTrue(app.staticTexts["$40.00"].waitForExistence(timeout: 5))

        // Open Edit Buy-ins
        app.staticTexts["Gabe"].tap()
        app.buttons["Edit Buy-ins"].tap()
        XCTAssertTrue(app.navigationBars["Edit Buy-ins"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Initial Buy-in"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Rebuy 1"].waitForExistence(timeout: 5))

        let buyInFields = app.textFields.matching(identifier: "Amount")
        XCTAssertEqual(buyInFields.count, 2)
        let initialField = buyInFields.element(boundBy: 0)
        XCTAssertEqual(initialField.value as? String, "20")

        // Fix a typo: correct the initial buy-in from 20 to 25
        initialField.doubleTap()
        initialField.typeText("25")
        app.staticTexts["Edit Buy-ins"].tap()
        app.buttons["Done"].tap()

        XCTAssertTrue(app.navigationBars["Table"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["$45.00"].waitForExistence(timeout: 5), "25 initial + 20 rebuy = 45")

        // Delete the rebuy entirely (e.g. it was added by mistake)
        app.staticTexts["Gabe"].tap()
        app.buttons["Edit Buy-ins"].tap()
        XCTAssertTrue(app.navigationBars["Edit Buy-ins"].waitForExistence(timeout: 5))
        app.staticTexts["Rebuy 1"].swipeLeft()
        app.buttons["Delete"].tap()
        app.buttons["Done"].tap()

        XCTAssertTrue(app.navigationBars["Table"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["$25.00"].waitForExistence(timeout: 5), "Rebuy removed, only the corrected initial buy-in remains")
    }

    @MainActor
    func testMidGameSettleUpAndStillPlayingBanner() throws {
        let app = launchApp()

        app.buttons["New Game"].tap()
        XCTAssertTrue(app.navigationBars["Chip & Blind Setup"].waitForExistence(timeout: 5))
        setUpChipsAndBlinds(app: app)
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.navigationBars["Add Players"].waitForExistence(timeout: 5))
        for (name, amount) in [("Gabe", "20"), ("Sam", "20"), ("Alex", "20")] {
            addPlayer(app: app, name: name, amount: amount)
        }
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.navigationBars["Review"].waitForExistence(timeout: 5))
        app.buttons["Start Game"].tap()
        XCTAssertTrue(app.navigationBars["Table"].waitForExistence(timeout: 5))

        // Gabe rebuys +20 (total buy-in now 40) while the game is live
        app.staticTexts["Gabe"].tap()
        app.buttons["Add Rebuy"].tap()
        XCTAssertTrue(app.navigationBars["Add Rebuy"].waitForExistence(timeout: 5))
        let rebuyField = app.textFields["Amount"]
        rebuyField.tap()
        rebuyField.typeText("20")
        app.buttons["Add"].tap()
        XCTAssertTrue(app.staticTexts["$40.00"].waitForExistence(timeout: 5), "Gabe's total should live-update to 40")
        XCTAssertTrue(app.staticTexts["+1 rebuy"].waitForExistence(timeout: 5))

        // Sam settles up mid-game while Gabe and Alex keep playing
        settleUp(app: app, playerName: "Sam", blackChipCount: "10")
        XCTAssertTrue(app.navigationBars["Table"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["-$10.00"].waitForExistence(timeout: 5), "Sam's final net should show on the table")

        // A settled seat should still be tappable, but offer view/edit instead of fresh actions
        app.staticTexts["Sam"].tap()
        XCTAssertFalse(app.buttons["Settle Up"].waitForExistence(timeout: 2), "Should not offer a fresh Settle Up")
        XCTAssertFalse(app.buttons["Add Rebuy"].waitForExistence(timeout: 2), "Should not offer Add Rebuy once cashed out")
        XCTAssertTrue(app.buttons["View / Edit Settle Up"].waitForExistence(timeout: 2))
        app.buttons["View / Edit Settle Up"].tap()

        XCTAssertTrue(app.navigationBars["Sam"].waitForExistence(timeout: 5))
        let countFields = app.textFields.matching(identifier: "0")
        let blackField = countFields.element(boundBy: 4) // White, Red, Green, Blue, Black
        XCTAssertEqual(blackField.value as? String, "10", "Previously entered chip count should be pre-filled")

        // Re-confirming without changes should not double-count the chips already on record
        app.buttons["Update Settle Up"].tap()
        XCTAssertTrue(app.navigationBars["Table"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["-$10.00"].waitForExistence(timeout: 5), "Net should stay -10, not double to 0 or +10")

        // End Game while 2 players are still active
        app.buttons["End Game"].tap()
        XCTAssertTrue(app.navigationBars["End Game"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["2 players still playing"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Still Playing"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Close Anyway"].waitForExistence(timeout: 5), "Should warn instead of offering a clean close")
        XCTAssertFalse(app.buttons["Close Session"].exists)
    }

    @MainActor
    func testFullHappyPathBalancedClose() throws {
        let app = launchApp()

        app.buttons["New Game"].tap()
        XCTAssertTrue(app.navigationBars["Chip & Blind Setup"].waitForExistence(timeout: 5))
        setUpChipsAndBlinds(app: app)
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.navigationBars["Add Players"].waitForExistence(timeout: 5))
        for (name, amount) in [("Gabe", "20"), ("Sam", "20")] {
            addPlayer(app: app, name: name, amount: amount)
        }
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.navigationBars["Review"].waitForExistence(timeout: 5))
        app.buttons["Start Game"].tap()
        XCTAssertTrue(app.navigationBars["Table"].waitForExistence(timeout: 5))

        // Gabe wins 10, Sam loses 10 -- zero-sum, should balance exactly
        settleUp(app: app, playerName: "Gabe", blackChipCount: "30")
        XCTAssertTrue(app.navigationBars["Table"].waitForExistence(timeout: 5))
        settleUp(app: app, playerName: "Sam", blackChipCount: "10")
        XCTAssertTrue(app.navigationBars["Table"].waitForExistence(timeout: 5))

        app.buttons["End Game"].tap()
        XCTAssertTrue(app.navigationBars["End Game"].waitForExistence(timeout: 5))

        XCTAssertTrue(app.staticTexts["$10.00"].waitForExistence(timeout: 5), "Gabe's net should be +10")
        XCTAssertTrue(app.staticTexts["-$10.00"].waitForExistence(timeout: 5), "Sam's net should be -10")
        XCTAssertTrue(app.staticTexts["$40.00"].waitForExistence(timeout: 5), "Total buy-ins/cash-outs should both be 40")
        XCTAssertTrue(app.buttons["Close Session"].waitForExistence(timeout: 5), "Should offer a clean close since everyone settled")
        XCTAssertFalse(app.buttons["Close Anyway"].exists)

        app.buttons["Close Session"].tap()

        XCTAssertTrue(app.buttons["New Game"].waitForExistence(timeout: 5), "Should return all the way to the Start screen")
        XCTAssertTrue(app.staticTexts["Home Game"].waitForExistence(timeout: 5))
    }
}
