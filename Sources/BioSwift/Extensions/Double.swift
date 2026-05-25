//
//  Double.swift
//  BioSwift
//
//  Created by Koen van der Drift on 12/22/16.
//  Copyright © 2016 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public extension Double {
    /// Returns a localized display string with a fixed number of fractional digits.
    func formatted(
        fractionDigits: Int,
        locale: Locale = .current
    ) -> String {
        precondition(fractionDigits >= 0, "fractionDigits must be non-negative")

        return self.formatted(
            .number
                .precision(.fractionLength(fractionDigits))
                .locale(locale)
        )
    }

    /// Rounds the Double numerically to the requested number of fractional digits.
    ///
    /// Appropriate for approximate floating-point calculations and UI geometry.
    /// For exact base-10 rounding, use Decimal instead.
    func rounded(
        fractionDigits: Int,
        rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero
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

    /// Converts the Double to Decimal and then applies decimal rounding.
    ///
    /// This controls the rounding step, but cannot restore precision already
    /// lost when the original value was represented as a Double.
    func roundedDecimal(
        scale: Int = 0,
        mode: NSDecimalNumber.RoundingMode = .plain
    ) -> Decimal {
        precondition(scale >= 0, "scale must be non-negative")

        return Decimal(self).rounded(scale: scale, mode: mode)
    }

    /// Converts the Double to Decimal, applies decimal rounding,
    /// and formats the result for display.
    func formattedDecimal(
        scale: Int = 0,
        mode: NSDecimalNumber.RoundingMode = .plain,
        locale: Locale = .current
    ) -> String {
        precondition(scale >= 0, "scale must be non-negative")

        return roundedDecimal(scale: scale, mode: mode)
            .formatted(
                .number
                    .precision(.fractionLength(scale))
                    .locale(locale)
            )
    }
}
