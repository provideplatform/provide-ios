//
//  ProfileImageView.swift
//  provide
//
//  Created by Kyle Thomas on 9/17/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

typealias OnProfileImageFetched = () -> Void

class ProfileImageView: UIImageView {

    convenience init(url: URL) {
        self.init()
        self.url = url
    }

    var urlString: String! {
        didSet {
            url = URL(string: urlString)
        }
    }

    var url: URL! {
        didSet {
            setImageWithUrl(url, callback: nil)
        }
    }

    func setImageWithUrl(_ url: URL!, callback: OnProfileImageFetched!) {
        if let url = url {
            alpha = 0.0
            contentMode = .scaleAspectFit

            sd_setImage(with: url) { [weak self] image, error, cacheType, url in
                self?.makeCircular()
                self?.alpha = 1.0

                callback?()
            }
        } else {
            alpha = 0.0
            image = nil
        }
    }
}
