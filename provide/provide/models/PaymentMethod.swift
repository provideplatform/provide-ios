//
//  PaymentMethod.swift
//  provide
//
//  Created by Kyle Thomas on 9/15/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

enum PaymentCardBrands: String {
    case amex = "amex"
    case discover = "discover"
    case mastercard = "mastercard"
    case visa = "visa"
}

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

    var validCardNumber: Bool {
        if let cardNumber = cardNumber, let brand = brand, let type = type, type == "card", let cardBrand = PaymentCardBrands(rawValue: brand) {
            switch cardBrand {
            case .amex:
                return cardNumber.length == 15
            default:
                return cardNumber.length == 16
            }
        }
        return false
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

    func toCardIOCreditCardInfo() -> CardIOCreditCardInfo {
        let cardInfo = CardIOCreditCardInfo()
        cardInfo.cardNumber = cardNumber
        return cardInfo
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
