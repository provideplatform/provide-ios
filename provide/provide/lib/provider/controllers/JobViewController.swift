//
//  JobViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/17/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class JobViewController: ViewController, FloorplanViewControllerDelegate {

    fileprivate var floorplanViewController: FloorplanViewController!

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

        floorplanViewController = UIStoryboard("Floorplan").instantiateViewController(withIdentifier: "FloorplanViewController") as! FloorplanViewController
        floorplanViewController.floorplanViewControllerDelegate = self
        floorplanViewController.navigationItem.title = job.name

        navigationController!.popViewController(animated: false)
        navigationController!.pushViewController(floorplanViewController, animated: false)
    }

    // MARK: FloorplanViewControllerDelegate

    func floorplanForFloorplanViewController(_ viewController: FloorplanViewController) -> Floorplan! {
        return nil
    }

    func jobForFloorplanViewController(_ viewController: FloorplanViewController) -> Job! {
        return job
    }

    func floorplanImageForFloorplanViewController(_ viewController: FloorplanViewController) -> UIImage! {
        return nil
    }

    func modeForFloorplanViewController(_ viewController: FloorplanViewController) -> FloorplanViewController.Mode! {
        return .setup
    }

    func scaleCanBeSetByFloorplanViewController(_ viewController: FloorplanViewController) -> Bool {
        return false
    }

    func scaleWasSetForFloorplanViewController(_ viewController: FloorplanViewController) {

    }

    func newWorkOrderCanBeCreatedByFloorplanViewController(_ viewController: FloorplanViewController) -> Bool {
        return false
    }

    func areaSelectorIsAvailableForFloorplanViewController(_ viewController: FloorplanViewController) -> Bool {
        return false
    }
    
    func navigationControllerForFloorplanViewController(_ viewController: FloorplanViewController) -> UINavigationController! {
        return navigationController
    }

    func floorplanViewControllerCanDropWorkOrderPin(_ viewController: FloorplanViewController) -> Bool {
        return false
    }

    func toolbarForFloorplanViewController(_ viewController: FloorplanViewController) -> FloorplanToolbar! {
        return nil
    }

    func showToolbarForFloorplanViewController(_ viewController: FloorplanViewController) {

    }

    func hideToolbarForFloorplanViewController(_ viewController: FloorplanViewController) {
        
    }
}
