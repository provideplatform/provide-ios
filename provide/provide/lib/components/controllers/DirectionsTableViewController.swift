//
//  DirectionsTableViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/20/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class DirectionsTableViewController: UITableViewController {

    var directions: Directions! {
        didSet {
            tableView?.reloadData()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return directions.routes.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return directions.routes[section].legs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "directionsTableViewCellReuseIdentifier")!

        return cell
    }
}
