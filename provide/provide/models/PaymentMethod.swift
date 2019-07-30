//
//  PaymentMethod.swift
//  provide
//
//  Created by Kyle Thomas on 9/15/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

@objcMembers
class PaymentMethod: Model {

    var id = 0
    var type: String!
    var brand: String!
    var cardNumber: String!
    var expMonth = -1
    var expYear = -1
    var cvc: String!
    var last4: String!
    var expired = false

    var icon: UIImage? {
        if let brand = brand {
            return UIImage(named: brand.lowercased())
        }
        return nil
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id",
            "brand",
            "card_number",
            "exp_month",
            "exp_year",
            "cvc",
            "last4",
            "expired",
            "type",
        ])
        return mapping!
    }
}

extension CardIOCreditCardInfo {
    func toPaymentMethod() -> PaymentMethod? {
        if let cardNumber = cardNumber {
            var redactedCardNumberWithSpaces = ""
            if cardNumber.length == 15 {
                redactedCardNumberWithSpaces = "•••• •••••• •\(cardNumber.suffix(4))" // 4-6-5
            } else if cardNumber.length == 16 {
                redactedCardNumberWithSpaces = "•••• •••• •••• \(cardNumber.suffix(4))" // 4-4-4-4
            }

            let paymentMethod = PaymentMethod()
            paymentMethod.type = "card"
            paymentMethod.last4 = redactedCardNumberWithSpaces
            paymentMethod.cardNumber = cardNumber
            paymentMethod.cvc = cvv
            paymentMethod.expMonth = Int(expiryMonth)
            paymentMethod.expYear = Int(expiryYear)

            switch cardType {
            case .amex:
                paymentMethod.brand = "amex"
            case .discover:
                paymentMethod.brand = "discover"
            case .mastercard:
                paymentMethod.brand = "mastercard"
            case .visa:
                paymentMethod.brand = "visa"
            default:
                logWarn("Payment method initialized with unsupported credit card type")
            }

            return paymentMethod
        }

        return nil
    }
}
