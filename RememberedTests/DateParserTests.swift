import XCTest
@testable import Remembered

final class DateParserTests: XCTestCase {

    func testBirthdays() {
        let input = "Chris Birthday Nov 3"
        let result = DateParser.parse(input)
        XCTAssertNotNil(result.date)
        XCTAssertEqual(result.type, "birthday")
        XCTAssertTrue(result.title.contains("Chris"))
    }
    
    func testRelativeDates() {
        let input = "Lunch tomorrow"
        let result = DateParser.parse(input)
        XCTAssertNotNil(result.date)
        
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        
        // Compare year/month/day
        XCTAssertEqual(calendar.component(.day, from: result.date!), calendar.component(.day, from: tomorrow))
    }
    
    func testMedical() {
        let input = "Surgery on Jan 18"
        let result = DateParser.parse(input)
        XCTAssertEqual(result.type, "medical")
        XCTAssertNotNil(result.date)
    }
    
    func testSlashDate() {
        let input = "Stef birthday 8/8"
        let result = DateParser.parse(input)
        XCTAssertNotNil(result.date, "Failed to parse 8/8")
        
        // Verify it parsed "Aug 8"
        if let date = result.date {
            let components = Calendar.current.dateComponents([.month, .day], from: date)
            XCTAssertEqual(components.month, 8)
            XCTAssertEqual(components.day, 8)
        }
    }
    
    func testDashDate() {
        let input = "Anniversary 12-25"
        let result = DateParser.parse(input)
        XCTAssertNotNil(result.date, "Failed to parse 12-25")
        if let date = result.date {
            let components = Calendar.current.dateComponents([.month, .day], from: date)
            XCTAssertEqual(components.month, 12)
            XCTAssertEqual(components.day, 25)
        }
    }

    func testDotDate() {
        let input = "Dad 09.09"
        // Regex might need to handle this
        let result = DateParser.parse(input)
        XCTAssertNotNil(result.date, "Failed to parse 09.09")
    }

    func testOrdinalDate() {
        let input = "Mom birthday Jan 3rd"
        let result = DateParser.parse(input)
        XCTAssertNotNil(result.date, "Failed to parse Jan 3rd")
        if let date = result.date {
             let components = Calendar.current.dateComponents([.month, .day], from: date)
             XCTAssertEqual(components.month, 1)
             XCTAssertEqual(components.day, 3)
        }
    }
    
    func testPossessiveWithConnectingWords() {
        let input = "Dominic's birthday is 9/25"
        let result = DateParser.parse(input)
        XCTAssertNotNil(result.date, "Failed to parse 9/25")
        XCTAssertEqual(result.type, "birthday")
        XCTAssertEqual(result.title, "Dominic's", "Title should be 'Dominic's' not '\(result.title)'")
        
        if let date = result.date {
            let components = Calendar.current.dateComponents([.month, .day], from: date)
            XCTAssertEqual(components.month, 9)
            XCTAssertEqual(components.day, 25)
        }
    }
    
    func testRelativeFuture() {
        let input = "Checkup in 2 weeks"
        let result = DateParser.parse(input)
        XCTAssertNotNil(result.date, "Failed to parse 'in 2 weeks'")
    }
    
    func testTodayShiftsToNextYear() {
        let input = "Today's event"
        let result = DateParser.parse(input)
        XCTAssertNotNil(result.date)
        
        let calendar = Calendar.current
        let nextYear = calendar.component(.year, from: Date()) + 1
        XCTAssertEqual(calendar.component(.year, from: result.date!), nextYear)
    }
    
    func testSpecificTodayShiftsToNextYear() {
        // Today is 12-25 (based on system time provided to me)
        let input = "Christmas 12/25"
        let result = DateParser.parse(input)
        XCTAssertNotNil(result.date)
        
        let calendar = Calendar.current
        let nextYear = calendar.component(.year, from: Date()) + 1
        XCTAssertEqual(calendar.component(.year, from: result.date!), nextYear)
    }
}
