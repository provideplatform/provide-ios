//
//  TripCompletionViewController.swift
//  provide
//
//  Created by Jawwad Ahmad on 10/21/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit

class TripCompletionViewController: UIViewController {

    func configure(driver: Provider, onConfirmTapped: @escaping (Int) -> Void) {
        self.driver = driver
        self.onConfirmTapped = onConfirmTapped
    }

    private var driver: Provider!
    private var onConfirmTapped: ((Int) -> Void)!

    private var selectedButton: UIButton?

    @IBOutlet private var tipButtons: [CircleButton]!
    @IBOutlet private weak var driverImageView: UIImageView!
    @IBOutlet private weak var driverNameLabel: UILabel!
    @IBOutlet private weak var customAmountButton: UIButton!

    @IBAction private func anyButtonTapped(_ sender: UIButton) {
        selectedButton?.isSelected = false
        sender.isSelected = true
        selectedButton = sender
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        driverNameLabel.text = "Add a tip for \(driver.name ?? "Unknown")"
        driverImageView.sd_setImage(with: driver.profileImageUrl)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        monkey("👨‍💼 Tap: Tip Button") {
            self.anyButtonTapped(self.tipButtons.last!)

            monkey("👨‍💼 Tap: CONFIRM") {
                self.confirmButtonTapped(nil)
            }
        }
    }

    @IBAction private func customButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Tip", message: "Enter an amount", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Dollars"
            textField.clearButtonMode = .whileEditing
            textField.borderStyle = .none
            textField.keyboardType = .numberPad
            textField.delegate = self
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            alertController.dismiss(animated: true, completion: nil)
        })

        alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            let text = alertController.textFields?.first?.text
            sender.setTitle("$\(text!)", for: .normal)
            alertController.dismiss(animated: true, completion: nil)
        })

        present(alertController, animated: true, completion: nil)
    }

    @IBAction private func confirmButtonTapped(_: UIButton?) {
        let tipAmount = selectedButton?.titleLabel?.text?.replacingOccurrences(of: "$", with: "") ?? "0"
        onConfirmTapped?(Int(tipAmount) ?? 0)
        dismiss(animated: true)
    }
}

extension TripCompletionViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)
        return (Int(updatedText) != nil && updatedText.characters.count <= 3) || updatedText.isEmpty
    }
}


class CircleButton: UIButton {

    override func awakeFromNib() {
        super.awakeFromNib()

        layer.cornerRadius = bounds.height / 2
        layer.borderWidth = 2
        layer.borderColor = UIColor.lightGray.cgColor
        backgroundColor = .white
    }

    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? #colorLiteral(red: 0.2266602516, green: 0.5155033469, blue: 0.9490318894, alpha: 1) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        }
    }
}
