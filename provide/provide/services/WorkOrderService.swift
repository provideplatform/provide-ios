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
typealias OnWorkOrderDrivingDirectionsFetched = (workOrder: WorkOrder, directions: Directions) -> ()

class WorkOrderService: NSObject {

    var nextWorkOrder: WorkOrder! {
        get {
            var workOrder: WorkOrder!
            var i = 0
            while workOrder == nil && i <= workOrders.count - 1 {
                let wo = workOrders[i] as WorkOrder
                if wo.status == "scheduled" {
                    workOrder = wo
                }

                i++
            }

            return workOrder
        }
    }
    var nextWorkOrderDrivingEtaMinutes: Int!

    var inProgressWorkOrder: WorkOrder! {
        get {
            var workOrder: WorkOrder!
            var i = 0
            while workOrder == nil && i <= workOrders.count - 1 {
                let wo = workOrders[i] as WorkOrder
                if wo.status == "en_route" || wo.status == "in_progress" { // can be en_route or in_progress
                    workOrder = wo
                }

                i++
            }
            
            return workOrder
        }
    }

    private var workOrders = [WorkOrder]()

    required override init() {
        super.init()
    }

    class func sharedService() -> WorkOrderService {
        struct Static {
            static let instance = WorkOrderService()
        }
        return Static.instance
    }

    func setWorkOrders(workOrders: [WorkOrder]!) {
        self.workOrders = workOrders
    }

    func setWorkOrdersUsingRoute(route: Route!) {
        workOrders = route.workOrders as! [WorkOrder]
    }

    func fetch(page: Int = 1,
               rpp: Int = 10,
               status: String = "scheduled",
               today: Bool = false,
               onWorkOrdersFetched: OnWorkOrdersFetched!) {

        let params = NSMutableDictionary(dictionary: [
                "page": page,
                "rpp": rpp,
                "status": status
            ])

        if today == true {
            let today = NSDate()
            let midnightToday = today.atMidnight.utcString
            let midnightTomorrow = today.atMidnight.dateByAddingTimeInterval(60 * 60 * 24).utcString

            params.setObject("\(midnightToday)..\(midnightTomorrow)", forKey: "date_range")
        }

        ApiService.sharedService().fetchWorkOrders(params,
            onSuccess: { (statusCode, mappingResult) -> () in
                var fetchedWorkOrders = [WorkOrder]()

                for workOrder in mappingResult.array() as! [WorkOrder] {
                    self.workOrders.append(workOrder)
                    fetchedWorkOrders.append(workOrder)
                }

                if onWorkOrdersFetched != nil {
                    onWorkOrdersFetched(workOrders: fetchedWorkOrders)
                }
            }, onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }

    func fetchNextWorkOrderDrivingEtaFromCoordinate(coordinate: CLLocationCoordinate2D, onWorkOrderEtaFetched: OnWorkOrderEtaFetched) {
        if let workOrder = nextWorkOrder {
            DirectionService.sharedService().fetchDrivingEtaFromCoordinate(coordinate, toCoordinate: workOrder.coordinate, onEtaFetched: { (minutesEta) -> () in
                self.nextWorkOrderDrivingEtaMinutes = minutesEta
                onWorkOrderEtaFetched(workOrder: workOrder, minutesEta: minutesEta)
            })
        }
    }

    func fetchInProgressWorkOrderDrivingEtaFromCoordinate(coordinate: CLLocationCoordinate2D, onWorkOrderEtaFetched: OnWorkOrderEtaFetched) {
        if let workOrder = inProgressWorkOrder {
            DirectionService.sharedService().fetchDrivingEtaFromCoordinate(coordinate, toCoordinate: workOrder.coordinate, onEtaFetched: { (minutesEta) -> () in
                self.nextWorkOrderDrivingEtaMinutes = minutesEta
                onWorkOrderEtaFetched(workOrder: workOrder, minutesEta: minutesEta)
            })
        }
    }

    func fetchInProgressWorkOrderDrivingDirectionsFromCoordinate(coordinate: CLLocationCoordinate2D, onWorkOrderDrivingDirectionsFetched: OnWorkOrderDrivingDirectionsFetched) {
        if let workOrder = inProgressWorkOrder {
            DirectionService.sharedService().fetchDrivingDirectionsFromCoordinate(coordinate, toCoordinate: workOrder.coordinate, onDrivingDirectionsFetched: { (directions) -> () in
                onWorkOrderDrivingDirectionsFetched(workOrder: workOrder, directions: directions)
            })
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
