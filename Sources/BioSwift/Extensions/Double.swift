//
//  Double.swift
//  BioSwift
//
//  Created by Koen van der Drift on 12/22/16.
//  Copyright © 2016 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

extension Double {
    /// Returns a localized display string with a fixed number of fractional digits.
    public func formatted(fractionDigits: Int, locale: Locale = .current) -> String {
        precondition(fractionDigits >= 0, "fractionDigits must be non-negative")

        return self.formatted(.number.precision(.fractionLength(fractionDigits)).locale(locale))
    }

    /// Rounds the Double numerically to the requested number of fractional digits.
    ///
    /// Appropriate for approximate floating-point calculations and UI geometry.
    /// For exact base-10 rounding, use Decimal instead.
    public func rounded(
        fractionDigits: Int, rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero
    ) -> Double {
        precondition(fractionDigits >= 0, "fractionDigits must be non-negative")

        guard isFinite else {
            return self
        }

        let multiplier = pow(10.0, Double(fractionDigits))
        let scaledValue = self * multiplier

        guard multiplier.isFinite, scaledValue.isFinite else {
            return self
        }

        return scaledValue.rounded(rule) / multiplier
    }

}
