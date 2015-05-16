//
//  RKHTTPRequestOperationExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

extension RKHTTPRequestOperation {

    public override func connection(connection: NSURLConnection, willSendRequest request: NSURLRequest, redirectResponse response: NSURLResponse?) -> NSURLRequest? {
        if response != nil {
            return nil
        }

        return request
    }
    
}
