//
//  ReportSchema.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 27/05/25.
//

struct ReportSchema {
    var TransactionDate = ""
    var TrackLabel = ""
    var ReleaseTitle = ""
    var TrackArtist = ""
    var TrackTitle = ""
    var ISRC = ""
    var Barcode = ""
    var Territory = ""
    var Currency = ""
    var NetPayable = "" 
    var Units = ""
    var SaleDate: String?
    var Source: String?
    var ReleaseArtist: String? 
    var ReleaseLabel: String?
    var options: Options?
}


struct SchemaColumnIndex {
    var TransactionDate = 0
    var TrackLabel = 0
    var ReleaseTitle = 0
    var TrackArtist = 0
    var TrackTitle = 0
    var ISRC = 0
    var Barcode = 0
    var Territory = 0
    var Currency = 0
    var NetPayable = 0
    var Units = 0
    var SaleDate = 0
    var Source = 0
    var ReleaseArtist = 0
    var ReleaseLabel = 0
}


struct Options {
    var skipRows = 0
    var delimiter: String?
}
