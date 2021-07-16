//
//  DetailOrderFragment.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation
@testable import Graphene

struct OrderDetailFragment: Fragment {

    func fragmentQuery(_ builder: QueryContainer<Order>) {
        builder += .id
        builder += .number
        builder += .createdAt
        builder += .firstName
        builder += .lastName
        builder += .externalId
        builder += .updateStateDate
        builder += .manager { manager in
            manager += .id
            manager += .nickName
            manager += .enabled
            manager += .lastLogin
        }
        builder += .orderType { orderType in
            orderType += .id
            orderType += .name
            orderType += .active
        }
        builder += .contragent { contragent in
            contragent += .contragentType
            contragent += .INN
            contragent += .KPP
            contragent += .legalName
            contragent += .legalAddress
            contragent += .OKPO
            contragent += .OGRNIP
            contragent += .OGRN
        }
        builder += .payments { payment in
            payment += .id
            payment += .amount
            payment += .paidAt
            payment += .comment
            payment += .type { paymentType in
                paymentType += .id
                paymentType += .name
                paymentType += .active
                paymentType += .description
            }
            payment += .status { paymentStatus in
                paymentStatus += .id
                paymentStatus += .name
                paymentStatus += .active
                paymentStatus += .defaultForApi
                paymentStatus += .ordering
                paymentStatus += .paymentTypes({ paymentType in
                    paymentType += .id
                })
            }
        }
        builder += .unionCustomer({ (unionCustomer) in
            unionCustomer += .id
            unionCustomer += .createdAt
            unionCustomer += .onCustomer({ corpCustomer in
                corpCustomer += .lastName
            })
            unionCustomer += .onCorporateCustomer({ (query) in
                query += .nickName
            })
        })
        builder += .orderProducts(first: 10, after: nil, { builder in
            builder += .totalCount
            builder += .pageInfo
            builder += .edges({ (orderProduct) in
                orderProduct += .id
                orderProduct += .initialPrice
            })
        })
    }

}
