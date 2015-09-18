//
//  ProductionViewController.swift
//  startrack
//
//  Created by Kyle Thomas on 9/7/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol ProductionViewControllerDelegate {

}

class ProductionViewController: ViewController {
    
    var delegate: ProductionViewControllerDelegate!

    @IBOutlet private weak var tableView: UITableView!

}
