//
//  TaskTableViewCellCheckboxView.swift
//  provide
//
//  Created by Kyle Thomas on 1/12/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import FontAwesomeKit

protocol TaskTableViewCellCheckboxViewDelegate {
    func taskTableViewCellCheckboxView(_ view: TaskTableViewCellCheckboxView, didBecomeChecked checked: Bool)
}
class TaskTableViewCellCheckboxView: UIView {

    let checkedGreenColor = UIColor("#447635")

    var delegate: TaskTableViewCellCheckboxViewDelegate!

    @IBOutlet fileprivate weak var checkIconImageView: UIImageView! {
        didSet {
            if let checkIconImageView = checkIconImageView {
                let imageBounds = bounds.insetBy(dx: 8.0, dy: 8.0)
                let checkIconImage = FAKFontAwesome.checkIcon(withSize: imageBounds.width).image(with: imageBounds.size).withRenderingMode(.alwaysTemplate)

                checkIconImageView.bounds = imageBounds
                checkIconImageView.frame = CGRect(x: 0.0, y: 0.0, width: imageBounds.width, height: imageBounds.height)
                checkIconImageView.image = checkIconImage
                checkIconImageView.tintColor = checkedGreenColor

                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TaskTableViewCellCheckboxView.tapped(_:)))
                checkIconImageView.addGestureRecognizer(tapGestureRecognizer)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFrame()
    }

    fileprivate func setupFrame() {
        bounds = CGRect(x: 0.0, y: 0.0, width: 25.0, height: 25.0)
        backgroundColor = UIColor.clear

        roundCorners(2.0)
        addBorder(1.5, color: UIColor.black)

        removeGestureRecognizers()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TaskTableViewCellCheckboxView.tapped(_:)))
        addGestureRecognizer(tapGestureRecognizer)
    }

    func tapped(_ gestureRecognizer: UITapGestureRecognizer) {
        if checkIconImageView.alpha == 1.0 {
            untickCheckbox()
        } else {
            tickCheckbox()
        }
    }

    fileprivate func tickCheckbox() {
        checkIconImageView?.alpha = 1.0
        delegate?.taskTableViewCellCheckboxView(self, didBecomeChecked: true)
    }

    fileprivate func untickCheckbox() {
        checkIconImageView?.alpha = 0.0
        delegate?.taskTableViewCellCheckboxView(self, didBecomeChecked: false)
    }

    func renderForTask(_ task: Task) {
        if task.id > 0 {
            alpha = 1.0
        }

        let completed = task.completedAt != nil || (task.status != nil && task.status == "completed")

        if completed {
            checkIconImageView?.alpha = 1.0
        } else {
            checkIconImageView?.alpha = 0.0
        }
    }
}
