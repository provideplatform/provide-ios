//
//  JobService.swift
//  provide
//
//  Created by Kyle Thomas on 1/5/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnJobsFetched = (jobs: [Job]) -> ()

class JobService: NSObject {

    private var jobs = [Job]()

    private static let sharedInstance = JobService()

    class func sharedService() -> JobService {
        return sharedInstance
    }

    func jobWithId(id: Int) -> Job! {
        for job in jobs {
            if job.id == id {
                return job
            }
        }
        return nil
    }

    func setJobs(jobs: [Job]) {
        self.jobs = jobs
    }

    func updateJob(job: Job) {
        var newJobs = [Job]()
        for j in jobs {
            if j.id == job.id {
                newJobs.append(job)
            } else {
                newJobs.append(j)
            }
        }
        jobs = newJobs
    }

    func fetch(page: Int = 1,
        rpp: Int = 10,
        companyId: Int!,
        status: String = "scheduled",
        includeCustomer: Bool = false,
        includeExpenses: Bool = false,
        includeProducts: Bool = false,
        onJobsFetched: OnJobsFetched!)
    {
        if page == 1 {
            jobs = [Job]()
        }
        
        var params: [String: AnyObject] = [
            "page": page,
            "rpp": rpp,
            "status": status,
        ]

        if let companyId = companyId {
            params["company_id"] = companyId
        }

        if includeCustomer {
            params.updateValue("true", forKey: "include_customer")
        }

        if includeExpenses {
            params.updateValue("true", forKey: "include_expenses")
        }

        if includeProducts {
            params.updateValue("true", forKey: "include_products")
        }

        ApiService.sharedService().fetchJobs(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedJobs = mappingResult.array() as! [Job]

                self.jobs += fetchedJobs

                onJobsFetched(jobs: fetchedJobs)
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }
}
