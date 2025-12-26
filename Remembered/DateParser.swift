import Foundation

struct DateParser {
    
    struct ParseResult {
        let date: Date?
        let title: String
        let type: String
    }
    
    private static let triggerWords: [String: [String]] = [
        "birthday": ["birthday", "bday"],
        "anniversary": ["anniversary"],
        "medical": ["surgery", "doctor", "appointment", "checkup"],
        "memorial": ["memorial", "death"]
    ]
    
    static func parse(_ input: String) -> ParseResult {
        let (foundDate, dateRange) = extractDate(from: input)
        
        var title = input
        if let range = dateRange {
            title.removeSubrange(range)
        }
        
        // Extract type and strip keywords
        var detectedType = "other"
        let lowerTitle = title.lowercased()
        
        for (type, keywords) in triggerWords {
            for keyword in keywords {
                if lowerTitle.contains(keyword) {
                    detectedType = type
                    
                    // Remove the keyword from the title
                    if let range = title.range(of: keyword, options: .caseInsensitive) {
                        title.removeSubrange(range)
                    }
                    break
                }
            }
        }
        
        // Remove common connecting words that might be left over
        let connectingWords = ["is", "was", "are", "were", "be", "been", "being", "on", "at", "in"]
        for word in connectingWords {
            // Use word boundaries to avoid removing parts of other words
            let pattern = "\\b\(word)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(title.startIndex..<title.endIndex, in: title)
                title = regex.stringByReplacingMatches(in: title, options: [], range: range, withTemplate: "")
            }
        }
        
        // Clean up whitespace - collapse multiple spaces and trim
        title = title.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If title is empty after removing date and keywords, fallback
        if title.isEmpty {
            // If we found a date but no words left, maybe use the original input's non-date parts
            // or just use the type name as the title if it's not "other"
            if detectedType != "other" {
                title = detectedType.capitalized
            } else {
                title = input.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return ParseResult(date: foundDate, title: title, type: detectedType)
    }
    
    private static func extractType(from input: String) -> String {
        let lower = input.lowercased()
        for (type, keywords) in triggerWords {
            for keyword in keywords {
                if lower.contains(keyword) { return type }
            }
        }
        return "other"
    }
    
    private static func extractDate(from input: String) -> (Date?, Range<String.Index>?) {
        // Use NSDataDetector for "Apple-magic" natural language date parsing
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return (nil, nil)
        }
        
        // We want the *first* date found, but we might prefer dates in the future?
        // For simple capture, just taking the first explicit date is standard.
        let nsRange = NSRange(input.startIndex..<input.endIndex, in: input)
        let matches = detector.matches(in: input, options: [], range: nsRange)
        
        if let match = matches.first, let parsedDate = match.date {
            var date = parsedDate
            
            // If the date is in the past or today (and specifically if no year was likely specified), 
            // we should shift it to next year for "Upcoming" logic.
            // Note: NSDataDetector usually defaults to the current year if not specified.
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let dateDay = calendar.startOfDay(for: date)
            
            if dateDay <= today {
                if let nextYear = calendar.date(byAdding: .year, value: 1, to: date) {
                    date = nextYear
                }
            }
            
            if let range = Range(match.range, in: input) {
                return (date, range)
            }
        }
        
        // Fallback: Simple slash/dash/dot format (e.g. 8/8, 1/18, 12-25, 9.9)
        let pattern = "\\b(?<month>\\d{1,2})[/.\\-](?<day>\\d{1,2})\\b"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
             let nsRange = NSRange(input.startIndex..<input.endIndex, in: input)
             if let match = regex.firstMatch(in: input, options: [], range: nsRange) {
                 if let monthRange = Range(match.range(withName: "month"), in: input),
                    let dayRange = Range(match.range(withName: "day"), in: input) {
                     
                     let month = Int(input[monthRange]) ?? 1
                     let day = Int(input[dayRange]) ?? 1
                     let currentYear = Calendar.current.component(.year, from: Date())
                     
                     var components = DateComponents()
                     components.year = currentYear
                     components.month = month
                     components.day = day
                     components.hour = 12
                     
                     let calendar = Calendar.current
                      if let date = calendar.date(from: components) {
                          var finalDate = date
                          // Future logic - shift to next year if date is today or in the past
                          let today = calendar.startOfDay(for: Date())
                          let dateDay = calendar.startOfDay(for: finalDate)
                          
                          if dateDay <= today {
                              if let nextYear = calendar.date(byAdding: .year, value: 1, to: finalDate) {
                                  finalDate = nextYear
                              }
                          }
                         
                         if let range = Range(match.range, in: input) {
                             return (finalDate, range)
                         }
                     }
                 }
             }
        }
        
        return (nil, nil)
    }    

}
