//
//  CategoryPickerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 3/19/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol CategoryPickerViewControllerDelegate {
    func categoryPickerViewController(viewController: CategoryPickerViewController, didSelectCategory category: Category)
}

class CategoryPickerViewController: UITableViewController {

    var delegate: CategoryPickerViewControllerDelegate!

    var categories = [Category]() {
        didSet {
            tableView?.reloadData()

            teardownPullToRefresh()
        }
    }

    var selectedCategories = [Category]() {
        didSet {
            tableView?.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "SELECT CATEGORY"

        setupPullToRefresh()
    }

    private func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(CategoryPickerViewController.reset), forControlEvents: .ValueChanged)

        tableView.addSubview(refreshControl!)

        refreshControl?.beginRefreshing()
    }

    private func teardownPullToRefresh() {
        refreshControl?.endRefreshing()
        refreshControl?.removeFromSuperview()
    }

    func reset() {
        categories = [Category]()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("categoryTableViewCellReuseIdentifier") as! CategoryTableViewCell

        cell.category = categories[indexPath.row]

        for selectedCategory in selectedCategories {
            if selectedCategory.id == cell.category.id {
                cell.setSelected(true, animated: false)
                break
            }
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedCategories.append(categories[indexPath.row])

        delegate?.categoryPickerViewController(self, didSelectCategory: categories[indexPath.row])
    }
}
