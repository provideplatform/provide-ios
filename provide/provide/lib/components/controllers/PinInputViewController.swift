//
//  PinInputViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/26/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol PinInputViewControllerDelegate {
    func pinInputViewControllerDidComplete(_ pinInputViewController: PinInputViewController)
    @objc optional func pinInputViewControllerDidExceedMaxAttempts(_ pinInputViewController: PinInputViewController)
    @objc optional func isInviteRedeptionPinInputViewController(_ pinInputViewController: PinInputViewController) -> Bool
    @objc optional func pinInputViewController(_ pinInputViewController: PinInputViewController, shouldAttemptInviteRedemptionWithPin pin: String)
}

class PinInputViewController: UIViewController, PinInputControlDelegate {

    enum `Type` {
        case createPinController    // 1. create, 2. confirm creation
        case redeemPinController    // 1. redeem
        case updatePinController    // 2. match old, 2. change, 3. confirm change
        case validatePinController  // 1. validate
    }

    enum State {
        case input
        case reInput
        case validate
    }

    // MARK: Public Variables

    var delegate: PinInputViewControllerDelegate! {
        didSet {
            if let isInviteRedemption = delegate?.isInviteRedeptionPinInputViewController?(self), isInviteRedemption == true {
                type = .redeemPinController
                state = .input
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

        modalTransitionStyle = .crossDissolve

        if KeyChainService.shared.pin == nil {
            type = .createPinController
            state = .input
        } else {
            type = .validatePinController
            state = .validate
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        precondition(delegate != nil, "delegate must be set")

        pinInputControl.delegate = self
        messageLabel.text = getMessage(type, state)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        messageLabel.text = getMessage(type, state)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        pinInputControl.becomeFirstResponder()
    }

    // MARK: PinInputControlDelegate

    func pinInputControl(_ pinInputControl: PinInputControl, didCompleteEnteringPin pin: String) {
        switch state! {
        case .input:
            if type != .redeemPinController {
                firstPinInput = pin
                state = .reInput
                resetWithMessage(getMessage(type, state))
            } else {
                pinInputControl.resignFirstResponder()
                delegate?.pinInputViewController?(self, shouldAttemptInviteRedemptionWithPin: pin)
            }
        case .reInput:
            if firstPinInput == pin { // both match
                KeyChainService.shared.pin = pin
                delegate.pinInputViewControllerDidComplete(self)
            } else {
                state = .input
                resetWithMessage("Pins did not match. Please try again")
            }
        case .validate:
            if KeyChainService.shared.pin != pin {
                resetWithMessage("Invalid Pin. Please try again")
                failedAttempts += 1
                if failedAttempts >= maxAllowedAttempts {
                    delegate.pinInputViewControllerDidExceedMaxAttempts?(self)
                }
            } else {
                dispatch_after_delay(fadeDuration) {
                    self.delegate.pinInputViewControllerDidComplete(self)
                }
            }
        }
    }

    private func resetWithMessage(_ message: String) {
        pinInputControl.resetView()

        dispatch_after_delay(fadeStartDelay) {
            UIView.animate(withDuration: self.fadeDuration, animations: {
                self.messageLabel.alpha = 0
            }, completion: { _ in
                UIView.animate(withDuration: self.fadeDuration) {
                    self.messageLabel.text = message
                    self.messageLabel.alpha = 1
                }
            })
        }
    }

    private func getMessage(_ controllerType: Type, _ inputState: State) -> String {
        switch controllerType {
        case .createPinController:
            switch inputState {
            case .input:   return "Create your 4 digit pin"
            case .reInput: return "Confirm your 4 digit pin"
            default:       break // .Validate is not applicable since the new pin is not created yet
            }
        case .redeemPinController:
            switch inputState {
            case .input: return "Enter your pin"
            default:        break // .Input and .ReInput are not applicable
            }
        case .updatePinController:
            switch inputState {
            case .validate: return "Enter your old pin"
            case .input:    return "Enter your new pin"
            case .reInput:  return "Confirm your new pin"
            }
        case .validatePinController:
            switch inputState {
            case .validate: return "Enter your pin"
            default:        break // .Input and .ReInput are not applicable
            }
        }
        return "Enter pin" // should never happen!
    }
}
