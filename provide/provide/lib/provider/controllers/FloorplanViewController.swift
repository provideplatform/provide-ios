//
//  FloorplanViewController.swift
//  provide
//
//  Created by Kyle Thomas on 1/18/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class FloorplanViewController: ViewController, FloorplanCreationViewControllerDelegate {

    var floorplan: Floorplan! {
        didSet {
            if let floorplan = floorplan {
                navigationItem.title = floorplan.name

                floorplanCreationViewController?.delegate = self
            }
        }
    }

    private var floorplanCreationViewController: FloorplanCreationViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "FloorplanCreationViewControllerEmbedSegue" {
            floorplanCreationViewController = segue.destinationViewController as! FloorplanCreationViewController
            floorplanCreationViewController.delegate = self
        }
    }

    // MARK: FloorplanCreationViewControllerDelegate

    func floorplanForFloorplanCreationViewController(viewController: FloorplanCreationViewController) -> Floorplan! {
        return floorplan
    }

    func floorplanCreationViewController(viewController: FloorplanCreationViewController, didCreateFloorplan floorplan: Floorplan) {
        // no-op
    }

    func floorplanCreationViewController(viewController: FloorplanCreationViewController, didUpdateFloorplan floorplan: Floorplan) {
        navigationItem.title = floorplan.name
    }
}
