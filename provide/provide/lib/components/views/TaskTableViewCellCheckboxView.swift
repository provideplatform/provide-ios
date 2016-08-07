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
    func taskTableViewCellCheckboxView(view: TaskTableViewCellCheckboxView, didBecomeChecked checked: Bool)
}
class TaskTableViewCellCheckboxView: UIView {

    let checkedGreenColor = UIColor("#447635")

    var delegate: TaskTableViewCellCheckboxViewDelegate!

    @IBOutlet private weak var checkIconImageView: UIImageView! {
        didSet {
            if let checkIconImageView = checkIconImageView {
                let imageBounds = CGRectInset(bounds, 8.0, 8.0)
                let checkIconImage = FAKFontAwesome.checkIconWithSize(imageBounds.width).imageWithSize(imageBounds.size).imageWithRenderingMode(.AlwaysTemplate)

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

    private func setupFrame() {
        bounds = CGRect(x: 0.0, y: 0.0, width: 25.0, height: 25.0)
        backgroundColor = UIColor.clearColor()

        roundCorners(2.0)
        addBorder(1.5, color: UIColor.blackColor())

        removeGestureRecognizers()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TaskTableViewCellCheckboxView.tapped(_:)))
        addGestureRecognizer(tapGestureRecognizer)
    }

    func tapped(gestureRecognizer: UITapGestureRecognizer) {
        if checkIconImageView.alpha == 1.0 {
            untickCheckbox()
        } else {
            tickCheckbox()
        }
    }

    private func tickCheckbox() {
        checkIconImageView?.alpha = 1.0
        delegate?.taskTableViewCellCheckboxView(self, didBecomeChecked: true)
    }

    private func untickCheckbox() {
        checkIconImageView?.alpha = 0.0
        delegate?.taskTableViewCellCheckboxView(self, didBecomeChecked: false)
    }

    func renderForTask(task: Task) {
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
