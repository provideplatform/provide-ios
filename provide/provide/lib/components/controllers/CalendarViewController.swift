//
//  CalendarViewController.swift
//  provide
//
//  Created by Kyle Thomas on 1/3/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import PDTSimpleCalendar

class CalendarViewController: PDTSimpleCalendarViewController {

    fileprivate var selectedCell: UICollectionViewCell!
    var selectedDateCell: UICollectionViewCell! {
        return selectedCell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCell = collectionView.cellForItem(at: indexPath)
        super.collectionView(collectionView, didSelectItemAt: indexPath)
    }
}
