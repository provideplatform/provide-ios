//
//  DestinationResultTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 8/26/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import KTSwiftExtensions

class DestinationResultTableViewCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var icon: UIImageView!
    @IBOutlet fileprivate weak var title: UILabel!
    @IBOutlet fileprivate weak var subtitle: UILabel!
    
    var result: Contact! {
        didSet {
            if let result = result {
                icon.image = #imageLiteral(resourceName: "provide-pin")
                title.text = result.desc
                subtitle.text = "\(result.city!), \(result.state!)"
            } else {
                icon.image = nil
                title.text = ""
                subtitle.text = ""
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        result = nil
    }
}
