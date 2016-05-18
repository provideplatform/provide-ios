//
//  JobViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/17/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class JobViewController: ViewController, FloorplanViewControllerDelegate {

    private var floorplanViewController: FloorplanViewController!

    var job: Job! {
        didSet {
            if let job = job {
                navigationItem.title = job.name
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = job.name

        floorplanViewController = UIStoryboard("Floorplan").instantiateViewControllerWithIdentifier("FloorplanViewController") as! FloorplanViewController
        floorplanViewController.floorplanViewControllerDelegate = self
        floorplanViewController.navigationItem.title = job.name

        navigationController!.popViewControllerAnimated(false)
        navigationController!.pushViewController(floorplanViewController, animated: false)
    }

    // MARK: FloorplanViewControllerDelegate

    func floorplanForFloorplanViewController(viewController: FloorplanViewController) -> Floorplan! {
        return nil
    }

    func jobForFloorplanViewController(viewController: FloorplanViewController) -> Job! {
        return job
    }

    func floorplanImageForFloorplanViewController(viewController: FloorplanViewController) -> UIImage! {
        return nil
    }

    func modeForFloorplanViewController(viewController: FloorplanViewController) -> FloorplanViewController.Mode! {
        return .Setup
    }

    func scaleCanBeSetByFloorplanViewController(viewController: FloorplanViewController) -> Bool {
        return false
    }

    func scaleWasSetForFloorplanViewController(viewController: FloorplanViewController) {

    }

    func newWorkOrderCanBeCreatedByFloorplanViewController(viewController: FloorplanViewController) -> Bool {
        return false
    }

    func areaSelectorIsAvailableForFloorplanViewController(viewController: FloorplanViewController) -> Bool {
        return false
    }
    
    func navigationControllerForFloorplanViewController(viewController: FloorplanViewController) -> UINavigationController! {
        return navigationController
    }

    func floorplanViewControllerCanDropWorkOrderPin(viewController: FloorplanViewController) -> Bool {
        return false
    }

    func toolbarForFloorplanViewController(viewController: FloorplanViewController) -> FloorplanToolbar! {
        return nil
    }

    func showToolbarForFloorplanViewController(viewController: FloorplanViewController) {

    }

    func hideToolbarForFloorplanViewController(viewController: FloorplanViewController) {
        
    }
}
