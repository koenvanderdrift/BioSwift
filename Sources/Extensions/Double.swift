//
//  Extensions.swift
//  BioSwift
//
//  Created by Koen van der Drift on 12/22/16.
//  Copyright © 2016 Koen van der Drift. All rights reserved.
//

import Foundation

extension Double {
//    public func roundTo(places: Int) -> Double {
//        let divisor = pow(10.0, Double(places))
//        return (self * divisor).rounded() / divisor
//    }
    
    // via: https://stackoverflow.com/questions/27338573/rounding-a-double-value-to-x-number-of-decimal-places-in-swift
    
    public func roundedDecimal(to scale: Int = 0, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var decimalValue = Decimal(self)
        var result = Decimal()
        NSDecimalRound(&result, &decimalValue, scale, mode)
        
        return result
    }
    
    public func roundedDecimalAsString(to scale: Int = 0, mode: NSDecimalNumber.RoundingMode = .plain) -> String {
        var decimalValue = roundedDecimal(to: scale, mode: mode)
        
        return NSDecimalString(&decimalValue, nil)
    }
    
    public func roundToDecimal(_ fractionDigits: Int) -> Double {
        let multiplier = pow(10, Double(fractionDigits))
        return Darwin.round(self * multiplier) / multiplier
    }
}
