//
//  DestinationResultsTableViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/26/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

typealias OnResultSelected = (Contact?) -> Void

class DestinationResultsViewController: ViewController, UITableViewDelegate, UITableViewDataSource {

    private var results: [Contact] = [Contact]() {
        didSet {
            tableView?.reloadData()
        }
    }

    private var onResultSelected: OnResultSelected!
    @IBOutlet private weak var tableView: UITableView!

    func configure(results: [Contact], onResultSelected: @escaping OnResultSelected) {
        self.results = results
        self.onResultSelected = onResultSelected
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        view.addDropShadow()
    }

    func updateResults(_ results: [Contact]) {
        self.results = results
        if !results.isEmpty {
            monkey("👨‍💼 Select: first result") {
                self.onResultSelected(results.first!)
            }
        }
    }

    func prepareForReuse() {
        results = []
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact = results[indexPath.row]
        logmoji("👱", "Selected: \(contact.desc!)")
        onResultSelected(contact)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(DestinationResultTableViewCell.self, for: indexPath)
        cell.result = results[indexPath.row]
        return cell
    }
}

extension DestinationResultsViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < -100 {
            onResultSelected(nil)
        }
    }
}
