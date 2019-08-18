//
//  DestinationInputViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/26/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

class DestinationInputViewController: ViewController, UITextFieldDelegate {

    var hasFirstResponder: Bool {
        if let destinationTextField = destinationTextField {
            return destinationTextField.isFirstResponder
        }
        return false
    }

    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var destinationTextFieldTopConstraint: NSLayoutConstraint!

    private var timer: Timer?
    private var pendingSearch = false

    var placemark: CLPlacemark!

    private var destinationResultsViewController: DestinationResultsViewController {
        return (parent as! ConsumerViewController).destinationResultsViewController
    }

    private var expanded = false {
        didSet {
            if expanded {
                placemark = nil

                navigationController?.setNavigationBarHidden(true, animated: true)

                UIView.animate(withDuration: 0.25) {
                    self.destinationTextField.becomeFirstResponder()
                }
            } else {
                if destinationTextField.isFirstResponder {
                    destinationTextField.resignFirstResponder()
                }

                destinationTextField.text = ""

                navigationController?.setNavigationBarHidden(false, animated: true)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(true, animated: false)

        KTNotificationCenter.addObserver(forName: .ApplicationWillResignActive) { [weak self] notification in
            guard let strongSelf = self else { return }
            if strongSelf.expanded {
                strongSelf.expanded = false
            }
        }
    }

    @objc private func search() {
        if pendingSearch {
            logInfo("Places autocomplete search API request still pending; will execute when it returns")
            return
        }

        if let query = destinationTextField.text, let location = LocationService.shared.currentLocation {
            timer?.invalidate()
            timer = nil

            pendingSearch = true
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
            if LocationService.shared.currentLocation == nil {
                LocationService.shared.resolveCurrentLocation { [weak self] location in
                    self?.search()
                    LocationService.shared.background()
                }
            } else {
                search()
            }
        } else if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(search), userInfo: nil, repeats: true)
        }
    }
}
