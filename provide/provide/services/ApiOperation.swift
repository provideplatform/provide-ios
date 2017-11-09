//
//  ApiOperation.swift
//  provide
//
//  Created by Kyle Thomas on 11/2/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import Foundation

class ApiOperation: Operation {

    private let initialBackoffTimeout: TimeInterval = 0.1
    private let maximumBackoffTimeout: TimeInterval = 60.0

    private var attempts = 0

    private var backoffTimeout: TimeInterval!

    private var httpMethod: String {
        return request.httpMethod!
    }

    var isIdempotent: Bool {
        return ["DELETE", "GET", "HEAD", "PATCH", "PUT"].contains(httpMethod)
    }

    private var params: [String: Any]? {
        if ["PATCH", "POST", "PUT"].contains(httpMethod) {
            if let body = request.httpBody, let params = try? JSONSerialization.jsonObject(with: body, options: []) as? [String: Any] {
                return params
            }
        }
        return nil
    }

    private var onError: OnError!

    private var onSuccess: OnSuccess!

    private var request: URLRequest!

    private var response: HTTPURLResponse? {
        return task.response as? HTTPURLResponse
    }

    private var responseDescriptor: RKResponseDescriptor?

    var responseHeaders: [AnyHashable: Any]? {
        return response?.allHeaderFields
    }

    private var responseEntity: Data?

    private var responseString: String? {
        return responseEntity.flatMap { String(data: $0, encoding: .utf8) }
    }

    private var url: URL!

    private var statusCode: Int {
        return response?.statusCode ?? -1
    }

    private var task: URLSessionDataTask!

    private weak var session: URLSession!

    override var isAsynchronous: Bool {
        return true
    }

    private var isCancelledObserver: NSKeyValueObservation!

    private var _executing = false
    override var isExecuting: Bool {
        return _executing
    }

    private var _finished = false
    override var isFinished: Bool {
        return _finished
    }

    private var _ready = true
    override var isReady: Bool {
        return _ready
    }

    override var description: String {
        return "\(name!): \(url!)"
    }

    convenience init(session: URLSession, request: URLRequest, responseDescriptor: RKResponseDescriptor?, onSuccess: OnSuccess!, onError: OnError!) {
        self.init()

        self.session = session
        self.request = request
        self.responseDescriptor = responseDescriptor
        self.url = request.url
        self.onSuccess = onSuccess
        self.onError = onError

        backoffTimeout = initialBackoffTimeout

        var mutableSelf = self
        withUnsafePointer(to: &mutableSelf) {
            mutableSelf.name = "ApiOperation[\($0)]"
        }

        isCancelledObserver = observe(\.isCancelled, options: [.new]) { [weak self] _, change in
            if change.newValue ?? false {
                self?.task?.cancel()
                self?.finish()
            }
        }
    }

    override func start() {
        if !isExecuting {
            _ready = false
            _executing = true
            _finished = false
        } else {
            logWarn("Attempted to start API operation \(self) while it was executing")
            return
        }

        apiCall()
    }

    private func apiCall() {
        if isCancelled {
            finish()
            return
        }

        attempts += 1
        logInfo("Dispatching API operation \(self) (attempt #\(attempts)")

        let startDate = Date()
        task = session.dataTask(with: request) { [weak self] data, response, error in
            let execTimeMillis: Double = (NSDate().timeIntervalSince(startDate) * 1000.0)
            let statusCode = self?.statusCode ?? -1
            self?.responseEntity = data

            if statusCode < 400 && error == nil {
                self?.onOperationSucceeded(execTimeMillis: execTimeMillis)
            } else {
                self?.onOperationFailed(execTimeMillis: execTimeMillis, error: error)
            }

            self?.finish()
        }

        task.resume()
    }

    private func finish() {
        if isExecuting || isCancelled {
            _executing = false
            _finished = true

            isCancelledObserver?.invalidate()

            logInfo("API operation finished executing: \(self)")
        }
    }

    override func cancel() {
        super.cancel()

        task?.cancel()
        finish()

        logInfo("API operation canceled: \(self)")
        AnalyticsService.shared.track("API Operation Canceled", properties: [
            "operation": self.description,
            "attempts": attempts,
            "path": url.path,
            "query": url.query ?? "",
            "statusCode": statusCode,
            "params": params as Any,
        ])
    }

    private func onOperationSucceeded(execTimeMillis: Double) {
        let statusCode = self.statusCode
        let contentLength = Int64(responseEntity?.count ?? 0)

        logmoji("✅", "\(statusCode): \(request.url!) (\(contentLength)-byte response); took \(execTimeMillis)ms")
        AnalyticsService.shared.track("API Operation Succeeded", properties: [
            "operation": self.description,
            "attempts": attempts,
            "path": url.path,
            "query": url.query ?? "",
            "statusCode": statusCode,
            "contentLength": contentLength,
            "params": params as Any,
            "execTimeMillis": execTimeMillis,
        ])

        if let mappingOperation = RKObjectResponseMapperOperation(request: request, response: response, data: responseEntity, responseDescriptors: [responseDescriptor as Any]) {
            mappingOperation.setDidFinishMappingBlock { [weak self] mappingResult, error in
                if let strongSelf = self {
                    if ProcessInfo.processInfo.environment["WRITE_JSON_RESPONSES"] != nil {
                        JSONResponseWriter.writeResponseToFile(strongSelf.responseString!, for: strongSelf.request!)
                    }

                    DispatchQueue.main.async { [weak self] in
                        self?.onSuccess?(statusCode, mappingResult)
                    }
                }
            }
            mappingOperation.start()
        }
    }

    private func onOperationFailed(execTimeMillis: Double, error: Error?) {
        let receivedResponse = responseEntity != nil
        let contentLength = Int64(responseEntity?.count ?? 0)

        if receivedResponse {
            backoffTimeout = initialBackoffTimeout

            AnalyticsService.shared.track("API Operation Failed", properties: [
                "operation": self.description,
                "attempts": attempts,
                "path": url.path,
                "query": url.query ?? "",
                "statusCode": statusCode,
                "contentLength": contentLength,
                "params": params as Any,
                "execTimeMillis": execTimeMillis,
            ])

            if statusCode == 401 {
                if request.url?.baseURL?.absoluteString == CurrentEnvironment.baseUrlString {
                    KTNotificationCenter.post(name: .ApplicationShouldForceLogout)
                }
            }

            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.onError?((error as NSError?) ?? NSError(), strongSelf.statusCode, strongSelf.responseString ?? "{}")
            }
        } else if let err = error as NSError? {
            logError(err)
            AnalyticsService.shared.track("API Operation Failed", properties: [
                "operation": self.description,
                "attempts": attempts,
                "path": url.path,
                "query": url.query ?? "",
                "error": err.localizedDescription,
                "code": err.code,
                "params": params as Any,
                "execTimeMillis": execTimeMillis,
            ])

            if ReachabilityService.shared.reachability.isReachable() {
                DispatchQueue.main.async {
                    NotificationService.shared.presentStatusBarNotificationWithTitle("API request failed... (\(err.localizedDescription))", style: .warning)
                }
            }

            let deadline = DispatchTime.now() + Double(Int64(backoffTimeout * Double(NSEC_PER_SEC)))
            backoffTimeout = backoffTimeout > maximumBackoffTimeout ? initialBackoffTimeout : backoffTimeout * 2
            DispatchQueue.global(qos: DispatchQoS.default.qosClass).asyncAfter(deadline: deadline) { [weak self] in
                self?.responseEntity = nil
                self?.task = nil
                self?.apiCall()
            }


        }
    }
}
