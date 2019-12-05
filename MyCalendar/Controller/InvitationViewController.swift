//
//  InvitationViewController.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/12/5.
//  Copyright © 2019 dks. All rights reserved.
//

// https://stackoverflow.com/questions/20523874/uitableviewcontroller-inside-a-uiviewcontroller
// https://stackoverflow.com/questions/34348275/pass-data-between-viewcontroller-and-containerviewcontroller

import UIKit

protocol InvitationDelegate {
    func addInvitation(phoneNumber: String)
}
class InvitationViewController: UIViewController {

    @IBOutlet weak var invitationPhoneNumberTextField: UITextField!
    
    var delegate: InvitationDelegate?
    
    var invitationTable: InvitationTableViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        invitationPhoneNumberTextField.becomeFirstResponder()
        invitationPhoneNumberTextField.clearButtonMode = .whileEditing
        // Do any additional setup after loading the view.
    }
    
    @IBAction func addButtonClicked(_ sender: UIButton) {
        if let phone = invitationPhoneNumberTextField.text {
            delegate?.addInvitation(phoneNumber: phone)
            if let invitationTable = invitationTable {
                invitationTable.addInvitation(invitation: phone)
                invitationPhoneNumberTextField.text = ""
            }
        }
        
    }
    
    
    @IBAction func saveButtonClicked(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "invitationTableViewSegue" {
            let dest = segue.destination as! InvitationTableViewController
            invitationTable = dest
            
        }
    }
    

}
