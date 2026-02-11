//
//  SchedulerMode.swift
//  FlashFlow
//
//  Created by bbdyno on 2/11/26.
//

import Foundation

enum SchedulerMode: String, CaseIterable, Codable, Sendable {
    case sm2 = "sm2"
    case fsrs = "fsrs"

    var title: String {
        switch self {
        case .sm2:
            return "SM-2 Hybrid"
        case .fsrs:
            return "FSRS Hybrid"
        }
    }

    var shortLabel: String {
        switch self {
        case .sm2:
            return "SM-2"
        case .fsrs:
            return "FSRS"
        }
    }
}
