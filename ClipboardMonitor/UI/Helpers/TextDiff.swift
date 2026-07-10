//
//  TextDiff.swift
//  ClipboardMonitor
//

import Foundation

/// Minimal line-oriented diff via LCS — enough for side-by-side compare without a library.
enum TextDiff {
    enum Line: Identifiable, Equatable {
        case unchanged(String)
        case added(String)
        case removed(String)

        var id: String {
            switch self {
            case .unchanged(let s): "u:\(s.hashValue)"
            case .added(let s): "a:\(s.hashValue)"
            case .removed(let s): "r:\(s.hashValue)"
            }
        }

        var text: String {
            switch self {
            case .unchanged(let s), .added(let s), .removed(let s): s
            }
        }
    }

    static func diff(lhs: String, rhs: String) -> [Line] {
        let a = lhs.components(separatedBy: "\n")
        let b = rhs.components(separatedBy: "\n")
        let table = lcsTable(a, b)
        return backtrack(a, b, table, a.count, b.count)
    }

    // MARK: - LCS

    private static func lcsTable(_ a: [String], _ b: [String]) -> [[Int]] {
        var table = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in 1...a.count {
            for j in 1...b.count {
                if a[i - 1] == b[j - 1] {
                    table[i][j] = table[i - 1][j - 1] + 1
                } else {
                    table[i][j] = max(table[i - 1][j], table[i][j - 1])
                }
            }
        }
        return table
    }

    private static func backtrack(
        _ a: [String],
        _ b: [String],
        _ table: [[Int]],
        _ i: Int,
        _ j: Int
    ) -> [Line] {
        if i > 0, j > 0, a[i - 1] == b[j - 1] {
            return backtrack(a, b, table, i - 1, j - 1) + [.unchanged(a[i - 1])]
        }
        if j > 0, (i == 0 || table[i][j - 1] >= table[i - 1][j]) {
            return backtrack(a, b, table, i, j - 1) + [.added(b[j - 1])]
        }
        if i > 0, (j == 0 || table[i][j - 1] < table[i - 1][j]) {
            return backtrack(a, b, table, i - 1, j) + [.removed(a[i - 1])]
        }
        return []
    }
}
