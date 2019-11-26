//
//  AddEventController.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/11/25.
//  Copyright © 2019 dks. All rights reserved.
//

// References:
// 1. https://github.com/itsmeichigo/DateTimePicker

import UIKit
import DateTimePicker

protocol EditEventDelegate {
    func addEvent(e: Event)
    func editEvent(e: Event)
}


class AddEventController: UITableViewController {

    @IBOutlet weak var titleTextField: UITextField!
    
    @IBOutlet weak var startTimeLabel: UILabel!
    
    @IBOutlet weak var endTimeLabel: UILabel!

    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var invitationLabel: UILabel!
    
    @IBOutlet weak var noteTextField: UITextField!
    
    // 每个section的行数
    let numberOfRows = [1,2,1,1,1]
    
    var currentEvent: Event?
    // 发布任务的代理
    var delegate: EditEventDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleTextField.becomeFirstResponder()
        tableView.keyboardDismissMode = .onDrag
        setupTextFields()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 5
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return numberOfRows[section]
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch tableView.cellForRow(at: indexPath)?.reuseIdentifier {
        case "startTimeCell":
            print("Start time cell clicked.")
            // self.view.endEditing(true)
            showDateTimePicker(completionHandler: { date in
                let formatter = DateFormatter()
                formatter.dateFormat = "YYYY/MM/dd HH:mm"
                self.startTimeLabel.text = formatter.string(from: date)
                self.startTimeLabel.textColor = UIColor.black
            })
        case "endTimeCell":
            print("End time cell clicked.")
            showDateTimePicker(completionHandler: {date in
                let formatter = DateFormatter()
                formatter.dateFormat = "YYYY/MM/dd HH:mm"
                self.endTimeLabel.text = formatter.string(from: date)
                self.endTimeLabel.textColor = UIColor.black
            })
        case "locationCell":
            print("Location cell clicked.")
        case "invitationCell":
            print("Invitation cell clicked.")
        default:
            print("Not handle.")
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func setupTextFields() {
        let toolBar = UIToolbar(frame: CGRect(origin: .zero, size: .init(width: view.frame.width, height: 30)))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(doneButtonAction))
        
        toolBar.setItems([flexSpace, doneBtn], animated: false)
        toolBar.sizeToFit()
        
        self.titleTextField.inputAccessoryView = toolBar
        self.noteTextField.inputAccessoryView = toolBar
    }
    @objc func doneButtonAction(){
        self.view.endEditing(true)
    }
    
    @IBAction func saveEventAction(_ sender: Any) {
        currentEvent = Event(title: titleTextField.text ?? "无主题",
                             st: startTimeLabel.text ?? "未设置开始时间",
                             et: endTimeLabel.text ?? "未设置结束时间",
                             loc: locationLabel.text ?? "未设置地点",
                             invitations: nil,
                             note: noteTextField.text ?? "未设置备注")
        if let e = currentEvent {
            delegate?.addEvent(e: e)
            navigationController?.popViewController(animated: true)
        }
        
    }
    

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension AddEventController: DateTimePickerDelegate {
    func dateTimePicker(_ picker: DateTimePicker, didSelectDate: Date) {
        title = picker.selectedDateString
    }
    
    private func showDateTimePicker(completionHandler: @escaping ((Date) -> Void)) {
        let min = Date().addingTimeInterval(-60 * 60 * 24 * 100)
        let max = Date().addingTimeInterval(60 * 60 * 24 * 365)
        let picker = DateTimePicker.create(minimumDate: min, maximumDate: max)
        picker.dateFormat = "YYYY/MM/dd HH:mm"
        picker.cancelButtonTitle = "取消"
        picker.todayButtonTitle = "今天"
        picker.doneButtonTitle = "确定"
        picker.highlightColor = UIColor(red:0.58, green:0.64, blue:0.92, alpha:1.0)
        picker.doneBackgroundColor = UIColor(red:0.29, green:0.78, blue:0.51, alpha:1.0)
        picker.completionHandler = completionHandler
        picker.delegate = self
        picker.show()
        //picker.frame = CGRect(x: 0, y: 100, width: picker.frame.size.width, height: picker.frame.size.height)
        //self.view.addSubview(picker)
    }
}

