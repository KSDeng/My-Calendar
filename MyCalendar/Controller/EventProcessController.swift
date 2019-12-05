//
//  AddEventController.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/11/25.
//  Copyright © 2019 dks. All rights reserved.
//

// References:
// 1. https://dev.to/lawgimenez/implementing-the-expandable-cell-in-ios-uitableview-f7j
// 2. https://stackoverflow.com/questions/17018447/rounding-of-nsdate-to-nearest-hour-in-ios

// MARK: TODOs
// 1. 添加任务时进行数据合法性检查
// 2. 编辑时间若起始时间更改一天要放到新的位置

import UIKit
import CoreData
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
    
    @IBOutlet weak var ifAllDaySwitch: UISwitch!
    
    @IBOutlet weak var startDateLabel: UILabel!
    
    @IBOutlet weak var startTimeButton: UIButton!
    
    @IBOutlet weak var startDateTimePicker: UIDatePicker!
    
    @IBOutlet weak var endDateLabel: UILabel!
    
    @IBOutlet weak var endTimeButton: UIButton!
    
    @IBOutlet weak var endDateTimePicker: UIDatePicker!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var invitationLabel: UILabel!
    
    @IBOutlet weak var noteTextField: UITextField!
    
    
    // 每个section的行数
    let numberOfRows = [1,3,1,1,1]
    
    // 当前事件
    var currentEvent: Task?
    // 当前事件在事件数组中的下标(用于编辑和删除)
    var currentEventIndex = 0
    // 发布任务的代理
    var delegate: EventProcessDelegate?
    
    // 进入当前视图的方式(增加和编辑)
    var enterType = Status.Default
    
    // 缓存DateTimePicker中的值
    var tmpStartDate: Date?
    var tmpStartTime: Date?
    var tmpEndDate: Date?
    var tmpEndTime: Date?
    
    // 添加地点时缓存
    var tmpLocation: MKPlacemark?
    
    // 是否展示时间选择器
    var ifShowStPicker = false
    var ifShowEdPicker = false
    
    // 缓存邀请人联系方式
    var tmpInvitations: [String] = []
    
    // 从storyboard加载viewcontroller时viewdidload不会被调用，但viewWillAppear会被调用
    // https://stackoverflow.com/questions/23474339/instantiateviewcontrollerwithidentifier-seems-to-call-viewdidload
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setVisibleContent()
        
        setDateTimePickers()
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        //titleTextField.becomeFirstResponder()
        tableView.keyboardDismissMode = .onDrag
        setupTextFields()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    
    private func setVisibleContent(){
        // 编辑动作进入之前记得设置currentEvent
        if enterType == .Edit {
            if let e = currentEvent {
                tmpStartDate = e.startDate!
                tmpStartTime = e.startTime!
                tmpEndDate = e.endDate!
                tmpEndTime = e.endTime!
                
                // 标题
                titleTextField.text = e.title
                // 全天开关
                ifAllDaySwitch.isOn = e.ifAllDay
                startTimeButton.isHidden = ifAllDaySwitch.isOn
                endTimeButton.isHidden = ifAllDaySwitch.isOn
                
                
                // 时间
                let sd = e.startDate!
                let ed = e.endDate!
                let weekday = Utils.weekDayMap[Calendar.current.component(.weekday, from: sd)]!
                startDateLabel.text = "\(Utils.getDateAsFormat(date: sd, format: "yyyy年M月d日")) \(weekday)"
                startTimeButton.setTitle(Utils.getDateAsFormat(date: sd, format: "HH:mm"), for: .normal)
                
                let eWeekday = Utils.weekDayMap[Calendar.current.component(.weekday, from: ed)]!
                endDateLabel.text = "\(Utils.getDateAsFormat(date: ed, format: "yyyy年M月d日")) \(eWeekday)"
                endTimeButton.setTitle(Utils.getDateAsFormat(date: ed, format: "HH:mm"), for: .normal)
                
                // 地点
                locationLabel.text = e.locTitle
                locationLabel.textColor = UIColor.black
                invitationLabel.text = ""
                noteTextField.text = e.note
                
            }else {
                print("Edit detail error, current event is nil!")
            }
            
        } else if enterType == .Show {
            navigationItem.title = "事务详情"
            
            titleTextField.isUserInteractionEnabled = false
            ifAllDaySwitch.isUserInteractionEnabled = false
            startDateLabel.isUserInteractionEnabled = false
            startTimeButton.isUserInteractionEnabled = false
            endDateLabel.isUserInteractionEnabled = false
            endTimeButton.isUserInteractionEnabled = false
            invitationLabel.isUserInteractionEnabled = false
            noteTextField.isUserInteractionEnabled = false
            
            if let e = currentEvent {
                // 标题
                titleTextField.text = e.title
                // 时间
                let weekday = Utils.weekDayMap[Calendar.current.component(.weekday, from: e.startTime!)]!
                startDateLabel.text = "\(Utils.getDateAsFormat(date: e.startDate!, format: "yyyy年M月d日")) \(weekday)"
                startTimeButton.setTitle(Utils.getDateAsFormat(date: e.startTime!, format: "HH:mm"), for: .normal)
                
                let eWeekday = Utils.weekDayMap[Calendar.current.component(.weekday, from: e.endTime!)]!
                endDateLabel.text = "\(Utils.getDateAsFormat(date: e.endDate!, format: "yyyy年M月d日")) \(eWeekday)"
                endTimeButton.setTitle(Utils.getDateAsFormat(date: e.endTime!, format: "HH:mm"), for: .normal)
                
                // 地点
                locationLabel.text = e.locTitle
                locationLabel.textColor = UIColor.black
                
                // 全天开关
                ifAllDaySwitch.isOn = e.ifAllDay
                
                // 邀请
                if tmpInvitations.isEmpty {
                    invitationLabel.text = ""
                } else {
                    invitationLabel.text = "已邀请\(tmpInvitations.count)位"
                    invitationLabel.textColor = UIColor.black
                }
                
                // 备注
                noteTextField.text = e.note
                
            }else {
                print("Show detail error, current event is nil!")
            }
            
            // navigationItem 某一侧添加多个BarButtonItem
            // https://stackoverflow.com/questions/30341263/how-to-add-multiple-uibarbuttonitems-on-right-side-of-navigation-bar
            let deleteButton = UIBarButtonItem(title: "删除", style: .plain, target: self, action: #selector(deleteButtonClicked))
            // 设置bar button item 字体颜色
            // https://stackoverflow.com/questions/664930/uibarbuttonitem-with-color
            deleteButton.tintColor = UIColor.red
            let editButton = UIBarButtonItem(title: "编辑", style: .plain, target: self, action: #selector(editButtonClicked))
            
            navigationItem.rightBarButtonItems = [deleteButton, editButton]
        } else if enterType == .Add {
            ifAllDaySwitch.isOn = false
            
            let now = Date()
            let nextHour = Date.init(timeInterval: 60*60, since: Date())
            
            let weekday = Utils.weekDayMap[Calendar.current.component(.weekday, from: now.nearestHour())]!
            
            tmpStartDate = now.nearestHour()
            tmpStartTime = now.nearestHour()
            tmpEndDate = nextHour.nearestHour()
            tmpEndTime = nextHour.nearestHour()
            
            startDateLabel.text = "\(Utils.getDateAsFormat(date: Date(), format: "yyyy年M月d日")) \(weekday)"
            startTimeButton.setTitle(Utils.getDateAsFormat(date: Date().nearestHour(), format: "HH:mm"), for: .normal)
            
            endDateLabel.text = "\(Utils.getDateAsFormat(date: nextHour, format: "yyyy年M月d日")) \(weekday)"
            endTimeButton.setTitle(Utils.getDateAsFormat(date: nextHour.nearestHour(), format: "HH:mm"), for: .normal)
            
        }
    }
    
    private func setDateTimePickers(){
        startDateTimePicker.isHidden = true
        startDateTimePicker.datePickerMode = .date
        startDateTimePicker.locale = Locale(identifier: "zh")
        
        endDateTimePicker.isHidden = true
        endDateTimePicker.datePickerMode = .date
        endDateTimePicker.locale = Locale(identifier: "zh")
        
    }
    
    
    @IBAction func startDateTimePickerChanged(_ sender: UIDatePicker) {
        // print(sender.date)
        let date = sender.date
        let weekday = Utils.weekDayMap[Calendar.current.component(.weekday, from: date)]!
        
        if startDateTimePicker.datePickerMode == .date {
            tmpStartDate = date
            startDateLabel.text = "\(Utils.getDateAsFormat(date: date, format: "yyyy年M月d日")) \(weekday)"
        } else if startDateTimePicker.datePickerMode == .time {
            tmpStartTime = date
            startTimeButton.setTitle(Utils.getDateAsFormat(date: date, format: "HH:mm"), for: .normal)
        }
    }
    
    @IBAction func endDateTimePickerChanged(_ sender: UIDatePicker) {
        //print(sender.date)
        let date = sender.date
        let weekday = Utils.weekDayMap[Calendar.current.component(.weekday, from: date)]!
        
        if endDateTimePicker.datePickerMode == .date {
            tmpEndDate = date
            endDateLabel.text = "\(Utils.getDateAsFormat(date: date, format: "yyyy年MM月d日")) \(weekday)"
        } else if endDateTimePicker.datePickerMode == .time {
            tmpEndTime = date
            endTimeButton.setTitle(Utils.getDateAsFormat(date: date, format: "HH:mm"), for: .normal)
        }
    }
    
    @IBAction func allDaySwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            startTimeButton.isHidden = true
            endTimeButton.isHidden = true
            endDateLabel.isUserInteractionEnabled = false
            
        }else{
            startTimeButton.isHidden = false
            endTimeButton.isHidden = false
            endDateLabel.isUserInteractionEnabled = true
        }
        tableView.beginUpdates()
        tableView.endUpdates()
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
            // https://stackoverflow.com/questions/2267993/uitableview-how-to-disable-selection-for-some-rows-but-not-others
            return indexPath.section == 2 ? indexPath : nil
            
        }
        
        // 打开全天开关之后结束时间不可交互
        if ifAllDaySwitch.isOn {
            return (indexPath.section == 1 && indexPath.row == 2) ? nil : indexPath
        }
        return indexPath
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let identifier = tableView.cellForRow(at: indexPath)?.reuseIdentifier
        switch identifier {
        case "locationCell": self.view.endEditing(true)
        case "invitationCell": self.view.endEditing(true)
        case "startTimeCell":
            if (!ifShowStPicker) {
                startDateTimePicker.datePickerMode = .date
                startDateTimePicker.locale = Locale(identifier: "zh")
                ifShowStPicker = true
            } else if (ifShowStPicker && startDateTimePicker.datePickerMode == .time){
                startDateTimePicker.datePickerMode = .date
                startDateTimePicker.locale = Locale(identifier: "zh")
            } else if (ifShowStPicker && startDateTimePicker.datePickerMode == .date){
                ifShowStPicker = false
            }
            startDateTimePicker.isHidden = !ifShowStPicker
        case "endTimeCell":
            
            if (!ifShowEdPicker) {
                endDateTimePicker.datePickerMode = .date
                endDateTimePicker.locale = Locale(identifier: "zh")
                ifShowEdPicker = true
            } else if (ifShowEdPicker && endDateTimePicker.datePickerMode == .time){
                endDateTimePicker.datePickerMode = .date
                endDateTimePicker.locale = Locale(identifier: "zh")
            } else if (ifShowEdPicker && endDateTimePicker.datePickerMode == .date){
                ifShowEdPicker = false
            }
            endDateTimePicker.isHidden = !ifShowEdPicker
        default:
            print("Clicked cell not handled.")
        }
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var res: CGFloat = 44
        
        // 时间设置栏
        if indexPath.section == 1 {
            if indexPath.row == 1 && ifShowStPicker{
                res = 214
            }
            if indexPath.row == 2 {
                if ifAllDaySwitch.isOn {
                    res = 0
                } else if ifShowEdPicker {
                    res = 214
                }
            }
        }
        // 邀请对象栏
        if indexPath.section == 3 {
            res += (44 * CGFloat(tmpInvitations.count))
        }
        
        return res
    }
    
    @IBAction func startTimeButtonClicked(_ sender: UIButton) {
        if (!ifShowStPicker) {
            startDateTimePicker.datePickerMode = .time
            startDateTimePicker.locale = Locale(identifier: "en_GB")
            ifShowStPicker = true
        } else if (ifShowStPicker && startDateTimePicker.datePickerMode == .date){
            startDateTimePicker.datePickerMode = .time
            startDateTimePicker.locale = Locale(identifier: "en_GB")
        } else if (ifShowStPicker && startDateTimePicker.datePickerMode == .time){
            ifShowStPicker = false
        }
        startDateTimePicker.isHidden = !ifShowStPicker
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    @IBAction func endTimeButtonClicked(_ sender: UIButton) {
        if (!ifShowEdPicker) {
            endDateTimePicker.datePickerMode = .time
            endDateTimePicker.locale = Locale(identifier: "en_GB")
            ifShowEdPicker = true
        } else if (ifShowEdPicker && endDateTimePicker.datePickerMode == .date){
            endDateTimePicker.datePickerMode = .time
            endDateTimePicker.locale = Locale(identifier: "en_GB")
        } else if (ifShowEdPicker && endDateTimePicker.datePickerMode == .time){
            ifShowEdPicker = false
        }
        endDateTimePicker.isHidden = !ifShowEdPicker
        tableView.beginUpdates()
        tableView.endUpdates()
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
    
    // 生成邀请记录
    private func generateInvitationsRecord() -> String {
        var res = ""
        for (index, inv) in tmpInvitations.enumerated() {
            res += inv
            if index != tmpInvitations.count - 1 {
                res += "|"
            }
        }
        return res
    }
    
    // 解析邀请记录
    private func parseInvitationRecord(record: String) -> [String] {
        var res: [String] = []
        for slice in record.split(separator: "|"){
            res.append("\(slice)")
        }
        return res
    }
    
    // 添加事件完成
    @IBAction func saveEventAction(_ sender: Any) {
        currentEvent = Task(context: Utils.context)
        if let stDate = tmpStartDate, let stTime = tmpStartTime {
            //print("Start date: \(stDate)")
            //print("Start time: \(stTime)")
            currentEvent?.startDate = stDate
            currentEvent?.startTime = stTime
        }
        if let edDate = tmpEndDate, let edTime = tmpEndTime {
            //print("End date: \(edDate)")
            //print("End time: \(edTime)")
            currentEvent?.endDate = edDate
            currentEvent?.endTime = edTime
        }
        
        if let currentEvent = currentEvent {
            currentEvent.ifAllDay = ifAllDaySwitch.isOn
            
            currentEvent.dateIndex = Utils.getDateAsFormat(date: currentEvent.startDate!, format: "yyyy-MM-dd")
            
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
        ifAllDaySwitch.isUserInteractionEnabled = true
        startDateLabel.isUserInteractionEnabled = true
        startTimeButton.isUserInteractionEnabled = true
        endDateLabel.isUserInteractionEnabled = true
        endTimeButton.isUserInteractionEnabled = true
        
        locationLabel.isUserInteractionEnabled = true
        invitationLabel.isUserInteractionEnabled = true
        noteTextField.isUserInteractionEnabled = true
        enterType = .Edit
        //titleTextField.becomeFirstResponder()
        
        let editConfirmButton = UIBarButtonItem(title: "保存", style: .plain, target: self, action: #selector(confirmEditButtonClicked))
        navigationItem.rightBarButtonItems = [editConfirmButton]
    }
    
    @objc func confirmEditButtonClicked(){
        if let currentEvent = currentEvent {
            currentEvent.title = titleTextField.text!.isEmpty ? "(无主题)" : titleTextField.text!
            currentEvent.ifAllDay = ifAllDaySwitch.isOn
            currentEvent.startDate = tmpStartDate
            currentEvent.startTime = tmpStartTime
            currentEvent.endDate = tmpEndDate
            currentEvent.endTime = tmpEndTime
            
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
        } else if segue.identifier == "addInvitation"{
            // 添加邀请对象
            let dest = (segue.destination) as! InvitationViewController
            dest.delegate = self
        }
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

// 获得最近的下一个整点
extension Date {
    func nearestHour() -> Date {
        var components = Calendar.current.dateComponents([.minute], from: self)
        let minute = components.minute ?? 0
        components.minute = 60 - minute
        if let getDate = Calendar.current.date(byAdding: components, to: self){
            return getDate
        } else{
            print("Neareast hour doesn't exist!")
            return Date()
        }
    }
}

extension EventProcessController: InvitationDelegate {
    func addInvitation(phoneNumber: String) {
        print("Add invitation \(phoneNumber)")
        tmpInvitations.append(phoneNumber)
    }
    
}
