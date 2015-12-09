//
//  JobReviewViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class JobReviewViewController: ViewController {

    weak var job: Job! {
        didSet {
            if let job = job {
                print("set job in job review view controller \(job)")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
