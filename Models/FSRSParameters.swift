//
//  FSRSParameters.swift
//  FlashForge
//
//  Created by bbdyno on 2/11/26.
//

import Foundation

struct FSRSParameters: Sendable, Codable {
    let w: [Double]
    let requestRetention: Double

    init(
        w: [Double] = [0.4, 0.6, 2.4, 5.8, 4.93, 0.94, 0.86, 0.01, 1.49, 0.14, 0.94, 2.18, 0.05, 0.34, 1.26, 0.29, 2.61],
        requestRetention: Double = 0.9
    ) {
        self.w = w
        self.requestRetention = requestRetention
    }
}

extension FSRSParameters {
    static let `default` = FSRSParameters()
}
