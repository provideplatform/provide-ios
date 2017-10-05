//
//  DestinationInputViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/26/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import KTSwiftExtensions

protocol DestinationInputViewControllerDelegate: NSObjectProtocol {
    func destinationInputViewController(_ viewController: DestinationInputViewController,
                                        didSelectDestination destination: Contact,
                                        startingFrom origin: Contact)
}

class DestinationInputViewController: ViewController, UITextFieldDelegate, DestinationResultsViewControllerDelegate {

    weak var delegate: DestinationInputViewControllerDelegate!

    weak var destinationResultsViewController: DestinationResultsViewController! {
        didSet {
            if let _ = destinationResultsViewController {
                destinationResultsViewController.delegate = self
            }
        }
    }

    @IBOutlet fileprivate weak var originTextField: UITextField!
    @IBOutlet fileprivate weak var destinationTextField: UITextField!
    
    fileprivate var initialFrame: CGRect!
    fileprivate var initialDestinationTextFieldFrame: CGRect!
    fileprivate var initialDestinationResultsViewFrame: CGRect!
    fileprivate var initialDestinationResultsTableViewFrame: CGRect!
    
    fileprivate var timer: Timer!
    fileprivate var pendingSearch = false

    fileprivate var placemark: CLPlacemark! {
        didSet {
            if let placemark = placemark {
                if placemark.thoroughfare != nil && placemark.subThoroughfare != nil {
                    self.originTextField.text = "\(placemark.subThoroughfare!) \(placemark.thoroughfare!)"
                }
            } else {
                self.originTextField.text = ""
            }
        }
    }

    fileprivate var expanded = false {
        didSet {
            if expanded {
                initialFrame = view.frame
                initialDestinationTextFieldFrame = destinationTextField.frame
                initialDestinationResultsViewFrame = destinationResultsViewController?.view.frame
                initialDestinationResultsTableViewFrame = destinationResultsViewController?.view.subviews.first!.frame

                placemark = nil

                navigationController?.setNavigationBarHidden(true, animated: true)

                UIView.animate(withDuration: 0.25, animations: { [weak self] in
                    self!.view.frame.origin.y = 0.0
                    self!.view.frame.size.width = self!.view.superview!.frame.width
                    self!.view.backgroundColor = .white

                    self!.destinationTextField.frame.size.width = self!.view.frame.width
                    self!.destinationTextField.becomeFirstResponder()

                    self!.originTextField.frame.size.width = self!.view.frame.width
                    self!.originTextField.isHidden = false
                })

                UIView.animate(withDuration: 0.3, animations: { [weak self] in
                    self!.destinationResultsViewController.view.frame.origin.y = self!.view.frame.height
                    self!.destinationResultsViewController.view.frame.size.height = self!.view.superview!.frame.height - self!.view.frame.height
                    self!.destinationResultsViewController.view.subviews.first!.frame.size.height = self!.destinationResultsViewController.view.frame.size.height
                })
            } else {
                if destinationTextField.isFirstResponder {
                    destinationTextField.resignFirstResponder()
                }

                destinationTextField.text = ""
                originTextField.text = ""

                navigationController?.setNavigationBarHidden(false, animated: true)

                UIView.animate(withDuration: 0.25, animations: { [weak self] in
                    self!.view.frame = self!.initialFrame
                    self!.view.backgroundColor = .clear

                    self!.destinationResultsViewController.view.frame = self!.initialDestinationResultsViewFrame
                    self!.destinationResultsViewController.view.subviews.first!.frame = self!.initialDestinationResultsTableViewFrame
                })
            }
        }
    }

    @objc fileprivate func search() {
        if pendingSearch {
            logInfo("Places autocomplete search API request still pending; will execute when it returns")
            return
        }

        if let query = destinationTextField.text {
            timer?.invalidate()
            timer = nil

            pendingSearch = true
            LocationService.sharedService().resolveCurrentLocation(
                onResolved: { [weak self] location in
                    LocationService.sharedService().reverseGeocodeLocation(
                        location,
                        onResolved: { [weak self] placemark in
                            self?.placemark = placemark
                        }
                    )
                    let currentCoordinate = location.coordinate
                    let params = [
                        "q": query,
                        "latitude": currentCoordinate.latitude,
                        "longitude": currentCoordinate.longitude,
                        ] as [String : Any]
                    ApiService.sharedService().autocompletePlaces(
                        params as [String : AnyObject],
                        onSuccess: { [weak self] statusCode, mappingResult in
                            self!.pendingSearch = false
                            if let suggestions = mappingResult?.array() as? [Contact] {
                                logInfo("Retrieved \(suggestions.count) autocomplete suggestions for query string: \(query)")
                                self!.destinationResultsViewController.results = suggestions
                            } else {
                                logWarn("Failed to fetch possible destinations for query: \(query) (\(statusCode))")
                            }
                        },
                        onError: { [weak self] err, statusCode, responseString in
                            logWarn("Failed to fetch autocomplete suggestions for query: \(query) (\(statusCode))")
                            self!.pendingSearch = false
                        }
                    )
                }
            )

        }
    }
    
    // MARK: UITextFieldDelegate

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if !expanded {
            expanded = true
            return false
        }
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        destinationResultsViewController.results = [Contact]()
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

    @IBAction fileprivate func textFieldChanged(_ textField: UITextField) {
        // TODO: use a LIFO queue and remove anything that is still queued
        // to allow only a single API request on the wire at a time
        
        if textField.text == "" {
            timer?.invalidate()
            timer = nil

            pendingSearch = false
            destinationResultsViewController.results = [Contact]() // FIXME-- make sure a pending request race doesn't lose to this
            return
        }

        if !pendingSearch {
            search()
        } else if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 0.1,
                                         target: self,
                                         selector: #selector(search),
                                         userInfo: nil,
                                         repeats: true)

        }
    }

    // MARK: DestinationResultsViewControllerDelegate

    func destinationResultsViewController(_ viewController: DestinationResultsViewController, didSelectResult result: Contact) {
        expanded = false
        view.isHidden = true
        // TODO: switch on result contact type when additional sections are added to DestinationResultsViewController

        LocationService.sharedService().resolveCurrentLocation(
            onResolved: { [weak self] currentLocation in
                let origin = Contact()
                origin.latitude = currentLocation.coordinate.latitude as NSNumber
                origin.longitude = currentLocation.coordinate.longitude as NSNumber
                if let placemark = self?.placemark {
                    origin.merge(placemark: placemark)
                    self?.placemark = nil
                }
                self?.delegate?.destinationInputViewController(self!, didSelectDestination: result, startingFrom: origin)
            }
        )
    }
}