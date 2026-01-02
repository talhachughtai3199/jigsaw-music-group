//
//  AvailableServices..swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 27/05/25.
//

class Services{
    
    private(set) var services = [String]()
    private(set) var schemas = Dictionary<String, ReportSchema>()
    
    static let shared = Services()
    private init(){}
    
    func getServices(){
        if(!services.isEmpty) {
            services.removeAll()
        }
        
        let tmpItems = ["Anghami",
                       "AWA",
                       "Boomplay",
                       "Deezer",
                       "Facebook",
                       "iHeart",
                       "Mixcloud",
                       "Peloton",
                       "KBOX",
                       "NetEase Cloud Music",
                       "Pandora",
                       "Resso",
                       "Soundcloud",
                       "Snap",
                       "Spotify",
                       "Trebel",
                       "Tiktok",
                       "AudioSalad",
                       "Soundtrack Your Brand",
                       "Canva",
                        "Tencent"].sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}
        
        services.append(contentsOf: tmpItems)
    }
    
    func getBeautifyServiceNameFromFile(_ filename: String) -> String? {
        let normalizedFilename = filename
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
        if normalizedFilename.contains("track for streaming") {
            return "Spotify"
        }
        if normalizedFilename.contains("_tb") {
            return "Deezer"
        }
        for service in services {
            let normalizedService = service.lowercased()

            if normalizedFilename.contains(normalizedService) {
                return service
            }
        }

        return nil
    }
    
    func getBeautifyServiceName(_ serviceName: String) -> String {
        switch (serviceName) {
        case "ang-anghami":
            return "Anghami"
        case "awa-awa":
            return "AWA"
        case "boo-boomplay":
            return "Boomplay"
        case "dzr-deezer":
            return "Deezer"
        case "fbk-facebook":
            return "Facebook"
        case "iht-iheart":
            return "iHeart"
        case "mxc-mixcloud":
            return "Mixcloud"
        case "plt-peloton":
            return "Peloton"
        case "kbx-kkbox":
            return "KBOX"
        case "ncm-netease-cloud-music":
            return "NetEase Cloud Music"
        case "stb-soundtrack-your-brand":
            return "Soundtrack Your Brand"
        case "audiosalad":
            return "AudioSalad"
        case "pnd-pandora":
            return "Pandora"
        case "res-resso":
            return "Resso"
        case "scu-soundcloud":
            return "Soundcloud"
        case "snp-snap":
            return "Snap"
        case "spo-spotify":
            return "Spotify"
        case "tbl-trebel":
            return "Trebel"
        case "tiktok":
            return "Tiktok"
        case "tme-tencent":
            return "Tencent"
        case "cnv-canva":
            return "Canva"
        default:
            return ""
        }
    }
    
    
    func getServiceSchema(){
        if(!schemas.isEmpty){
            schemas.removeAll()
        }
        
        schemas["Anghami"] = ReportSchema(
            TransactionDate: "End Date",
            TrackLabel: "Label Name'",
            ReleaseTitle: "Release Title",
            TrackArtist: "Artist Name",
            TrackTitle: "Track Title",
            ISRC: "ISRC",
            Barcode : "Release ID",
            Territory : "Country of Sale",
            Currency : "Currency",
            NetPayable : "Total Payable",
            Units : "Quantity")
        
        schemas["AWA"] = ReportSchema(
            TransactionDate : "report_date",
            TrackLabel : "label_id",
            ReleaseTitle : "release_title",
            TrackArtist : "Artist",
            TrackTitle : "Track_title",
            ISRC : "isrc_id",
            Barcode : "release_id",
            Territory : "territory_code",
            Currency : "",
            NetPayable : "Total in USD",
            Units : "quantity")
        
        
        schemas["Boomplay"] = ReportSchema(
            TransactionDate : "End_Date",
            TrackLabel : "Label_Name",
            ReleaseTitle : "Release_Title",
            TrackArtist : "Artist_Name",
            TrackTitle : "Track_Title",
            ISRC : "ISRC",
            Barcode : "Release_ID",
            Territory : "Country_Of_Sale",
            Currency : "DSP_currency",
            NetPayable : "Total_Payable_USD",
            Units : "Quantity",
            options: Options(skipRows: 0, delimiter: "\t"))
        
        schemas["Deezer"] = ReportSchema(
            TransactionDate : "end_report",
            TrackLabel : "label",
            ReleaseTitle : "album",
            TrackArtist : "artist",
            TrackTitle : "title",
            ISRC : "isrc",
            Barcode : "upc",
            Territory : "country",
            Currency : "",
            NetPayable : "royalties",
            Units : "nb_of_plays")
        
        schemas["Facebook"] = ReportSchema(
            TransactionDate : "end_date",
            TrackLabel : "",
            ReleaseTitle : "",
            TrackArtist : "track_artist",
            TrackTitle : "track_title",
            ISRC : "elected_isrc",
            Barcode : "",
            Territory : "country",
            Currency : "",
            NetPayable : "usd_payable",
            Units : "event_count_including_estimates")
        
        schemas["iHeart"] = ReportSchema(
            TransactionDate : "ReportEndDt",
            TrackLabel : "Label Code",
            ReleaseTitle : "Album Name",
            TrackArtist : "Artist Name",
            TrackTitle : "Track Name",
            ISRC : "ISRC",
            Barcode : "Barcode",
            Territory : "",
            Currency : "",
            NetPayable : "Price",
            Units : "event_count_including_estimates",
            options: Options(skipRows: 0, delimiter: "\t"))
 
        schemas["Mixcloud"] = ReportSchema(
            TransactionDate : "End_Date",
            TrackLabel : "Label_Name",
            ReleaseTitle : "Release_Title",
            TrackArtist : "Artist_Name",
            TrackTitle : "Track_Title",
            ISRC : "ISRC",
            Barcode : "",
            Territory : "Country_Of_Sale",
            Currency : "Base_Currency",
            NetPayable : "Total_Payable_USD",
            Units : "Quantity")
        
        
        schemas["Peloton"] = ReportSchema(
            TransactionDate : "End_Date Tier",
            TrackLabel : "Label_Name",
            ReleaseTitle : "Release_Title",
            TrackArtist : "Artist_Name",
            TrackTitle : "Track_Title",
            ISRC : "ISRC",
            Barcode : "Release_ID",
            Territory : "Country",
            Currency : "Currency",
            NetPayable : "Total_Payable_USD",
            Units : "Quantity")
        
        schemas["KBOX"] = ReportSchema(
            TransactionDate : "Date",
            TrackLabel : "Label",
            ReleaseTitle : "Album Name",
            TrackArtist : "Artist Name",
            TrackTitle : "Track Name",
            ISRC : "ISRC",
            Barcode : "Barcode",
            Territory : "Territory",
            Currency : "Currency",
            NetPayable : "USD Payable",
            Units : "Number of Transactions")
        
        
        schemas["NetEase Cloud Music"] = ReportSchema(
            TransactionDate : "End_Date",
            TrackLabel : "Label_Name",
            ReleaseTitle : "Release_Title",
            TrackArtist : "Artist_Name",
            TrackTitle : "Track_Title",
            ISRC : "ISRC",
            Barcode : "Release_ID",
            Territory : "Country_Of_Sale",
            Currency : "Statement_Currency",
            NetPayable : "USD_Amount",
            Units : "Quantity_ Streams")
        
        schemas["Pandora"] = ReportSchema(
            TransactionDate : "SalesDate",
            TrackLabel : "LabelName",
            ReleaseTitle : "ResourceTitle",
            TrackArtist : "Contributors",
            TrackTitle : "ReleaseTitle",
            ISRC : "ISRC",
            Barcode : "Barcode",
            Territory : "TerritoryCode",
            Currency : "CurrencyCode",
            NetPayable : "EffectiveRoyaltyRate",
            Units : "NumberOfConsumerSalesGross",
            options: Options(skipRows: 2)
        )
        
        schemas["Resso"] = ReportSchema(
            TransactionDate : "reporting_period_end",
            TrackLabel : "label_name",
            ReleaseTitle : "release_title",
            TrackArtist : "artist_name",
            TrackTitle : "track_title",
            ISRC : "isrc",
            Barcode : "Barcode",
            Territory : "country",
            Currency : "currency",
            NetPayable : "total_payable_usd",
            Units : "number_of_streams")
        
        schemas["Soundcloud"] = ReportSchema(
            TransactionDate : "Reporting Period",
            TrackLabel : "Label Name",
            ReleaseTitle : "Album Name",
            TrackArtist : "Artist Name",
            TrackTitle : "Track Name",
            ISRC : "ISRC",
            Barcode : "Barcode",
            Territory : "Territory",
            Currency : "Revenue Currency",
            NetPayable : "Total Revenue",
            Units : "Total Plays")
        
        schemas["Snap"] = ReportSchema(
            TransactionDate : "End_Date",
            TrackLabel : "Label_Name",
            ReleaseTitle : "Release_Title",
            TrackArtist : "Artist_Name",
            TrackTitle : "Track_Title",
            ISRC : "ISRC",
            Barcode : "Release_Id",
            Territory : "Country",
            Currency : "",
            NetPayable : "Total_Payable_USD",
            Units : "Quantity_Views")
        
        schemas["Spotify"] = ReportSchema(
            TransactionDate : "End date",
            TrackLabel : "Label",
            ReleaseTitle : "Album name",
            TrackArtist : "Artist name",
            TrackTitle : "Track name",
            ISRC : "ISRC",
            Barcode : "UPC",
            Territory : "Country",
            Currency : "Payable currency",
            NetPayable : "Payable",
            Units : "Quantity",
            options: Options(skipRows: 4, delimiter: "\t"))
        
        schemas["Trebel"] = ReportSchema(
            TransactionDate : "End_Date",
            TrackLabel : "Label_Name",
            ReleaseTitle : "Release_Title",
            TrackArtist : "Artist_Name",
            TrackTitle : "Track_Title",
            ISRC : "ISRC",
            Barcode : "Release_ID",
            Territory : "Territory",
            Currency : "Currency",
            NetPayable : "Total_Payable_USD",
            Units : "Quantity")
        
        schemas["Tiktok"] = ReportSchema(
            TransactionDate : "report_end_date",
            TrackLabel : "label_name",
            ReleaseTitle : "album",
            TrackArtist : "artist",
            TrackTitle : "song_title",
            ISRC : "isrc",
            Barcode : "product_code",
            Territory : "territory",
            Currency : "statement_currency",
            NetPayable : "statement_amount",
            Units : "video_views")
        
        schemas["AudioSalad"] = ReportSchema(
            TransactionDate : "Transaction Date",
            TrackLabel : "Track Label",
            ReleaseTitle : "Release Title",
            TrackArtist : "Track Artist",
            TrackTitle : "Track Title",
            ISRC : "ISRC",
            Barcode : "Barcode",
            Territory : "Territory",
            Currency : "Currency",
            NetPayable : "Net Payable",
            Units : "Units",
            SaleDate: "Sale Date",
            Source: "Source",
            ReleaseArtist: "Release Artist",
            ReleaseLabel: "Release Label"
        )
        
        schemas["Soundtrack Your Brand"] = ReportSchema(
            TransactionDate : "End_Date",
            TrackLabel : "",
            ReleaseTitle : "Album_Title",
            TrackArtist : "Track_Artist",
            TrackTitle : "Track_Title",
            ISRC : "ISRC",
            Barcode : "UPC",
            Territory : "Country_Of_Sale",
            Currency : "Statement_Currency",
            NetPayable : "Statement_Amount",
            Units : "Number_Of_Transactions",
            SaleDate: "Start_Date",
            ReleaseArtist: "Album_Artist",
            ReleaseLabel: "Label_Name"
        )
        
        schemas["Tencent"] = ReportSchema(
            TransactionDate : "End_Date",
            TrackLabel : "",
            ReleaseTitle : "Release_Title",
            TrackArtist : "Artist_Name",
            TrackTitle : "Track_Title",
            ISRC : "ISRC",
            Barcode : "",
            Territory : "Country_Of_Sale",
            Currency : "Statement_Currency",
            NetPayable : "Total_Payable",
            //NetPayable : "Total_Payable_USD",
            Units : "Quantity",
            SaleDate: "Start_Date",
            Source: "Service",
            ReleaseLabel: "Label_Name"
        )
        
        schemas["Canva"] = ReportSchema(
            TransactionDate : "End_Date",
            TrackLabel : "",
            ReleaseTitle : "Release_Title",
            TrackArtist : "Artist_Name",
            TrackTitle : "Track_Title",
            ISRC : "ISRC",
            Barcode : "UPC",
            Territory : "Country",
            Currency : "Currency",
            NetPayable : "Total_Payable",
            Units : "",
            SaleDate: "Start_Date",
            Source: "Service",
            ReleaseLabel: "Label_Name"
        )
        
    }
}
