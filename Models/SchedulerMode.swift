//
//  SchedulerMode.swift
//  FlashForge
//
//  Created by bbdyno on 2/11/26.
//

import Foundation

enum SchedulerMode: String, CaseIterable, Codable, Sendable {
    case sm2 = "sm2"
    case fsrs = "fsrs"

    var title: String {
        "Adaptive Hybrid (Anki + FSRS)"
    }

    var shortLabel: String {
        "Hybrid"
    }
}
