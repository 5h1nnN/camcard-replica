import Foundation

enum BusinessCardFieldParser {
    static func parse(_ rawText: String) -> BusinessCardDraft {
        let lines = normalizedLines(in: rawText)
        guard !lines.isEmpty else { return .empty }

        let email = firstMatch(
            pattern: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#,
            in: rawText,
            options: [.caseInsensitive]
        )
        let website = firstMatch(
            pattern: #"(?:https?://|www\.)[A-Z0-9][A-Z0-9._~:/?#\[\]@!$&'()*+,;=%-]*"#,
            in: rawText,
            options: [.caseInsensitive]
        ).trimmingCharacters(in: CharacterSet(charactersIn: ".,;，；"))

        let phoneLines = lines.filter(isPhoneLine)
        let mobilePhone = phoneLines.first(where: isMobilePhoneLine) ?? phoneLines.first ?? ""
        let officePhone = phoneLines.first(where: { $0 != mobilePhone }) ?? ""
        let excluded = Set(
            [email, website, mobilePhone, officePhone]
                .filter { !$0.isEmpty }
                .flatMap { value in lines.filter { $0.localizedCaseInsensitiveContains(value) } }
        )
        let descriptiveLines = lines.filter { !excluded.contains($0) && !isContactOnlyLine($0) }

        let company = descriptiveLines.first(where: isCompanyLine) ?? ""
        let jobTitle = descriptiveLines.first(where: isJobTitleLine) ?? ""
        let address = descriptiveLines.first(where: isAddressLine) ?? ""
        let name = descriptiveLines.first(where: {
            $0 != company && $0 != jobTitle && $0 != address && isPlausibleName($0)
        }) ?? ""

        return BusinessCardDraft(
            ocrRawText: lines.joined(separator: "\n"),
            name: name,
            company: company,
            jobTitle: jobTitle,
            mobilePhone: cleanPhone(mobilePhone),
            officePhone: cleanPhone(officePhone),
            email: email,
            website: website,
            address: address,
            notes: ""
        )
    }

    static func normalizedLines(in rawText: String) -> [String] {
        var seen = Set<String>()
        return rawText
            .components(separatedBy: .newlines)
            .map { line in
                line.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    private static func firstMatch(
        pattern: String,
        in text: String,
        options: NSRegularExpression.Options = []
    ) -> String {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: options) else { return "" }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = expression.firstMatch(in: text, range: range),
              let swiftRange = Range(match.range, in: text) else { return "" }
        return String(text[swiftRange])
    }

    private static func isPhoneLine(_ line: String) -> Bool {
        if line.range(of: "@") != nil || line.range(of: #"(?:https?://|www\.)"#, options: [.regularExpression, .caseInsensitive]) != nil {
            return false
        }
        let digits = line.filter(\.isNumber).count
        guard (7...15).contains(digits) else { return false }
        if isAddressLine(line) && !containsAny(line, ["电话", "手机", "mobile", "tel", "phone"]) {
            return false
        }
        return line.range(of: #"(?<!\d)\+?[\d()\s-]{7,}(?!\d)"#, options: .regularExpression) != nil
    }

    private static func isMobilePhoneLine(_ line: String) -> Bool {
        containsAny(line, ["手机", "移动", "mobile", "cell"]) ||
            line.range(of: #"(?:\+?86[\s-]?)?1[3-9]\d(?:[\s-]?\d){8}"#, options: .regularExpression) != nil
    }

    private static func cleanPhone(_ line: String) -> String {
        guard !line.isEmpty else { return "" }
        let withoutLabel = line.replacingOccurrences(
            of: #"(?i)^\s*(?:手机|移动电话|电话|座机|mobile|cell|phone|tel|t)\s*[:：]?\s*"#,
            with: "",
            options: .regularExpression
        )
        return withoutLabel.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isCompanyLine(_ line: String) -> Bool {
        containsAny(line, [
            "公司", "集团", "工作室", "事务所", "科技", "大学", "学院",
            " inc", "inc.", " llc", "ltd", "studio", "company", "corporation", "university"
        ])
    }

    private static func isJobTitleLine(_ line: String) -> Bool {
        containsAny(line, [
            "经理", "总监", "设计师", "工程师", "顾问", "主管", "创始人", "教授",
            "founder", "director", "manager", "designer", "engineer", "consultant", "president", "professor", "ceo", "cto"
        ])
    }

    private static func isAddressLine(_ line: String) -> Bool {
        containsAny(line, [
            "地址", "省", "市", "区", "县", "路", "街", "道", "号", "室",
            "address", "street", " road", " avenue", " ave", " boulevard", " blvd", "suite", "room"
        ])
    }

    private static func isContactOnlyLine(_ line: String) -> Bool {
        containsAny(line, ["邮箱", "email", "网址", "website", "电话", "手机", "mobile", "phone", "tel"])
    }

    private static func isPlausibleName(_ line: String) -> Bool {
        let count = line.count
        guard (2...40).contains(count) else { return false }
        guard line.filter(\.isNumber).isEmpty else { return false }
        return !isCompanyLine(line) && !isJobTitleLine(line) && !isAddressLine(line)
    }

    private static func containsAny(_ text: String, _ needles: [String]) -> Bool {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return needles.contains { folded.contains($0.lowercased()) }
    }
}
