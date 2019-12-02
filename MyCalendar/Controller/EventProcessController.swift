//
//  AddEventController.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/11/25.
//  Copyright © 2019 dks. All rights reserved.
//

// References:
// 1. https://github.com/itsmeichigo/DateTimePicker

// MARK: TODOs
// Expandable TableView Cell

import UIKit
import CoreData
import DateTimePicker
import MapKit

protocol EventProcessDelegate {
    func addEvent(e: Task)
    func editEvent(e: Task, index: Int, eventId: NSManagedObjectID)
    func deleteEvent(index: Int, eventId: NSManagedObjectID)
}

enum Status {
    case Add, Edit, Show, Default
}

class EventProcessController: UITableViewController {

    @IBOutlet weak var titleTextField: UITextField!
    
    @IBOutlet weak var startTimeLabel: UILabel!
    
    @IBOutlet weak var endTimeLabel: UILabel!

    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var invitationLabel: UILabel!
    
    @IBOutlet weak var noteTextField: UITextField!
    
    
    // 每个section的行数
    let numberOfRows = [1,2,1,1,1]
    // 展示的时候地点cell是可以互动的
    let showInteract = [false, false, false, true, false, false]
    
    // 当前事件
    // var currentEvent = Event()
    //var currentEvent = EventPersist(context: Utils.context)
    var currentEvent: Task?
    // 当前事件在事件数组中的下标(用于编辑和删除)
    var currentEventIndex = 0
    // 发布任务的代理
    var delegate: EventProcessDelegate?
    
    // 进入当前视图的方式(增加和编辑)
    var enterType = Status.Default
    
    var tmpStartTime = Date()
    var tmpEndTime = Date()
    
    // 添加地点时缓存
    var tmpLocation: MKPlacemark?
    
