//
//  CastingDemandViewController.swift
//  startrack
//
//  Created by Kyle Thomas on 9/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class CastingDemandViewController: ViewController, CastingDemandRecommendationCollectionViewCellDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

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
        let params = [
            "casting_demand_id": String(castingDemand.id),
            "customer_id": String(castingDemand.shooting.location.id),
            "work_order_providers": [["provider_id": provider.id]],
            "scheduled_start_at": castingDemand.scheduledStartAtDate.utcString,
            "estimated_duration": castingDemand.estimatedDuration * 60,
            "status": "scheduled",
            "components": [["component": "QRCodeCheckin"]]
        ]

        pendingProvider = provider

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
}
