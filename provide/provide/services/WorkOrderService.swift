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
        for wo in workOrders {
            if wo.status == "scheduled" {
                for provider in wo.providers {
                    if provider.userId == currentUser().id {
                        return wo
                    }
                }
            }
        }
        return nil
    }

    var nextWorkOrderDrivingEtaMinutes: Int!

    var inProgressWorkOrder: WorkOrder! {
        for wo in workOrders {
            if wo.status == "en_route" || wo.status == "in_progress" || wo.status == "rejected" {
                for provider in wo.providers {
                    if provider.userId == currentUser().id {
                        return wo
                    }
                }
            }
        }
        return nil
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

    func workOrderWithId(id: Int) -> WorkOrder! {
        for workOrder in workOrders {
            if workOrder.id == id {
                return workOrder
            }
        }
        return nil
    }

    func setWorkOrders(workOrders: [WorkOrder]) {
        self.workOrders = workOrders
    }

    func setWorkOrdersUsingRoute(route: Route) {
        workOrders = route.workOrders
    }

    private func setRejectedItemFlags(workOrders: [WorkOrder]) {
        for workOrder in workOrders {
            if let itemsRejected = workOrder.itemsRejected {
                for itemRejected in itemsRejected {
                    itemRejected.rejected = true
                }
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
        includeExpenses: Bool = false,
        includeSupervisors: Bool = true,
        includeProviders: Bool = true,
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
            params.updateValue("true", forKey: "exclude_routes")
        }

        if includeExpenses {
            params.updateValue("true", forKey: "include_expenses")
        }

        if includeSupervisors {
            params.updateValue("true", forKey: "include_supervisors")
        }

        if includeProviders {
            params.updateValue("true", forKey: "include_work_order_providers")
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
