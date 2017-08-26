//
//  DestinationInputViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/26/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import KTSwiftExtensions

class DestinationInputViewController: ViewController, UITextFieldDelegate {

    weak var destinationResultsViewController: DestinationResultsViewController!

    @IBOutlet fileprivate weak var destinationTextField: UITextField!
    
    fileprivate var initialFrame: CGRect!
    fileprivate var initialDestinationTextFieldFrame: CGRect!
    fileprivate var initialDestinationResultsViewFrame: CGRect!
    fileprivate var initialDestinationResultsTableViewFrame: CGRect!
    
    fileprivate var timer: Timer!
    fileprivate var pendingSearch = false

    fileprivate var expanded = false {
        didSet {
            if expanded {
                initialFrame = view.frame
                initialDestinationTextFieldFrame = destinationTextField.frame
                initialDestinationResultsViewFrame = destinationResultsViewController?.view.frame
                initialDestinationResultsTableViewFrame = destinationResultsViewController?.view.subviews.first!.frame

                navigationController?.setNavigationBarHidden(true, animated: true)
                
                UIView.animate(withDuration: 0.25, animations: { [weak self] in
                    self!.view.frame.origin.y = 0.0
                    self!.view.frame.size.width = self!.view.superview!.frame.width
                    self!.view.backgroundColor = .white
                    
                    self!.destinationTextField.frame.size.width = self!.view.frame.width
                    self!.destinationTextField.becomeFirstResponder()
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
            timer = Timer.scheduledTimer(timeInterval: 0.25,
                                         target: self,
                                         selector: #selector(DestinationInputViewController.search),
                                         userInfo: nil,
                                         repeats: true)

        }
    }
}
