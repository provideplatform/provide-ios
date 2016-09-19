//
//  CompanyService.swift
//  provide
//
//  Created by Kyle Thomas on 2/22/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnCompaniesFetched = (_ companies: [Company]) -> ()

class CompanyService: NSObject {

    fileprivate var companies = [Company]()

    fileprivate static let sharedInstance = CompanyService()

    class func sharedService() -> CompanyService {
        return sharedInstance
    }

    func companyWithId(_ id: Int) -> Company! {
        for company in companies {
            if company.id == id {
                return company
            }
        }
        return nil
    }

    func setCompanies(_ companies: [Company]) {
        self.companies = companies
    }

    func updateCompany(_ company: Company) {
        var newCompanies = [Company]()
        for c in companies {
            if c.id == company.id {
                newCompanies.append(company)
            } else {
                newCompanies.append(c)
            }
        }
        companies = newCompanies
    }

    func fetch(_ page: Int = 1,
        rpp: Int = 10,
        companyId: Int!,
        status: String = "scheduled",
        includeCustomer: Bool = false,
        includeExpenses: Bool = false,
        includeProducts: Bool = false,
        onCompaniesFetched: OnCompaniesFetched!)
    {
        if page == 1 {
            companies = [Company]()
        }

        var params: [String: AnyObject] = [
            "page": page as AnyObject,
            "rpp": rpp as AnyObject,
            "status": status as AnyObject,
        ]

        if let companyId = companyId {
            params["company_id"] = companyId as AnyObject
        }

        ApiService.sharedService().fetchCompanies(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedCompanies = mappingResult?.array() as! [Company]

                self.companies += fetchedCompanies

                onCompaniesFetched(fetchedCompanies)
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }
}
