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

    var castingDemand: CastingDemand! {
        didSet {
            refreshNavigationItem()

//            nameLabel?.text = castingDemand.actingRole.name
//
//            attributesLabel?.text = ""
//            quantityLabel?.text = "Quantity: \(castingDemand.quantity)"
//            rateLabel?.text = "Budget: $\(castingDemand.rate) / \(castingDemand.estimatedDuration)"

            fetchProviderRecommendations()
        }
    }

    private var providers = [Provider]()

    private func fetchProviderRecommendations() {
        castingDemand?.fetchProviderRecommendations(
            { statusCode, mappingResult in
                for provider in mappingResult.array() as! [Provider] {
                    self.providers.append(provider)
                }
                self.recommendationsCollectionView.reloadData()
            },
            onError: { error, statusCode, responseString in

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
        print("approved recommended provider \(provider)")
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
