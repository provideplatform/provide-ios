//
//  DirectionsTableViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/20/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class DirectionsTableViewController: UITableViewController {

    var directions: Directions! {
        didSet {
            if let tableView = tableView {
                tableView.reloadData()
            }
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return directions.routes.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return directions.routes[section].legs.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("directionsTableViewCellReuseIdentifier")!

        return cell
    }
}
