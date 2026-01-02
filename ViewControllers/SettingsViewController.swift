//
//  SettingsViewController.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 26/05/25.
//

import Cocoa
class SettingViewController : NSViewController{

    
    var config = Configuration.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        initializeSettings()
    }
    
    func initializeSettings(){
        
    }
    

    
    @IBAction func BtnOkPressed(_ sender: Any) {
        self.dismiss(self)
    }
}
