//
//  PinInputViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/26/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol PinInputViewControllerDelegate {
    func pinInputViewControllerDidComplete(pinInputViewController: PinInputViewController)
    optional func pinInputViewControllerDidExceedMaxAttempts(pinInputViewController: PinInputViewController)
    optional func isInviteRedeptionPinInputViewController(pinInputViewController: PinInputViewController) -> Bool
    optional func pinInputViewController(pinInputViewController: PinInputViewController, shouldAttemptInviteRedemptionWithPin pin: String)
}


class PinInputViewController: UIViewController, PinInputControlDelegate {

    enum Type {
        case CreatePinController   // 1. create, 2. confirm creation
        case RedeemPinController // 1. redeem
        case UpdatePinController   // 2. match old, 2. change, 3. confirm change
        case ValidatePinController // 1. validate
    }

    enum State {
        case Input
        case ReInput
        case Validate
    }

    // MARK: Public Variables
    var delegate: PinInputViewControllerDelegate! {
        didSet {
            if let delegate = delegate {
                if let isInviteRedemption = delegate.isInviteRedeptionPinInputViewController?(self) {
                    if isInviteRedemption {
                        type = .RedeemPinController
                        state = .Input
                    }
                }
            }
        }
    }

    // MARK: Private Variables
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var pinInputControl: PinInputControl!

    private var state: State!
    private var type: Type!
    private var failedAttempts = 0
    private let maxAllowedAttempts = 3

    private let fadeStartDelay = 0.1
    private let fadeDuration = 0.3

    private var firstPinInput: String!

    override func awakeFromNib() {
        super.awakeFromNib()

        modalTransitionStyle = .CrossDissolve

        if KeyChainService.sharedService().pin == nil {
            type = .CreatePinController
            state = .Input
        } else {
            type = .ValidatePinController
            state = .Validate
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        precondition(delegate != nil, "delegate must be set")

        pinInputControl.delegate = self
        messageLabel.text = getMessage(type, state)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        messageLabel.text = getMessage(type, state)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        pinInputControl.becomeFirstResponder()
    }

    // MARK: PinInputControlDelegate

    func pinInputControl(pinInputControl: PinInputControl, didCompleteEnteringPin pin: String) {
        switch state! {
        case .Input:
            if type != .RedeemPinController {
                firstPinInput = pin
                state = .ReInput
                resetWithMessage(getMessage(type, state))
            } else {
                pinInputControl.resignFirstResponder()
                delegate?.pinInputViewController?(self, shouldAttemptInviteRedemptionWithPin: pin)
            }
        case .ReInput:
            if firstPinInput == pin { // both match
                KeyChainService.sharedService().pin = pin
                delegate.pinInputViewControllerDidComplete(self)
            } else {
                state = .Input
                resetWithMessage("Pins did not match. Please try again")
            }
        case .Validate:
            if KeyChainService.sharedService().pin != pin {
                resetWithMessage("Invalid Pin. Please try again")
                failedAttempts += 1
                if failedAttempts >= maxAllowedAttempts {
                    delegate.pinInputViewControllerDidExceedMaxAttempts?(self)
                }
            } else {
                dispatch_after_delay(self.fadeDuration) {
                    self.delegate.pinInputViewControllerDidComplete(self)
                }
            }
        }
    }

    private func resetWithMessage(message: String) {
        pinInputControl.resetView()

        dispatch_after_delay(fadeStartDelay) {
            UIView.animateWithDuration(self.fadeDuration, animations: {
                self.messageLabel.alpha = 0
                }) { _ in
                    UIView.animateWithDuration(self.fadeDuration) {
                        self.messageLabel.text = message
                        self.messageLabel.alpha = 1
                    }
            }
        }
    }

    private func getMessage(controllerType: Type, _ inputState: State) -> String {
        switch controllerType {
        case .CreatePinController:
            switch inputState {
            case .Input:   return "Create your 4 digit pin"
            case .ReInput: return "Confirm your 4 digit pin"
            default:       break // .Validate is not applicable since the new pin is not created yet
            }
        case .RedeemPinController:
            switch inputState {
            case .Input: return "Enter your pin"
            default:        break // .Input and .ReInput are not applicable
            }
        case .UpdatePinController:
            switch inputState {
            case .Validate: return "Enter your old pin"
            case .Input:    return "Enter your new pin"
            case .ReInput:  return "Confirm your new pin"
            }
        case .ValidatePinController:
            switch inputState {
            case .Validate: return "Enter your pin"
            default:        break // .Input and .ReInput are not applicable
            }
        }
        return "Enter pin" // should never happen!
    }

}
