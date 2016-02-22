//
//  CompanyService.swift
//  provide
//
//  Created by Kyle Thomas on 2/22/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnCompaniesFetched = (companies: [Company]) -> ()

class CompanyService: NSObject {

    private var companies = [Company]()

    private static let sharedInstance = CompanyService()

    class func sharedService() -> CompanyService {
        return sharedInstance
    }

    func companyWithId(id: Int) -> Company! {
        for company in companies {
            if company.id == id {
                return company
            }
        }
        return nil
    }

    func setCompanies(companies: [Company]) {
        self.companies = companies
    }

    func updateCompany(company: Company) {
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

    func fetch(page: Int = 1,
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
            "page": page,
            "rpp": rpp,
            "status": status,
        ]

        if let companyId = companyId {
            params["company_id"] = companyId
        }

        ApiService.sharedService().fetchCompanies(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedCompanies = mappingResult.array() as! [Company]

                self.companies += fetchedCompanies

                onCompaniesFetched(companies: fetchedCompanies)
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }
}
