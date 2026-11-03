import Foundation

enum BusinessCardFieldParser {
    nonisolated static func parse(_ rawText: String) -> BusinessCardDraft {
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
        let faxPhone = phoneLines.first(where: isFaxPhoneLine) ?? ""
        let mobilePhone = phoneLines.first(where: isMobilePhoneLine)
            ?? phoneLines.first(where: { !isFaxPhoneLine($0) && !isOfficePhoneLine($0) })
            ?? phoneLines.first(where: { !isFaxPhoneLine($0) })
            ?? ""
        let officePhone = phoneLines.first(where: {
            $0 != mobilePhone && $0 != faxPhone && isOfficePhoneLine($0)
        }) ?? phoneLines.first(where: { $0 != mobilePhone && $0 != faxPhone }) ?? ""
        let excluded = Set(
            [email, website, mobilePhone, officePhone, faxPhone]
                .filter { !$0.isEmpty }
                .flatMap { value in lines.filter { $0.localizedCaseInsensitiveContains(value) } }
        )
        let descriptiveLines = lines.filter { !excluded.contains($0) && !isContactOnlyLine($0) }

        let addressLine = descriptiveLines.first(where: isAddressLine) ?? ""
        let jobTitle = descriptiveLines.first(where: { $0 != addressLine && isJobTitleLine($0) }) ?? ""
        let recognizedCompany = descriptiveLines.first(where: {
            $0 != addressLine && $0 != jobTitle && isCompanyLine($0)
        }) ?? ""
        let nameLine = descriptiveLines.first(where: {
            $0 != recognizedCompany && $0 != jobTitle && $0 != addressLine && isPlausibleName($0)
        }) ?? ""
        let name = mergedBilingualName(
            startingWith: nameLine,
            in: descriptiveLines,
            excluding: [recognizedCompany, jobTitle, addressLine]
        )
        let company = recognizedCompany.isEmpty
            ? descriptiveLines.first(where: {
                !name.contains($0) && $0 != jobTitle && $0 != addressLine && isPlausibleCompanyFallback($0)
            }) ?? ""
            : recognizedCompany
        let address = stripKnownLabel(
            addressLine,
            labels: ["地址", "address", "street address", "office address"]
        )

        return BusinessCardDraft(
            ocrRawText: lines.joined(separator: "\n"),
            name: name,
            company: company,
            jobTitle: jobTitle,
            mobilePhone: cleanPhone(mobilePhone),
            officePhone: cleanPhone(officePhone),
            faxPhone: cleanPhone(faxPhone),
            email: email,
            website: website,
            address: address,
            notes: ""
        )
    }

