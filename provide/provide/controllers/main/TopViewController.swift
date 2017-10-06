//
//  TopViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

class TopViewController: ViewController, MenuViewControllerDelegate {

    fileprivate var vc: UIViewController!

    fileprivate var topStoryboard: UIStoryboard! {
        if let mode = KeyChainService.shared.mode {
            switch mode {
            case .customer:
                return UIStoryboard("Customer")
            case .provider:
                return UIStoryboard("Provider")
            }
        } else {
            // this should never happen...
            logWarn("No user mode resolved... panic!!!") // this should never happen...
        }
        return nil
    }

    var rootViewController: UIViewController! {
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        reload()
    }

    func reload() {
        if vc != nil {
            navigationController?.setNavigationBarHidden(true, animated: false)
            navigationController?.popViewController(animated: false)
            self.vc = nil
        }

        vc = topStoryboard.instantiateInitialViewController()

        navigationController?.pushViewController(vc, animated: false)

        navigationItem.hidesBackButton = true
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    // MARK: MenuViewControllerDelegate

    func navigationControllerForMenuViewController(_ menuViewController: MenuViewController) -> UINavigationController? {
        return navigationController
    }

    func menuItemForMenuViewController(_ menuViewController: MenuViewController, at indexPath: IndexPath) -> MenuItem? {
        if indexPath.section == numberOfSectionsInMenuViewController(menuViewController) - 1 {
            switch indexPath.row {
            case 0:
                return MenuItem(item: ["label": "Legal", "url": "\(CurrentEnvironment.baseUrlString)/#/legal"])
            case 1:
                return MenuItem(item: ["label": "Logout", "action": "logout"])
            default:
                break
            }
        } else if let delegate = vc as? MenuViewControllerDelegate {
            return delegate.menuItemForMenuViewController(menuViewController, at: indexPath)
        }
        return nil
    }

    func numberOfSectionsInMenuViewController(_ menuViewController: MenuViewController) -> Int {
        if let delegate = vc as? MenuViewControllerDelegate {
            return delegate.numberOfSectionsInMenuViewController(menuViewController) + 1
        }
        return 1
    }

    func menuViewController(_ menuViewController: MenuViewController, numberOfRowsInSection section: Int) -> Int {
        if section == numberOfSectionsInMenuViewController(menuViewController) - 1 {
            return 2
        } else if let delegate = vc as? MenuViewControllerDelegate {
            return delegate.menuViewController(menuViewController, numberOfRowsInSection: section)
        } else {
            return 0
        }
    }
}
