//
//  MainSplitViewController.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 21/05/25.
//

import Cocoa

class MainSplitViewController: NSSplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        initializeSettings()
    }
    
    func initializeSettings(){
        
        if let navBar = self.splitViewItems.first {
            //prevent side pane from resize
            navBar.canCollapse = false
            navBar.holdingPriority = .defaultLow
            navBar.maximumThickness = 180
            navBar.minimumThickness = 180
        }
    }
}
