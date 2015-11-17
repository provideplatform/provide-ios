//
//  JobTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 11/17/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class JobTableViewCell: UITableViewCell {

    @IBOutlet private weak var nameLabel: UILabel!

    var job: Job! {
        didSet {
            if let job = job {
                nameLabel?.text = job.name
                nameLabel?.sizeToFit()
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel?.text = ""
    }
}
