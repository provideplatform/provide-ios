//
//  CastingDemandViewController.swift
//  startrack
//
//  Created by Kyle Thomas on 9/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class CastingDemandViewController: ViewController, CastingDemandRecommendationCollectionViewCellDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIAlertViewDelegate {

    @IBOutlet private weak var recommendationsCollectionView: UICollectionView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    var castingDemand: CastingDemand! {
        didSet {
            refreshNavigationItem()
            fetchProviderRecommendations()
        }
    }

    private var providers = [Provider]()

    private var pendingProvider: Provider!

    private func fetchProviderRecommendations() {
        activityIndicatorView?.startAnimating()

        castingDemand?.fetchProviderRecommendations(
            { statusCode, mappingResult in
                for provider in mappingResult.array() as! [Provider] {
                    var queuedRecommendation = false
                    for queuedProvider in self.providers {
                        queuedRecommendation = queuedProvider.id == provider.id
                        if queuedRecommendation {
                            break
                        }
                    }
                    let validRecommendation = !queuedRecommendation && (self.pendingProvider == nil || self.pendingProvider.id != provider.id)
                    if validRecommendation {
                        self.providers.append(provider)
                    }
                }
                self.recommendationsCollectionView.reloadData()
                self.activityIndicatorView.stopAnimating()
            },
            onError: { error, statusCode, responseString in
                self.activityIndicatorView.stopAnimating()
            }
        )
    }

    private func showNextRecommendation() {
        providers.removeFirst()
        dispatch_after_delay(0.0) {
            self.recommendationsCollectionView.reloadData()
        }
        if providers.count <= 2 {
            fetchProviderRecommendations()
        }
    }

    private func refreshNavigationItem() {
        navigationItem.title = castingDemand?.actingRole.name.uppercaseString
    }

    private func promptForRecurrence() {
        let message = "Attempt to cast \(pendingProvider.contact.firstName) for all shooting dates associated with this \(castingDemand.actingRole.name) role?"
        let cancelButtonTitle = "No, just for \(castingDemand.scheduledStartAtDate.timeString!) on \(castingDemand.scheduledStartAtDate.dateString)"
        let alertView = UIAlertView(title: "Cast Role", message: message, delegate: self, cancelButtonTitle: cancelButtonTitle)
        alertView.addButtonWithTitle("Yes")
        alertView.addButtonWithTitle("Specific Dates")
        alertView.show()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = .None

        recommendationsCollectionView.registerClass(CastingDemandRecommendationCollectionViewHeader.self,
                                                    forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                                                    withReuseIdentifier: "castingDemandRecommendationCollectionViewHeader")

        recommendationsCollectionView.scrollEnabled = false


    }

//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "CastingDemandRecommendationViewControllerEmbedSegue" {
//            (segue.destinationViewController as! CastingDemandRecommendationViewController).delegate = self
//        }
//    }

    // MARK: CastingDemandRecommendationCollectionViewCellDelegate

    func castingDemandRecommendationCollectionViewCell(cell: CastingDemandRecommendationCollectionViewCell, didRejectRecommendedProvider provider: Provider) {
        print("rejected recommended provider \(provider)")
        showNextRecommendation()
    }

    func castingDemandRecommendationCollectionViewCell(cell: CastingDemandRecommendationCollectionViewCell, didApproveRecommendedProvider provider: Provider) {
        pendingProvider = provider

        let shouldPromptForRecurrence = provider.id != -1

        if shouldPromptForRecurrence {
            promptForRecurrence()
        } else {
            scheduleWorkOrderForPendingProvider()
        }
    }

    func scheduleWorkOrderForPendingProvider() {
        let params = [
            "casting_demand_id": String(castingDemand.id),
            "customer_id": String(castingDemand.shooting.location.id),
            "work_order_providers": [["provider_id": pendingProvider.id]],
            "scheduled_start_at": castingDemand.scheduledStartAtDate.utcString,
            "estimated_duration": castingDemand.estimatedDuration * 60,
            "status": "scheduled",
            "components": [["component": "QRCode"]]
        ]

        ApiService.sharedService().createWorkOrder(params as! [String : AnyObject],
            onSuccess: { (statusCode, mappingResult) -> () in
                self.pendingProvider = nil

                self.castingDemand.quantityRemaining--
                self.recommendationsCollectionView.reloadData()
            },
            onError: { error, statusCode, responseString in
                self.pendingProvider = nil
            }
        )

        showNextRecommendation()
    }

    // MARK: UICollectionViewDelegate

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(10.0, 0.0, 0.0, 0.0)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }

    // MARK: UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return providers.count
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "castingDemandRecommendationCollectionViewHeaderReuseIdentifier", forIndexPath: indexPath) as! CastingDemandRecommendationCollectionViewHeader
        view.castingDemand = castingDemand
        return view
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("castingDemandRecommendationCollectionViewCellReuseIdentifier", forIndexPath: indexPath) as! CastingDemandRecommendationCollectionViewCell
        cell.delegate = self
        cell.provider = providers[indexPath.row]
        return cell
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    // MARK: UIAlertViewDelegate

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        switch buttonIndex {
        case 0:
            scheduleWorkOrderForPendingProvider()
        case 1:
            // TODO: schedule pending provider work orders for all shooting dates... scheduleWorkOrderForPendingProvider()
            print("TODO: schedule a work order for each shooting date...")
        case 2:
            print("TODO: schedule a work order for specific dates by picking them from the calendar...")
        default:
            break
        }
    }

//    // Called when we cancel a view (eg. the user clicks the Home button). This is not called when the user clicks the cancel button.
//    // If not defined in the delegate, we simulate a click in the cancel button
//    @available(iOS, introduced=2.0, deprecated=9.0)
//    optional public func alertViewCancel(alertView: UIAlertView)
//
//    @available(iOS, introduced=2.0, deprecated=9.0)
//    optional public func willPresentAlertView(alertView: UIAlertView) // before animation and showing view
//    @available(iOS, introduced=2.0, deprecated=9.0)
//    optional public func didPresentAlertView(alertView: UIAlertView) // after animation
//
//    @available(iOS, introduced=2.0, deprecated=9.0)
//    optional public func alertView(alertView: UIAlertView, willDismissWithButtonIndex buttonIndex: Int) // before animation and hiding view
//    @available(iOS, introduced=2.0, deprecated=9.0)
//    optional public func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) // after animation
//
//    // Called after edits in any of the default fields added by the style
//    @available(iOS, introduced=2.0, deprecated=9.0)
//    optional public func alertViewShouldEnableFirstOtherButton(alertView: UIAlertView) -> Bool
}
