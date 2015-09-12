//
//  CastingDemandRecommendationCollectionViewCell.swift
//  startrack
//
//  Created by Kyle Thomas on 9/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol CastingDemandRecommendationCollectionViewCellDelegate {
    func castingDemandRecommendationCollectionViewCell(cell: CastingDemandRecommendationCollectionViewCell, didRejectRecommendedProvider: Provider)
    func castingDemandRecommendationCollectionViewCell(cell: CastingDemandRecommendationCollectionViewCell, didApproveRecommendedProvider: Provider)
}

class CastingDemandRecommendationCollectionViewCell: UICollectionViewCell, CastingDemandRecommendationViewControllerDelegate {

    var delegate: CastingDemandRecommendationCollectionViewCellDelegate!

    var recommendationViewController: CastingDemandRecommendationViewController!

    var provider: Provider! {
        didSet {
            initRecommendationViewController()
        }
    }

    private func initRecommendationViewController() {
        if let recommendationViewController = recommendationViewController {
            recommendationViewController.view.removeFromSuperview()
            self.recommendationViewController = nil
        }

        recommendationViewController = UIStoryboard("CastingDirector").instantiateViewControllerWithIdentifier("CastingDemandRecommendationViewController") as! CastingDemandRecommendationViewController
        recommendationViewController.delegate = self

        recommendationViewController.view.frame = frame.insetBy(dx: 20.0, dy: 0.0)
        addSubview(recommendationViewController.view)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        initRecommendationViewController()
    }

    // MARK: CastingDemandRecommendationCollectionViewCellDelegate

    func providerForCastingDemandRecommendationViewController(viewController: CastingDemandRecommendationViewController) -> Provider {
        return provider
    }

    func castingDemandRecommendationViewController(viewController: CastingDemandRecommendationViewController, didRejectRecommendedProvider provider: Provider) {
        delegate?.castingDemandRecommendationCollectionViewCell(self, didRejectRecommendedProvider: provider)
    }

    func castingDemandRecommendationViewController(viewController: CastingDemandRecommendationViewController, didApproveRecommendedProvider: Provider) {
        delegate?.castingDemandRecommendationCollectionViewCell(self, didApproveRecommendedProvider: provider)
    }
}
