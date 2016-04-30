//
//  BlueprintSelectorView.swift
//  provide
//
//  Created by Kyle Thomas on 4/30/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintSelectorViewDelegate {
    func jobForBlueprintSelectorView(selectorView: BlueprintSelectorView) -> Job!
    func blueprintSelectorView(selectorView: BlueprintSelectorView, didSelectBlueprint blueprint: Attachment)
}

class BlueprintSelectorView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {

    var delegate: BlueprintSelectorViewDelegate! {
        didSet {
            if let _ = delegate {
                collectionView.reloadData()
            }
        }
    }

    @IBOutlet private weak var collectionView: UICollectionView!

    weak var job: Job! {
        return delegate?.jobForBlueprintSelectorView(self)
    }

    private var blueprints: [Attachment] {
        if let job = job {
            return job.blueprints
        }
        return [Attachment]()
    }

    private func thumbnailUrlForBlueprintAtIndex(index: Int) -> NSURL! {
        let blueprint = blueprints[index]
        for representation in blueprint.representations {
            if representation.hasTag("72dpi") {
                if let thumbnailUrl = representation.thumbnailUrl {
                    return thumbnailUrl
                } else {
                    for rep in representation.representations {
                        if rep.hasTag("thumbnail") {
                            return rep.url
                        }
                    }
                }
            }
        }

        return nil
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
                                y: targetView.frame.height - 165.0 - 10.0 - 44.0,
                                width: 345.0,
                                height: 165.0)

            self.collectionView.contentSize = self.frame.size

        }
    }

    // MARK: UICollectionViewDataSource

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return blueprints.count + 1
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("blueprintCollectionViewCellReuseIdentifier", forIndexPath: indexPath) as! PickerCollectionViewCell
        cell.rendersCircularImage = false

        if indexPath.row <= blueprints.count - 1 {
            let blueprint = blueprints[indexPath.row]

            //cell.selected = isSelected(blueprint)

            if cell.selected {
                collectionView.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: .None)
            }

            cell.name = blueprint.filename

            if let thumbnailUrl = thumbnailUrlForBlueprintAtIndex(indexPath.row) {
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
//        let inset = UIEdgeInsetsMake(10.0, 10.0, 0.0, 10.0)
//        let insetWidthOffset = inset.left + inset.right
//        if let superview = collectionView.superview {
//            return CGSizeMake(superview.bounds.width - insetWidthOffset, 125.0)
//        }
        if indexPath.row < blueprints.count - 1 {
            CGSizeMake(175.0, 150.0)
        }
        return CGSizeMake(125.0, 150.0)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        //let blueprint = blueprints[indexPath.row]
        //delegate?.blueprintSelectorView(self, didSelectBlueprint: product)
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
