//
//  TopViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

class TopViewController: ViewController, MenuViewControllerDelegate {

    private(set) var rootViewController: UIViewController?

    private var topStoryboard: UIStoryboard {
        guard let mode = KeyChainService.shared.mode else { return UIStoryboard("Jobs") } // Should never happen

        switch mode {
        case .consumer: return UIStoryboard("Consumer")
        case .provider: return UIStoryboard("Jobs")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        reload()
    }

    func reload() {
        if rootViewController != nil {
            navigationController?.setNavigationBarHidden(true, animated: false)
            navigationController?.popViewController(animated: false)
            if #available(iOS 11.0, *) {
                navigationController?.navigationBar.prefersLargeTitles = true
            }

            rootViewController = nil
        }

        rootViewController = topStoryboard.instantiateInitialViewController()

        navigationController?.pushViewController(rootViewController!, animated: false)

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
                return MenuItem(label: "Legal", urlString: "\(CurrentEnvironment.baseUrlString)/#/legal")
            case 1:
                return MenuItem(label: "Logout", action: #selector(MenuViewController.logout))
            default:
                break
            }
        } else if let delegate = rootViewController as? MenuViewControllerDelegate {
            return delegate.menuItemForMenuViewController(menuViewController, at: indexPath)
        }
        return nil
    }

    func numberOfSectionsInMenuViewController(_ menuViewController: MenuViewController) -> Int {
        if let delegate = rootViewController as? MenuViewControllerDelegate {
            return delegate.numberOfSectionsInMenuViewController(menuViewController) + 1
        }
        return 1
    }

    func menuViewController(_ menuViewController: MenuViewController, numberOfRowsInSection section: Int) -> Int {
        if section == numberOfSectionsInMenuViewController(menuViewController) - 1 {
            return 2
        } else if let delegate = rootViewController as? MenuViewControllerDelegate {
            return delegate.menuViewController(menuViewController, numberOfRowsInSection: section)
        } else {
            return 0
        }
    }
}
