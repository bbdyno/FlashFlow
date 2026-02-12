//
//  CardTextSanitizer.swift
//  FlashForge
//
//  Created by bbdyno on 2/12/26.
//

import Foundation

enum CardTextSanitizer {
    static func normalizeMultiline(_ text: String) -> String {
        let unified = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = unified
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var leadingIndex = 0
        while leadingIndex < lines.count, lines[leadingIndex].isEmpty {
            leadingIndex += 1
        }

        guard leadingIndex < lines.count else {
            return ""
        }

        var trailingIndex = lines.count - 1
        while trailingIndex >= leadingIndex, lines[trailingIndex].isEmpty {
            trailingIndex -= 1
        }

        var result: [String] = []
        var previousWasEmpty = false

        for line in lines[leadingIndex...trailingIndex] {
            if line.isEmpty {
                if previousWasEmpty {
                    continue
                }
                result.append("")
                previousWasEmpty = true
            } else {
                result.append(line)
                previousWasEmpty = false
            }
        }

        return result.joined(separator: "\n")
    }

    static func normalizeSingleLine(_ text: String) -> String {
        let multiline = normalizeMultiline(text)
        guard !multiline.isEmpty else {
            return ""
        }

        return multiline
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    static func isLegacyNoNote(_ text: String) -> Bool {
        normalizeSingleLine(text).lowercased() == "no note"
    }

    static func previewLine(from text: String, emptyFallback: String) -> String {
        let normalized = normalizeMultiline(text)
        guard !normalized.isEmpty else {
            return emptyFallback
        }

        let lines = normalized.components(separatedBy: "\n")
        guard let firstLine = lines.first else {
            return emptyFallback
        }

        let additionalLineCount = max(0, lines.count - 1)
        guard additionalLineCount > 0 else {
            return firstLine
        }

        if additionalLineCount == 1 {
            return "\(firstLine) (+1 line)"
        }
        return "\(firstLine) (+\(additionalLineCount) lines)"
    }
}
