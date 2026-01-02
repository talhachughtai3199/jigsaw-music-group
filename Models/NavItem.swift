//
//  NavItem.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 21/05/25.
//

class NavItem: Equatable{
    static func == (lhs: NavItem, rhs: NavItem) -> Bool {
        return lhs.Title == rhs.Title
    }
    
    var Id: Int = 0
    var Title: String? = ""
    var ReportDate: Date?
    
    init(Id: Int, Title: String? = nil, ReportDate: Date? = nil) {
        self.Id = Id
        self.Title = Title
        self.ReportDate = ReportDate
    }
}
