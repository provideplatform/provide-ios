//
//  FloorplanSelectorView.swift
//  provide
//
//  Created by Kyle Thomas on 4/30/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

protocol FloorplanSelectorViewDelegate {
    func jobForFloorplanSelectorView(_ selectorView: FloorplanSelectorView) -> Job!
    func floorplanSelectorView(_ selectorView: FloorplanSelectorView, didSelectFloorplan floorplan: Floorplan!, atIndexPath indexPath: IndexPath!)
}

class FloorplanSelectorView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {

    var delegate: FloorplanSelectorViewDelegate! {
        didSet {
            if let _ = delegate {
                collectionView.reloadData()
            }
        }
    }

    @IBOutlet fileprivate weak var collectionView: UICollectionView!

    weak var job: Job! {
        return delegate?.jobForFloorplanSelectorView(self)
    }

    fileprivate var floorplans: [Floorplan] {
        if let job = job {
            return job.floorplans
        }
        return [Floorplan]()
    }

    fileprivate func thumbnailUrlForFloorplanAtIndex(_ index: Int) -> URL! {
        return floorplans[index].thumbnailImageUrl as URL!
    }

    func redraw(_ targetView: UIView) {
        dispatch_after_delay(0.0) {
            if let superview = self.superview {
                if superview != targetView {
                    self.removeFromSuperview()
                }
            } else {
                targetView.addSubview(self)
            }

            targetView.bringSubview(toFront: self)

            self.frame = CGRect(x: 50.0,
                                y: Double(targetView.frame.height) - 165.0 - 10.0 - 44.0,
                                width: (Double(self.floorplans.count) * 175.0) + 125.0 + 10.0,
                                height: 165.0)

            self.collectionView.contentSize = self.frame.size
            self.collectionView.frame.size = self.collectionView.contentSize
        }
    }

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return floorplans.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: "floorplanCollectionViewCellReuseIdentifier", for: indexPath) as! PickerCollectionViewCell
        cell.rendersCircularImage = false

        if (indexPath as NSIndexPath).row <= floorplans.count - 1 {
            let floorplan = floorplans[(indexPath as NSIndexPath).row]

            //cell.selected = isSelected(floorplan)

            if cell.isSelected {
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition())
            }

            cell.name = floorplan.name

            if let thumbnailUrl = thumbnailUrlForFloorplanAtIndex((indexPath as NSIndexPath).row) {
                cell.imageUrl = thumbnailUrl
            }
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "importFloorplanCollectionViewCellReuseIdentifier", for: indexPath) as! PickerCollectionViewCell
        }

        return cell
    }

    // MARK: UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(5.0, 10.0, 5.0, 10.0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        if (indexPath as NSIndexPath).row < floorplans.count - 1 {
            return CGSize(width: 175.0, height: 150.0)
        }
        return CGSize(width: 125.0, height: 150.0)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row <= floorplans.count - 1 {
            let floorplan = floorplans[(indexPath as NSIndexPath).row]
            delegate?.floorplanSelectorView(self, didSelectFloorplan: floorplan, atIndexPath: indexPath)
        } else {
            delegate?.floorplanSelectorView(self, didSelectFloorplan: nil, atIndexPath: nil)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        //let floorplan = floorplans[indexPath.row]
        //delegate?.floorplanSelectorView(self, didDeselectFloorplan: product)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
}
