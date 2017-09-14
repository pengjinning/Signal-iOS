//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

import XCTest

class FakeiPhone6JSQMessagesCollectionViewFlowLayout: JSQMessagesCollectionViewFlowLayout {
    // This value was nabbed by inspecting the super class layout.itemSize while debugging the `messageBubbleSizeForMessageData`. 
    // It requires the view to actually be rendered to get a proper size, so we're baking it in here.
    // This will break if we change the layout.
    override var itemWidth: CGFloat { return 367 }
}

/**
 * This is a brittle test, which will break if our layout changes. It serves mostly as documentation for cases to 
 * consider when changing the bubble size calculator. Primarly these test cases came out of a bug introduced in iOS10,
 * which prevents us from computing proper bounding box for text that uses the UIEmoji font.
 *
 * If one of these tests breaks, it should be OK to update the expected value so long as you've tested the result renders
 * correctly in the running app (the reference sizes were computed in the context of an iphone6 layout.
 * @see `FakeiPhone6JSQMessagesCollectionViewFlowLayout`
 */
class MesssagesBubblesSizeCalculatorTest: XCTestCase {

    let indexPath = IndexPath()
    let layout =  FakeiPhone6JSQMessagesCollectionViewFlowLayout()
    let calculator = MessagesBubblesSizeCalculator()
    let thread = TSContactThread()!
    let contactsManager = OWSContactsManager()

    func messageDataForForText(_ text: String?) -> JSQMessageData {
        let interaction = TSOutgoingMessage(timestamp: 0, in: thread, messageBody: text)
        interaction.save()
        return TSMessageAdapter.messageViewData(with: interaction, in: thread, contactsManager: self.contactsManager)
    }

    func testHeightForNilMessage() {
        let text: String? = nil
        let messageData = self.messageDataForForText(text)
        let actual = calculator.messageBubbleSize(for: messageData, at: indexPath, with: layout)
        XCTAssertEqual(37, actual.height)
    }

    func testHeightForShort1LineMessage() {
        let text = "foo"
        let messageData = self.messageDataForForText(text)
        let actual = calculator.messageBubbleSize(for: messageData, at: indexPath, with: layout)
        XCTAssertEqual(38, actual.height)
    }

    func testHeightForLong1LineMessage() {
        let text = "1 2 3 4 5 6 7 8 9 10 11 12 13 14 x"
        let messageData = self.messageDataForForText(text)
        let actual = calculator.messageBubbleSize(for: messageData, at: indexPath, with: layout)
        XCTAssertEqual(38, actual.height)
    }

    func testHeightForShort2LineMessage() {
        let text = "1 2 3 4 5 6 7 8 9 10 11 12 13 14 x 1"
        let messageData = self.messageDataForForText(text)
        let actual = calculator.messageBubbleSize(for: messageData, at: indexPath, with: layout)
        XCTAssertEqual(59, actual.height)
    }

    func testHeightForLong2LineMessage() {
        let text = "1 2 3 4 5 6 7 8 9 10 11 12 13 14 x 1 2 3 4 5 6 7 8 9 10 11 12 13 14 x"
        let messageData = self.messageDataForForText(text)
        let actual = calculator.messageBubbleSize(for: messageData, at: indexPath, with: layout)
        XCTAssertEqual(59, actual.height)
    }

    func testHeightForiOS10EmojiBug() {
        let messageData = self.messageDataForForText("Wunderschönen Guten Morgaaaahhhn 😝 - hast du gut geschlafen ☺️😘")
        let actual = calculator.messageBubbleSize(for: messageData, at: indexPath, with: layout)

        XCTAssertEqual(85.5, actual.height)
    }

    func testHeightForiOS10EmojiBug2() {
        let messageData = self.messageDataForForText("Test test test test test test test test test test test test 😊❤️❤️")
        let actual = calculator.messageBubbleSize(for: messageData, at: indexPath, with: layout)

        XCTAssertEqual(62, actual.height)
    }

    func testHeightForChineseWithEmojiBug() {
        let messageData = self.messageDataForForText("一二三四五六七八九十甲乙丙😝戊己庚辛壬圭咖啡牛奶餅乾水果蛋糕")
        let actual = calculator.messageBubbleSize(for: messageData, at: indexPath, with: layout)
        // erroneously seeing 69 with the emoji fix in place.
        XCTAssertEqual(85.5, actual.height)
    }

    func testHeightForChineseWithoutEmojiBug() {
        let messageData = self.messageDataForForText("一二三四五六七八九十甲乙丙丁戊己庚辛壬圭咖啡牛奶餅乾水果蛋糕")
        let actual = calculator.messageBubbleSize(for: messageData, at: indexPath, with: layout)
        // erroneously seeing 69 with the emoji fix in place.
        XCTAssertEqual(81, actual.height)
    }

    func testHeightForiOS10DoubleSpaceNumbersBug() {
        let messageData = self.messageDataForForText("１２３４５６７８９０１２３４５６７８９０")
        let actual = calculator.messageBubbleSize(for: messageData, at: indexPath, with: layout)
        // erroneously seeing 51 with emoji fix in place. It's the call to "fix string"
        XCTAssertEqual(59, actual.height)
    }

}
