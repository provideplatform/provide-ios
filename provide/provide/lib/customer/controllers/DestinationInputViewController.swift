//
//  DestinationInputViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/26/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

class DestinationInputViewController: ViewController, UITextFieldDelegate {

    weak var destinationResultsViewController: DestinationResultsViewController!

    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var destinationTextFieldTopConstraint: NSLayoutConstraint!

    private var initialDestinationResultsViewFrame: CGRect!

    private var timer: Timer!
    private var pendingSearch = false

    var placemark: CLPlacemark!

    private var expanded = false {
        didSet {
            if expanded {
                initialDestinationResultsViewFrame = destinationResultsViewController?.view.frame

                placemark = nil

                navigationController?.setNavigationBarHidden(true, animated: true)

                UIView.animate(withDuration: 0.25) {
                    self.destinationTextField.becomeFirstResponder()
                }

                UIView.animate(withDuration: 0.3) {
                    self.destinationResultsViewController.view.frame.origin.y = self.view.height
                    self.destinationResultsViewController.view.frame.size.height = self.parent!.view.height - self.view.height
                }
            } else {
                if destinationTextField.isFirstResponder {
                    destinationTextField.resignFirstResponder()
                }

                destinationTextField.text = ""

                navigationController?.setNavigationBarHidden(false, animated: true)

                UIView.animate(withDuration: 0.25) {
                    self.destinationResultsViewController.view.frame = self.initialDestinationResultsViewFrame
                }
            }
        }
    }

    @objc private func search() {
        if pendingSearch {
            logInfo("Places autocomplete search API request still pending; will execute when it returns")
            return
        }

        if let query = destinationTextField.text {
            timer?.invalidate()
            timer = nil

            pendingSearch = true
            LocationService.shared.resolveCurrentLocation { [weak self] location in
                LocationService.shared.reverseGeocodeLocation(location) { [weak self] placemark in
                    self?.placemark = placemark
                }
                let currentCoordinate = location.coordinate
                let params: [String: Any] = [
                    "q": query,
                    "latitude": currentCoordinate.latitude,
                    "longitude": currentCoordinate.longitude,
                ]
                ApiService.shared.autocompletePlaces(params, onSuccess: { [weak self] statusCode, mappingResult in
                    self?.pendingSearch = false
                    if let suggestions = mappingResult?.array() as? [Contact] {
                        logInfo("Retrieved \(suggestions.count) autocomplete suggestions for query string: \(query)")
                        self?.destinationResultsViewController.updateResults(suggestions)
                    } else {
                        logWarn("Failed to fetch possible destinations for query: \(query) (\(statusCode))")
                    }
                }, onError: { [weak self] err, statusCode, responseString in
                    logWarn("Failed to fetch autocomplete suggestions for query: \(query) (\(statusCode))")
                    self?.pendingSearch = false
                })

                LocationService.shared.background()
            }
        }
    }

    func collapseAndHide() {
        expanded = false
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if !expanded {
            expanded = true

            logmoji("👱", "Activated: search field")

            monkey("👨‍💼 Input: destination address") {
                self.destinationTextField.text = "888 N Quincy St"
                self.search()
            }

            return false
        }
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        destinationResultsViewController.updateResults([])
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if expanded {
            if textField.isFirstResponder {
                textField.resignFirstResponder()
            }
            search()
            return true
        }
        return false
    }

    @IBAction private func textFieldChanged(_ textField: UITextField) {
        // TODO: use a LIFO queue and remove anything that is still queued
        // to allow only a single API request on the wire at a time

        if textField.text == "" {
            timer?.invalidate()
            timer = nil

            pendingSearch = false
            destinationResultsViewController.updateResults([]) // FIXME-- make sure a pending request race doesn't lose to this
            return
        }

        if !pendingSearch {
            search()
        } else if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(search), userInfo: nil, repeats: true)
        }
    }
}