    nonisolated static func normalizedLines(in rawText: String) -> [String] {
        var seen = Set<String>()
        return rawText
            .components(separatedBy: .newlines)
            .map { line in
                line.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    nonisolated private static func firstMatch(
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

    nonisolated private static func isPhoneLine(_ line: String) -> Bool {
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

    nonisolated private static func isMobilePhoneLine(_ line: String) -> Bool {
        containsAny(line, ["手机", "移动", "mobile", "cell"]) ||
            line.range(of: #"(?:\+?86[\s-]?)?1[3-9]\d(?:[\s-]?\d){8}"#, options: .regularExpression) != nil
    }

    nonisolated private static func isOfficePhoneLine(_ line: String) -> Bool {
        containsAny(line, ["座机", "办公", "office", "work", "direct", "电话", "phone", "tel"])
            && !isMobilePhoneLine(line)
            && !isFaxPhoneLine(line)
    }

    nonisolated private static func isFaxPhoneLine(_ line: String) -> Bool {
        containsAny(line, ["传真", "fax"])
    }

    nonisolated private static func cleanPhone(_ line: String) -> String {
        guard !line.isEmpty else { return "" }
        let strippedBilingualLabel = stripKnownLabel(
            line,
            labels: [
                "手机", "移动电话", "电话", "座机", "办公电话", "传真",
                "mobile", "mobile phone", "cell", "cell phone", "office",
                "office phone", "work", "work phone", "phone", "telephone", "tel", "fax"
            ]
        )
        let withoutLabel = strippedBilingualLabel.replacingOccurrences(
            of: #"(?i)^\s*(?:手机|移动电话|电话|座机|办公电话|传真|mobile(?:\s+phone)?|cell(?:\s+phone)?|office(?:\s+phone)?|work(?:\s+phone)?|phone|tel(?:ephone)?|fax|t|f)\s*[:：]?\s*"#,
            with: "",
            options: .regularExpression
        )
        return withoutLabel.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func isCompanyLine(_ line: String) -> Bool {
        containsAny(line, [
            "公司", "集团", "工作室", "事务所", "科技", "大学", "学院", "实验室", "研究所", "中心", "咨询",
            " inc", "inc.", " llc", "ltd", "studio", "company", "corporation", "university",
            "lab", "labs", "works", "consulting", "ventures", "systems", "design", "mobile",
            "network", "networks", "center", "centre", "agency", "solutions"
        ])
    }

    nonisolated private static func isJobTitleLine(_ line: String) -> Bool {
        containsAny(line, [
            "经理", "总监", "设计师", "工程师", "顾问", "主管", "创始人", "教授", "研究员", "分析师", "开发",
            "founder", "director", "manager", "designer", "engineer", "consultant", "president", "professor",
            "analyst", "advisor", "lead", "researcher", "developer", "account", "technical", "ceo", "cto"
        ])
    }

    nonisolated private static func isAddressLine(_ line: String) -> Bool {
        containsAny(line, [
            "地址", "省", "市", "区", "县", "路", "街", "道", "号",
            "address", "street", " road", " avenue", " ave", " boulevard", " blvd", "suite", "room"
        ])
    }

    nonisolated private static func isContactOnlyLine(_ line: String) -> Bool {
        if containsAny(line, ["邮箱", "email", "网址", "website", "web:", "web："]) {
            return true
        }
        let digitCount = line.filter(\.isNumber).count
        return digitCount >= 5 && containsAny(
            line,
            ["电话", "手机", "传真", "mobile", "phone", "office", "work", "tel", "fax"]
        )
    }

    nonisolated private static func mergedBilingualName(
        startingWith firstLine: String,
        in lines: [String],
        excluding excludedLines: [String]
    ) -> String {
        guard !firstLine.isEmpty,
              let firstIndex = lines.firstIndex(of: firstLine),
              firstIndex + 1 < lines.count else { return firstLine }
        let nextLine = lines[firstIndex + 1]
        guard !excludedLines.contains(nextLine),
              isPlausibleName(nextLine),
              firstLine.count <= 30,
              nextLine.count <= 12,
              usesLatinLetters(firstLine) != usesLatinLetters(nextLine) else { return firstLine }
        return "\(firstLine) \(nextLine)"
    }

    nonisolated private static func usesLatinLetters(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (65...90).contains(scalar.value) || (97...122).contains(scalar.value)
        }
    }

    nonisolated private static func isPlausibleName(_ line: String) -> Bool {
        let count = line.count
        guard (2...40).contains(count) else { return false }
        guard asciiDigitCount(in: line) == 0 else { return false }
        return !isCompanyLine(line) && !isJobTitleLine(line) && !isAddressLine(line)
    }

    nonisolated private static func isPlausibleCompanyFallback(_ line: String) -> Bool {
        let count = line.count
        return (2...60).contains(count)
            && asciiDigitCount(in: line) < 3
            && !isJobTitleLine(line)
            && !isAddressLine(line)
            && !isContactOnlyLine(line)
    }

    nonisolated private static func asciiDigitCount(in text: String) -> Int {
        text.unicodeScalars.count { (48...57).contains($0.value) }
    }

    nonisolated private static func stripKnownLabel(_ line: String, labels: [String]) -> String {
        guard let separator = line.firstIndex(where: { $0 == ":" || $0 == "：" }) else {
            return line.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let prefix = String(line[..<separator])
        guard containsAny(prefix, labels) else {
            return line.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return String(line[line.index(after: separator)...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func containsAny(_ text: String, _ needles: [String]) -> Bool {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return needles.contains { folded.contains($0.lowercased()) }
    }
}