    // 从storyboard加载viewcontroller时viewdidload不会被调用，但viewWillAppear会被调用
    // https://stackoverflow.com/questions/23474339/instantiateviewcontrollerwithidentifier-seems-to-call-viewdidload
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 编辑动作进入之前记得设置currentEvent
        if enterType == .Edit {
            //print("Enter type: edit")
            titleTextField.text = currentEvent!.title
            startTimeLabel.text = Utils.getDateAsFormat(date: currentEvent!.startTime!, format: "HH:mm")
            endTimeLabel.text = Utils.getDateAsFormat(date: currentEvent!.endTime!, format: "HH:mm")
            // locationLabel.text = currentEvent!.location
            invitationLabel.text = ""
            noteTextField.text = currentEvent!.note ?? ""
        } else if enterType == .Show {
            navigationItem.title = "事务详情"
            
            titleTextField.isUserInteractionEnabled = false
            startTimeLabel.isUserInteractionEnabled = false
            endTimeLabel.isUserInteractionEnabled = false
            //locationLabel.isUserInteractionEnabled = false
            invitationLabel.isUserInteractionEnabled = false
            noteTextField.isUserInteractionEnabled = false
            
            titleTextField.text = currentEvent!.title
            startTimeLabel.text = Utils.getDateAsFormat(date: currentEvent!.startTime!, format: "HH:mm")
            endTimeLabel.text = Utils.getDateAsFormat(date: currentEvent!.endTime!, format: "HH:mm")
            locationLabel.text = currentEvent!.locTitle
            locationLabel.textColor = UIColor.black
            invitationLabel.text = ""
            noteTextField.text = currentEvent!.note ?? ""
            
            //navigationItem.rightBarButtonItem?.title = "删除"
            //navigationItem.rightBarButtonItem?.tintColor = UIColor.red
            
            // navigationItem 某一侧添加多个BarButtonItem
            // https://stackoverflow.com/questions/30341263/how-to-add-multiple-uibarbuttonitems-on-right-side-of-navigation-bar
            let deleteButton = UIBarButtonItem(title: "删除", style: .plain, target: self, action: #selector(deleteButtonClicked))
            // 设置bar button item 字体颜色
            // https://stackoverflow.com/questions/664930/uibarbuttonitem-with-color
            deleteButton.tintColor = UIColor.red
            let editButton = UIBarButtonItem(title: "编辑", style: .plain, target: self, action: #selector(editButtonClicked))
            
            navigationItem.rightBarButtonItems = [deleteButton, editButton]
        }
    }
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
    
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // 若是展示事务内容则将cell设置为不可选择
        // https://stackoverflow.com/questions/812426/uitableview-setting-some-cells-as-unselectable
        if enterType == .Show {
            
            // 此时地点cell可以交互
            return indexPath.section == 2 ? indexPath : nil
            
        }
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch tableView.cellForRow(at: indexPath)?.reuseIdentifier {
        case "startTimeCell":
            print("Start time cell clicked.")
            self.view.endEditing(true)
            showDateTimePicker(completionHandler: { date in
                // self.currentEvent!.startTime = date       // 开始时间
                self.tmpStartTime = date
                
                let formatter = DateFormatter()
                formatter.timeZone = .autoupdatingCurrent
                formatter.dateFormat = "YYYY/MM/dd HH:mm"
                self.startTimeLabel.text = formatter.string(from: date)
                self.startTimeLabel.textColor = UIColor.black
            })
        case "endTimeCell":
            print("End time cell clicked.")
            self.view.endEditing(true)
            showDateTimePicker(completionHandler: {date in
                // self.currentEvent!.endTime = date        // 结束时间
                self.tmpEndTime = date
                
                let formatter = DateFormatter()
                formatter.timeZone = .autoupdatingCurrent
                formatter.dateFormat = "YYYY/MM/dd HH:mm"
                self.endTimeLabel.text = formatter.string(from: date)
                self.endTimeLabel.textColor = UIColor.black
            })
        case "locationCell":
            print("Location cell clicked.")
            
            self.view.endEditing(true)
        case "invitationCell":
            print("Invitation cell clicked.")
            self.view.endEditing(true)
        default:
            print("Not handle.")
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // 添加输入完成按钮
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
    
    // 添加事件完成
    // TODO: input check, alert
    @IBAction func saveEventAction(_ sender: Any) {
        currentEvent = Task(context: Utils.context)
        currentEvent?.startTime = tmpStartTime
        currentEvent?.endTime = tmpEndTime
        
        if let currentEvent = currentEvent {
            if currentEvent.startTime == nil{
                currentEvent.startTime = Date()
            }
            if currentEvent.endTime == nil{
                currentEvent.endTime = Date()
            }
            currentEvent.timeStamp = Utils.getDateAsFormat(date: Date(), format: "yyyyMMddHHmmss")
            currentEvent.dateIndex = Utils.getDateAsFormat(date: currentEvent.startTime!, format: "yyyy-MM-dd")
            
            currentEvent.arrayIndex = Int32(currentEventIndex)              // 数组下标
            currentEvent.type = EventType.Task.rawValue
            currentEvent.title = titleTextField.text!.isEmpty ? "(无主题)" : titleTextField.text!
            
            // 设置位置信息
            if let location = tmpLocation {
                currentEvent.locTitle = location.name
                currentEvent.locAddrDetail = location.title
                currentEvent.locLongitude = location.coordinate.longitude
                currentEvent.locLatitude = location.coordinate.latitude
            }
            
            // currentEvent.location = locationLabel.text!.isEmpty ? "(未添加地点)" : locationLabel.text!
            // currentEvent.invitations = nil          // TODO
            currentEvent.note = noteTextField.text!.isEmpty ? "(未添加备注)" : noteTextField.text!
            currentEvent.colorPoint = Int16(Utils.currentColorPoint)
            Utils.currentColorPoint = (Utils.currentColorPoint + 1) % Utils.eventColorArray.count
            
            // print("ColorPoint: \(colorPoint)")
            delegate?.addEvent(e: currentEvent)
        }else{
            print("No event to add error.")
        }
        
        navigationController?.popViewController(animated: true)
        
    }
    
    @objc func deleteButtonClicked(){
        delegate?.deleteEvent(index: currentEventIndex, eventId: currentEvent!.objectID)
        navigationController?.popViewController(animated: true)
    }
    @objc func editButtonClicked(){
        navigationItem.title = "编辑事务"
        titleTextField.isUserInteractionEnabled = true
        startTimeLabel.isUserInteractionEnabled = true
        endTimeLabel.isUserInteractionEnabled = true
        locationLabel.isUserInteractionEnabled = true
        invitationLabel.isUserInteractionEnabled = true
        noteTextField.isUserInteractionEnabled = true
        enterType = .Edit
        titleTextField.becomeFirstResponder()
        
        let editConfirmButton = UIBarButtonItem(title: "保存", style: .plain, target: self, action: #selector(confirmEditButtonClicked))
        navigationItem.rightBarButtonItems = [editConfirmButton]
    }
    
    @objc func confirmEditButtonClicked(){
        if let currentEvent = currentEvent {
            currentEvent.title = titleTextField.text!.isEmpty ? "(无主题)" : titleTextField.text!
            // 设置位置信息
            if let location = tmpLocation {
                currentEvent.locTitle = location.name
                currentEvent.locAddrDetail = location.title
                currentEvent.locLongitude = location.coordinate.longitude
                currentEvent.locLatitude = location.coordinate.latitude
            }
            // currentEvent.invitations = nil          // TODO
            currentEvent.note = noteTextField.text!.isEmpty ? "(未添加备注)" : noteTextField.text!
            delegate?.editEvent(e: currentEvent, index: currentEventIndex, eventId: currentEvent.objectID)
        }else {
            print("No event to edit error.")
        }
        
        navigationController?.popViewController(animated: true)
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

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        // 添加地点
        if segue.identifier == "showMap"{
            let dest = (segue.destination) as! MapViewController
            
            // 进入时设置Map状态
            if enterType == .Add {
                dest.state = .add
            } else if enterType == .Show {
                dest.state = .show
                
                dest.showTitle = self.currentEvent?.locTitle
                dest.showLongitude = self.currentEvent?.locLongitude
                dest.showLatitude = self.currentEvent?.locLatitude
            } else if enterType == .Edit {
                dest.state = .edit
                
                dest.showTitle = self.currentEvent?.locTitle
                dest.showLongitude = self.currentEvent?.locLongitude
                dest.showLatitude = self.currentEvent?.locLatitude
            }
            dest.delegate = self
            
        }
    }
    

}


extension EventProcessController: DateTimePickerDelegate {
    func dateTimePicker(_ picker: DateTimePicker, didSelectDate: Date) {
        title = picker.selectedDateString
    }
    
    private func showDateTimePicker(completionHandler: @escaping ((Date) -> Void)) {
        // 允许的时间范围为过去100天到未来365天
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

extension EventProcessController: SetLocationHandle {

    func setLocation(location: MKPlacemark) {
        tmpLocation = location
        self.locationLabel.text = location.name
        self.locationLabel.textColor = UIColor.black
    }
    func editLocationDone(location: MKPlacemark) {
        tmpLocation = location
        self.locationLabel.text = location.name
        self.locationLabel.textColor = UIColor.black
    }
    
}
