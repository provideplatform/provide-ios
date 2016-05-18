//
//  FloorplanSelectorView.swift
//  provide
//
//  Created by Kyle Thomas on 4/30/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol FloorplanSelectorViewDelegate {
    func jobForFloorplanSelectorView(selectorView: FloorplanSelectorView) -> Job!
    func floorplanSelectorView(selectorView: FloorplanSelectorView, didSelectFloorplan floorplan: Floorplan!, atIndexPath indexPath: NSIndexPath!)
}

class FloorplanSelectorView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {

    var delegate: FloorplanSelectorViewDelegate! {
        didSet {
            if let _ = delegate {
                collectionView.reloadData()
            }
        }
    }

    @IBOutlet private weak var collectionView: UICollectionView!

    weak var job: Job! {
        return delegate?.jobForFloorplanSelectorView(self)
    }

    private var floorplans: [Floorplan] {
        if let job = job {
            return job.floorplans
        }
        return [Floorplan]()
    }

    private func thumbnailUrlForFloorplanAtIndex(index: Int) -> NSURL! {
        return floorplans[index].thumbnailImageUrl
    }

    func redraw(targetView: UIView) {
        dispatch_after_delay(0.0) {
            if let superview = self.superview {
                if superview != targetView {
                    self.removeFromSuperview()
                }
            } else {
                targetView.addSubview(self)
            }

            targetView.bringSubviewToFront(self)

            self.frame = CGRect(x: 50.0,
                                y: Double(targetView.frame.height) - 165.0 - 10.0 - 44.0,
                                width: (Double(self.floorplans.count) * 175.0) + 125.0 + 10.0,
                                height: 165.0)

            self.collectionView.contentSize = self.frame.size
            self.collectionView.frame.size = self.collectionView.contentSize
        }
    }

    // MARK: UICollectionViewDataSource

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return floorplans.count + 1
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("blueprintCollectionViewCellReuseIdentifier", forIndexPath: indexPath) as! PickerCollectionViewCell
        cell.rendersCircularImage = false

        if indexPath.row <= floorplans.count - 1 {
            let floorplan = floorplans[indexPath.row]

            //cell.selected = isSelected(blueprint)

            if cell.selected {
                collectionView.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: .None)
            }

            cell.name = floorplan.name

            if let thumbnailUrl = thumbnailUrlForFloorplanAtIndex(indexPath.row) {
                cell.imageUrl = thumbnailUrl
            }
        } else {
            cell = collectionView.dequeueReusableCellWithReuseIdentifier("importBlueprintCollectionViewCellReuseIdentifier", forIndexPath: indexPath) as! PickerCollectionViewCell
        }

        return cell
    }

    // MARK: UICollectionViewDelegate

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(5.0, 10.0, 5.0, 10.0)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if indexPath.row < floorplans.count - 1 {
            CGSizeMake(175.0, 150.0)
        }
        return CGSizeMake(125.0, 150.0)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row <= floorplans.count - 1 {
            let floorplan = floorplans[indexPath.row]
            delegate?.floorplanSelectorView(self, didSelectFloorplan: floorplan, atIndexPath: indexPath)
        } else {
            delegate?.floorplanSelectorView(self, didSelectFloorplan: nil, atIndexPath: nil)
        }
    }

    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        //let blueprint = blueprints[indexPath.row]
        //delegate?.blueprintSelectorView(self, didDeselectBlueprint: product)
    }

    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
}
