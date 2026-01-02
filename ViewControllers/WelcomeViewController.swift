//
//  WelcomeViewController.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 20/05/25.
//

import Cocoa

class WelcomeViewController: NSViewController {

    
    let config = Configuration.shared
    @IBOutlet weak var BtnCreateNewReport: HandCursorButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func BtnCreateNewReportPressed(_ sender: Any) {
        config.mainTab?.SwitchTab(screen: .CreateNewReport)
        config.createReportVC?.resetUI()
    }
}
