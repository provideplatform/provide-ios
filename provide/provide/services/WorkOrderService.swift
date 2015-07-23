//
//  WorkOrderService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnWorkOrdersFetched = (workOrders: [WorkOrder]) -> ()
typealias OnWorkOrderEtaFetched = (workOrder: WorkOrder, minutesEta: Int) -> ()

class WorkOrderService: NSObject {

    var nextWorkOrder: WorkOrder! {
        return workOrders.findFirst { $0.status == "scheduled" }
    }

    var nextWorkOrderDrivingEtaMinutes: Int!

    var inProgressWorkOrder: WorkOrder! {
        return workOrders.findFirst { $0.status == "en_route" || $0.status == "in_progress" } // can be en_route or in_progress
    }

    private var workOrders = [WorkOrder]() {
        didSet {
            setRejectedItemFlags(workOrders)
        }
    }

    private static let sharedInstance = WorkOrderService()

    class func sharedService() -> WorkOrderService {
        return sharedInstance
    }

    func setWorkOrders(workOrders: [WorkOrder]) {
        self.workOrders = workOrders
    }

    func setWorkOrdersUsingRoute(route: Route) {
        workOrders = route.workOrders
    }

    private func setRejectedItemFlags(workOrders: [WorkOrder]) {
        for workOrder in workOrders {
            var itemsRejected = workOrder.itemsRejected
            for itemRejected in itemsRejected {
                itemRejected.rejected = true
            }
        }
    }

    func updateWorkOrder(workOrder: WorkOrder) {
        if let currentRoute = RouteService.sharedService().currentRoute {
            currentRoute.updateWorkOrder(workOrder)
        }

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

    func fetch(page: Int = 1,
        rpp: Int = 10,
        status: String = "scheduled",
        today: Bool = false,
        excludeRoutes: Bool = true,
        onWorkOrdersFetched: OnWorkOrdersFetched!)
    {
        var params: [String: AnyObject] = [
            "page": page,
            "rpp": rpp,
            "status": status,
        ]

        if today {
            let today = NSDate()
            let midnightToday = today.atMidnight.utcString
            let midnightTomorrow = today.atMidnight.dateByAddingTimeInterval(60 * 60 * 24).utcString

            params["date_range"] = "\(midnightToday)..\(midnightTomorrow)"
        }

        if excludeRoutes {
            params.setObject("true", forKey: "exclude_routes")
        }

        ApiService.sharedService().fetchWorkOrders(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedWorkOrders = mappingResult.array() as! [WorkOrder]
                self.setRejectedItemFlags(fetchedWorkOrders)

                self.workOrders += fetchedWorkOrders

                onWorkOrdersFetched(workOrders: fetchedWorkOrders)
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }

    func fetchNextWorkOrderDrivingEtaFromCoordinate(coordinate: CLLocationCoordinate2D, onWorkOrderEtaFetched: OnWorkOrderEtaFetched) {
        if let workOrder = nextWorkOrder {
            DirectionService.sharedService().fetchDrivingEtaFromCoordinate(coordinate, toCoordinate: workOrder.coordinate) { minutesEta in
                self.nextWorkOrderDrivingEtaMinutes = minutesEta
                onWorkOrderEtaFetched(workOrder: workOrder, minutesEta: minutesEta)
            }
        }
    }

    func fetchInProgressWorkOrderDrivingEtaFromCoordinate(coordinate: CLLocationCoordinate2D, onWorkOrderEtaFetched: OnWorkOrderEtaFetched) {
        if let workOrder = inProgressWorkOrder {
            DirectionService.sharedService().fetchDrivingEtaFromCoordinate(coordinate, toCoordinate: workOrder.coordinate) { minutesEta in
                self.nextWorkOrderDrivingEtaMinutes = minutesEta
                onWorkOrderEtaFetched(workOrder: workOrder, minutesEta: minutesEta)
            }
        }
    }

    func fetchInProgressWorkOrderDrivingDirectionsFromCoordinate(coordinate: CLLocationCoordinate2D, onDrivingDirectionsFetched: OnDrivingDirectionsFetched) {
        if let workOrder = inProgressWorkOrder {
            DirectionService.sharedService().fetchDrivingDirectionsFromCoordinate(coordinate, toCoordinate: workOrder.coordinate) { directions in
                onDrivingDirectionsFetched(directions: directions)
            }
        }
    }

    func setInProgressWorkOrderRegionMonitoringCallbacks(onDidEnterRegion: VoidBlock, onDidExitRegion: VoidBlock) {
        if let workOrder = inProgressWorkOrder {
            LocationService.sharedService().unregisterRegionMonitor(workOrder.regionIdentifier)

            let overlay = MKCircle(centerCoordinate: workOrder.coordinate, radius: workOrder.regionMonitoringRadius)
            LocationService.sharedService().monitorRegionWithCircularOverlay(overlay,
                                                                           identifier: workOrder.regionIdentifier,
                                                                           onDidEnterRegion: onDidEnterRegion,
                                                                           onDidExitRegion: onDidExitRegion)
        }
    }
}
