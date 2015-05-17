//
//  WorkOrderDestinationHeaderViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderDestinationHeaderViewController: ViewController {

    var initialFrame: CGRect! {
        return CGRectMake(view.frame.origin.x,
                          view.frame.size.height * -2,
                          view.frame.size.width,
                          view.frame.size.height)
    }

    var targetView: UIView! {
        get {
            return workOrdersViewControllerDelegate.targetViewForViewController?(self)
        }
    }

    weak var workOrder: WorkOrder! {
        get {
            return WorkOrderService.sharedService().nextWorkOrder
        }
    }

    var workOrdersViewControllerDelegate: WorkOrdersViewControllerDelegate!

    private var rendered = false

    @IBOutlet private weak var titleImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addressTextView: UITextView!

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.933, green: 0.937, blue: 0.945, alpha: 1.00)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    func render() {
        view.removeFromSuperview()
        view.alpha = 0

        targetView.addSubview(view)
        targetView.bringSubviewToFront(view)

        if workOrder != nil {
            if workOrder.customer.profileImageUrl != nil {
                // TODO -- load the image view using the profileImageUrl
            } else if workOrder.customer.contact.email != nil {
                var gravatarImageView = RFGravatarImageView(frame: titleImageView.frame)
                gravatarImageView.email = workOrder.contact.email
                gravatarImageView.load({ (error) -> Void in
                    gravatarImageView.makeCircular()
                    self.view.insertSubview(gravatarImageView, aboveSubview: self.titleImageView)
                    self.titleImageView.alpha = 0
                    gravatarImageView.alpha = 1
                })
            }

            titleLabel.text = workOrder.customer.displayName
            addressTextView.text = workOrder.customer.contact.address
        }

        //var frame = initialFrame
        var frame = CGRectMake(0.0,
            targetView.frame.size.height,
            targetView.frame.size.width,
            view.frame.size.height)

        if let navigationController = workOrdersViewControllerDelegate.navigationControllerForViewController?(self) {
            frame = CGRectMake(frame.origin.x,
                               navigationController.navigationBar.frame.size.height + navigationController.navigationBar.frame.origin.y,
                               navigationController.navigationBar.frame.size.width,
                               frame.size.height)
        }

        view.frame = frame

        view.addDropShadow(CGSizeMake(1.0, 1.25), radius: 2.0, opacity: 0.3)

        UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseIn,
            animations: { () -> Void in
                self.view.alpha = 1
                self.view.frame = CGRectMake(frame.origin.x,
                                             frame.origin.y,
                                             frame.size.width,
                                             frame.size.height)

                

            },
            completion: { (complete) -> Void in
                
            }
        )
    }

    func unwind() {
        UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseIn,
            animations: { () -> Void in
                self.view.alpha = 0
                self.view.frame = self.initialFrame

            },
            completion: { (complete) -> Void in
                self.view.removeFromSuperview()
            }
        )
    }

    // MARK Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case "WorkOrderDestinationHeaderViewControllerUnwindSegue":
            assert(segue.sourceViewController is WorkOrderDestinationHeaderViewController)
            assert(segue.destinationViewController is WorkOrdersViewController)
            unwind()
            break
        default:
            break
        }
    }
}
