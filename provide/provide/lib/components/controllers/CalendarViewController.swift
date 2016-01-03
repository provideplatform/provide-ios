//
//  CalendarViewController.swift
//  provide
//
//  Created by Kyle Thomas on 1/3/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class CalendarViewController: PDTSimpleCalendarViewController {

    private var selectedCell: UICollectionViewCell!
    var selectedDateCell: UICollectionViewCell! {
        return selectedCell
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedCell = collectionView.cellForItemAtIndexPath(indexPath)
        super.collectionView(collectionView, didSelectItemAtIndexPath: indexPath)
    }
}
