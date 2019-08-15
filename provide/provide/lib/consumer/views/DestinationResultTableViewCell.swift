//
//  DestinationResultTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 8/26/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

class DestinationResultTableViewCell: UITableViewCell {

    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!

    var result: Contact? {
        didSet {
            if let result = result {
                icon.image = #imageLiteral(resourceName: "provide-pin")
                titleLabel.text = result.desc

                var st = ""
                if let city = result.city {
                    st = city
                }
                if let state = result.state {
                    if result.city != nil {
                        st = "\(st), "
                    }
                    st = "\(st)\(state)"
                }
                subtitleLabel.text = st
            } else {
                icon.image = nil
                titleLabel.text = ""
                subtitleLabel.text = ""
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        result = nil
    }
}
