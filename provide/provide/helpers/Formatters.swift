//
//  Formatters.swift
//  provide
//
//  Created by Jawwad Ahmad on 10/22/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit

class Formatters {
    static let currencyFormatter: NumberFormatter = {
        $0.numberStyle = .currency
        $0.minimumFractionDigits = 2
        return $0
    }(NumberFormatter())
}
