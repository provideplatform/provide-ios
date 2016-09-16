//
//  CategoryPickerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 3/19/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol CategoryPickerViewControllerDelegate {
    func categoryPickerViewController(_ viewController: CategoryPickerViewController, didSelectCategory category: Category)
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

    fileprivate func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(CategoryPickerViewController.reset), for: .valueChanged)

        tableView.addSubview(refreshControl!)

        refreshControl?.beginRefreshing()
    }

    fileprivate func teardownPullToRefresh() {
        refreshControl?.endRefreshing()
        refreshControl?.removeFromSuperview()
    }

    func reset() {
        categories = [Category]()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryTableViewCellReuseIdentifier") as! CategoryTableViewCell

        cell.category = categories[(indexPath as NSIndexPath).row]

        for selectedCategory in selectedCategories {
            if selectedCategory.id == cell.category.id {
                cell.setSelected(true, animated: false)
                break
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCategories.append(categories[(indexPath as NSIndexPath).row])

        delegate?.categoryPickerViewController(self, didSelectCategory: categories[(indexPath as NSIndexPath).row])
    }
}
