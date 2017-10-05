//
//  DestinationResultsTableViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/26/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import KTSwiftExtensions

protocol DestinationResultsViewControllerDelegate: NSObjectProtocol {
    func destinationResultsViewController(_ viewController: DestinationResultsViewController, didSelectResult result: Contact)
}

class DestinationResultsViewController: ViewController, UITableViewDelegate, UITableViewDataSource {

    weak var delegate: DestinationResultsViewControllerDelegate!

    var results: [Contact] = [Contact]() {
        didSet {
            tableView?.reloadData()
        }
    }

    @IBOutlet fileprivate weak var tableView: UITableView!

    func prepareForReuse() {
        results = [Contact]()
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact = results[indexPath.row]
        logInfo("Selected destination result: \(contact.desc)")
        delegate?.destinationResultsViewController(self, didSelectResult: contact)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "destinationResultTableViewCellReuseIdentifier") as! DestinationResultTableViewCell
        cell.result = results[indexPath.row]
        return cell
    }
}
