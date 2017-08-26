//
//  DestinationResultsTableViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/26/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import KTSwiftExtensions

class DestinationResultsViewController: ViewController, UITableViewDelegate, UITableViewDataSource {

    var results: [Contact] = [Contact]() {
        didSet {
            tableView?.reloadData()
        }
    }

    @IBOutlet fileprivate weak var tableView: UITableView!
    
    // MARK: UITableViewDelegate
    
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
