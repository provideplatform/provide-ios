//
//  WorkOrderService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnWorkOrdersFetched = (_ workOrders: [WorkOrder]) -> Void
typealias OnWorkOrderEtaFetched = (_ workOrder: WorkOrder, _ minutesEta: Int) -> Void

class WorkOrderService: NSObject {
    static let shared = WorkOrderService()

    var nextWorkOrderDrivingEtaMinutes: Int = 0

    weak var nextWorkOrder: WorkOrder! {
        for wo in workOrders {
            if wo.status == "scheduled" || wo.status == "pending_acceptance" {
                if wo.userId == currentUser.id {
                    return wo
                }
                for provider in wo.providers where provider.userId == currentUser.id && !wo.isCurrentProviderTimedOut {
                    return wo
                }
            }
        }
        return nil
    }

    weak var inProgressWorkOrder: WorkOrder! {
        for wo in workOrders {
            if wo.userId == currentUser.id {
                if wo.status == "awaiting_schedule"
                    || wo.status == "pending_acceptance"
                    || wo.status == "en_route"
                    || wo.status == "arriving"
                    || wo.status == "in_progress"
                    || wo.status == "timed_out" {
                    return wo
                }
            }

            if wo.status == "pending_acceptance"
                || wo.status == "en_route"
                || wo.status == "arriving"
                || wo.status == "in_progress"
                || wo.status == "rejected" {

                for provider in wo.providers where provider.userId == currentUser.id && !wo.isCurrentProviderTimedOut {
                    return wo
                }
            }
        }
        return nil
    }

    private var workOrders = [WorkOrder]()

    func workOrderWithId(_ id: Int) -> WorkOrder? {
        for workOrder in workOrders where workOrder.id == id {
            return workOrder
        }
        return nil
    }

    func setWorkOrders(_ workOrders: [WorkOrder]) {
        self.workOrders = workOrders
    }

    func updateWorkOrder(_ workOrder: WorkOrder) {
        var newWorkOrders = [WorkOrder]()
        for wo in workOrders {
            if wo.id == workOrder.id {
                newWorkOrders.append(workOrder)
            } else {
                newWorkOrders.append(wo)
            }
        }
        workOrders = newWorkOrders
    }

    func fetch(_ page: Int = 1,
               rpp: Int = 10,
               status: String = "scheduled",
               today: Bool = false,
               includeProviders: Bool = true,
               onWorkOrdersFetched: OnWorkOrdersFetched!) {

        var params: [String: Any] = [
            "page": page,
            "rpp": rpp,
            "status": status,
        ]

        if today {
            let today = Date()
            let midnightToday = today.atMidnight.utcString
            let midnightTomorrow = today.atMidnight.addingTimeInterval(60 * 60 * 24).utcString

            params["date_range"] = "\(midnightToday)..\(midnightTomorrow)"
        }

        if includeProviders {
            params["include_work_order_providers"] = "true"
        }

        ApiService.shared.fetchWorkOrders(params, onSuccess: { statusCode, mappingResult in
            let fetchedWorkOrders = mappingResult?.array() as! [WorkOrder]
            self.workOrders += fetchedWorkOrders
            onWorkOrdersFetched(fetchedWorkOrders)
        }, onError: { error, statusCode, responseString in
            logWarn("Failed to retrieve work orders; \(error)")
        })
    }

    func fetchNextWorkOrderDrivingEtaFromCoordinate(_ coordinate: CLLocationCoordinate2D, onWorkOrderEtaFetched: @escaping OnWorkOrderEtaFetched) {
        if let workOrder = nextWorkOrder {
            DirectionService.shared.fetchDrivingEtaFromCoordinate(coordinate, toCoordinate: workOrder.coordinate) { minutesEta in
                self.nextWorkOrderDrivingEtaMinutes = minutesEta
                onWorkOrderEtaFetched(workOrder, minutesEta)
            }
        }
    }

    private func fetchInProgressWorkOrderDrivingEtaFromCoordinate(_ coordinate: CLLocationCoordinate2D, onWorkOrderEtaFetched: @escaping OnWorkOrderEtaFetched) {
        if let workOrder = inProgressWorkOrder {
            DirectionService.shared.fetchDrivingEtaFromCoordinate(coordinate, toCoordinate: workOrder.coordinate) { minutesEta in
                self.nextWorkOrderDrivingEtaMinutes = minutesEta
                onWorkOrderEtaFetched(workOrder, minutesEta)
            }
        }
    }

    func fetchInProgressWorkOrderDrivingDirectionsFromCoordinate(_ coordinate: CLLocationCoordinate2D, onDrivingDirectionsFetched: @escaping OnDrivingDirectionsFetched) {
        if let workOrder = inProgressWorkOrder {
            DirectionService.shared.fetchDrivingDirectionsFromCoordinate(coordinate, toCoordinate: workOrder.coordinate) { directions in
                onDrivingDirectionsFetched(directions)
            }
        }
    }

    func setInProgressWorkOrderRegionMonitoringCallbacks(_ onDidEnterRegion: @escaping VoidBlock, onDidExitRegion: @escaping VoidBlock) {
        if let workOrder = inProgressWorkOrder {
            LocationService.shared.unregisterRegionMonitor(workOrder.regionIdentifier)

            let overlay = MKCircle(center: workOrder.coordinate, radius: workOrder.regionMonitoringRadius)
            LocationService.shared.monitorRegionWithCircularOverlay(overlay, identifier: workOrder.regionIdentifier, onDidEnterRegion: onDidEnterRegion, onDidExitRegion: onDidExitRegion)
        }
    }
}
