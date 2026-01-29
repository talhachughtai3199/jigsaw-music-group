//
//  AssignedFilesCollectionViewItem.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 22/05/25.
//

import Cocoa

class SummaryCollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var LblCurrency: NSTextField!
    @IBOutlet weak var LblAmount: NSTextField!
   
    var item: SummaryDetails?
    let config = Configuration.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func setSourceItem(selectedItem: SummaryDetails){
        self.item = selectedItem
        if let safeItem = self.item{
            LblCurrency.stringValue = safeItem.currency ?? ""
            LblAmount.stringValue = "\(safeItem.currencySymbol ?? "") \(String(format: "%.2f", safeItem.amount ?? 0.0))"
            LblAmount.toolTip = "\(safeItem.amount ?? 0.0)" 
        }
    }
}
