//
//  CastingDemandRecommendationViewController.swift
//  startrack
//
//  Created by Kyle Thomas on 9/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol CastingDemandRecommendationViewControllerDelegate {
    func providerForCastingDemandRecommendationViewController(viewController: CastingDemandRecommendationViewController) -> Provider
    func castingDemandRecommendationViewController(viewController: CastingDemandRecommendationViewController, didRejectRecommendedProvider: Provider)
    func castingDemandRecommendationViewController(viewController: CastingDemandRecommendationViewController, didApproveRecommendedProvider: Provider)
}

class CastingDemandRecommendationViewController: ViewController, CastingDemandRecommendationContainerViewDelegate {
    
    var delegate: CastingDemandRecommendationViewControllerDelegate!

    @IBOutlet private weak var containerView: CastingDemandRecommendationContainerView!

    override func viewDidLoad() {
        super.viewDidLoad()

        containerView.delegate = self
    }

    // MARK: CastingDemandRecommendationContainerViewDelegate

    func providerForCastingDemandRecommendationContainerView(view: CastingDemandRecommendationContainerView) -> Provider {
        return delegate.providerForCastingDemandRecommendationViewController(self)
    }

    func castingDemandRecommendationContainerView(view: CastingDemandRecommendationContainerView, didRejectRecommendedProvider provider: Provider) {
        delegate?.castingDemandRecommendationViewController(self, didRejectRecommendedProvider: provider)
    }

    func castingDemandRecommendationContainerView(view: CastingDemandRecommendationContainerView, didApproveRecommendedProvider provider: Provider) {
        delegate?.castingDemandRecommendationViewController(self, didApproveRecommendedProvider: provider)
    }
}
