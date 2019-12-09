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

// MARK: - TODOs

import UIKit
import CoreData
import MapKit

// MARK: -Enums
// 当前通知设置的种类
enum notificationSettingEnum: String {
    case None, TenMinutes, HalfAnHour, AnHour, Custom
}

// MARK: - Protocols
protocol EventProcessDelegate {
    func addEvent(e: Task)
    func editEvent(e: Task, index: Int, eventId: NSManagedObjectID)
    func deleteEvent(index: Int, eventId: NSManagedObjectID)
}

class EventProcessController: UITableViewController {

    // MARK: - Outlets
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
    
    
    @IBOutlet weak var notificationCurrentSettingLabel: UILabel!
    
    @IBOutlet weak var notificationNoneButton: UIButton!
    
    @IBOutlet weak var notificationTenMinutesButton: UIButton!
    
    @IBOutlet weak var notificationHalfAnHourButton: UIButton!
    
    @IBOutlet weak var notificationOneHourButton: UIButton!
    
    @IBOutlet weak var notificationCustomButton: UIButton!
    
    // MARK: - Constants
    // 本地通知管理器
    let notificationManager = LocalNotificationManager()
    
    // MARK: - Variables
    // 每个section的行数
    var numberOfRows = [1,3,1,1,1,1]
    
    // 当前事件
    var currentEvent: Task?
    // 当前事件在事件数组中的下标(用于编辑和删除)
    var currentEventIndex = 0
    // 发布任务的代理
    var delegate: EventProcessDelegate?
    
    // 当前视图的状态(增加、编辑、展示、默认)
    var status = Status.Default
    
    // 缓存DateTimePicker中的值
    var tmpStartDate: Date?
    var tmpStartTime: Date?
    var tmpEndDate: Date?
    var tmpEndTime: Date?
    
    // 时间设置是否合法
    var ifTimeSettingValid = true
    
    // 当前设置的开始时间和结束时间
    var cachedST: Date? {
        willSet {
            if let st = newValue, let et = cachedET, !ifAllDaySwitch.isOn {
                ifTimeSettingValid = !(st > et)
                startDateLabel.textColor = st > et ? UIColor.red : UIColor.black
                startTimeButton.setTitleColor(st > et ? UIColor.red : UIColor.black, for: .normal)
                endDateLabel.textColor = st > et ? UIColor.red : UIColor.black
                endTimeButton.setTitleColor(st > et ? UIColor.red : UIColor.black, for: .normal)
            }
        }
    }
    var cachedET: Date? {
        willSet {
            if let st = cachedST, let et = newValue, !ifAllDaySwitch.isOn {
                ifTimeSettingValid = !(st > et)
                startDateLabel.textColor = st > et ? UIColor.red : UIColor.black
                startTimeButton.setTitleColor(st > et ? UIColor.red : UIColor.black, for: .normal)
                endDateLabel.textColor = st > et ? UIColor.red : UIColor.black
                endTimeButton.setTitleColor(st > et ? UIColor.red : UIColor.black, for: .normal)
            }
        }
    }
    
    // 添加地点时缓存
    var tmpLocation: MKPlacemark?
    
    // 是否展示时间选择器
    var ifShowStPicker = false
    var ifShowEdPicker = false
    
    // 缓存邀请人联系方式
    // var tmpInvitations: [String] = []
    var tmpInvitations: [CachedInvitation] = []
    
    // 是否展示更多通知选项
    var ifShowCustomNotificationSettings = false {
        willSet {
            notificationNoneButton.isHidden = !newValue
            notificationTenMinutesButton.isHidden = !newValue
            notificationHalfAnHourButton.isHidden = !newValue
            notificationOneHourButton.isHidden = !newValue
            notificationCustomButton.isHidden = !newValue
        }
    }
    
    // 缓存当前通知
    var tmpNotification: CachedNotification?
    var tmpNotiRange: String?
    var tmpNotiNumber: Int?
    
    // 缓存的当前通知设置状态
    var notificationSettingStatus = notificationSettingEnum.HalfAnHour
    // 自定义notification通知时间秒数记录
    var customNotificationSecondsFromNow: Int?
    
    // MARK: - Setups
    private func setVisibleContent(){
        
        ifShowCustomNotificationSettings = false
        // 邀请
        if !tmpInvitations.isEmpty {
            invitationLabel.text = "已邀请\(tmpInvitations.count)位"
            invitationLabel.textColor = UIColor.black
        } else {
            invitationLabel.text = "添加邀请对象"
        }
        
        
        
        switch status {
        case .Add:
            
            let now = Date()
            let nextHour = Date.init(timeInterval: 60*60, since: Date())
            
            let weekday = Utils.weekDayMap[Calendar.current.component(.weekday, from: now.nearestHour())]!
            
            tmpStartDate = now.nearestHour()
            tmpStartTime = now.nearestHour()
            tmpEndDate = nextHour.nearestHour()
            tmpEndTime = nextHour.nearestHour()
            cachedST = tmpStartDate
            cachedET = tmpEndDate
            
            startDateLabel.text = "\(Utils.getDateAsFormat(date: now.nearestHour(), format: "yyyy年M月d日")) \(weekday)"
            startTimeButton.setTitle(Utils.getDateAsFormat(date: now.nearestHour(), format: "HH:mm"), for: .normal)
            
            endDateLabel.text = "\(Utils.getDateAsFormat(date: nextHour.nearestHour(), format: "yyyy年M月d日")) \(weekday)"
            endTimeButton.setTitle(Utils.getDateAsFormat(date: nextHour.nearestHour(), format: "HH:mm"), for: .normal)
            
            
            
            // 邀请
            if !tmpInvitations.isEmpty {
                invitationLabel.text = "已邀请\(tmpInvitations.count)位"
                invitationLabel.textColor = UIColor.black
            }else {
                invitationLabel.text = "添加邀请对象"
                invitationLabel.textColor = UIColor.lightGray
            }
            
        case .Edit:
            if let e = currentEvent {
                print("Pre settings in edit...")
                // 编辑动作进入之前记得设置currentEvent
                tmpStartDate = e.startDate!
                tmpStartTime = e.startTime!
                tmpEndDate = e.endDate!
                tmpEndTime = e.endTime!
                cachedST = getTimeCombined(date: tmpStartDate, time: tmpStartTime)
                cachedET = getTimeCombined(date: tmpEndDate, time: tmpEndTime)
                
                // 标题
                titleTextField.text = e.title
                // 全天开关
                ifAllDaySwitch.isOn = e.ifAllDay
                startTimeButton.isHidden = ifAllDaySwitch.isOn
                endTimeButton.isHidden = ifAllDaySwitch.isOn
                
                setDateTimeLabels(e: e)
                
                // 地点
                locationLabel.text = e.locTitle
                locationLabel.textColor = UIColor.black
                
                // 邀请
                if !tmpInvitations.isEmpty {
                    invitationLabel.text = "已邀请\(tmpInvitations.count)位"
                    invitationLabel.textColor = UIColor.black
                }else {
                    invitationLabel.text = "添加邀请对象"
                    invitationLabel.textColor = UIColor.lightGray
                }
                // 备注
                noteTextField.text = e.note
            }else{
                print("Current task is nil!")
            }
        case .Show:
            if let e = currentEvent {
                navigationItem.title = "事务详情"
                
                titleTextField.isUserInteractionEnabled = false
                ifAllDaySwitch.isUserInteractionEnabled = false
                startDateLabel.isUserInteractionEnabled = false
                startTimeButton.isUserInteractionEnabled = false
                endDateLabel.isUserInteractionEnabled = false
                endTimeButton.isUserInteractionEnabled = false
                invitationLabel.isUserInteractionEnabled = false
                noteTextField.isUserInteractionEnabled = false
                
                // 标题
                titleTextField.text = e.title
                // 时间
                setDateTimeLabels(e: e)
                cachedST = getTimeCombined(date: e.startDate!, time: e.startTime!)
                cachedET = getTimeCombined(date: e.endDate!, time: e.endTime!)
                
                // 地点
                locationLabel.text = e.locTitle
                locationLabel.textColor = UIColor.black
                
                // 全天开关
                ifAllDaySwitch.isOn = e.ifAllDay
                if ifAllDaySwitch.isOn {
                    startTimeButton.isHidden = true
                    endTimeButton.isHidden = true
                }
                
                // 邀请
                if !tmpInvitations.isEmpty {
                    invitationLabel.text = "已邀请\(tmpInvitations.count)位"
                    invitationLabel.textColor = UIColor.black
                }else {
                    invitationLabel.text = "暂无邀请对象"
                    invitationLabel.textColor = UIColor.lightGray
                }
                // 通知
                if let noti = tmpNotification {
                    notificationCurrentSettingLabel.text = "提前\(noti.number)\(noti.range)通知"
                }
                
                // 备注
                noteTextField.text = e.note
                
                // navigationItem 某一侧添加多个BarButtonItem
                // https://stackoverflow.com/questions/30341263/how-to-add-multiple-uibarbuttonitems-on-right-side-of-navigation-bar
                let deleteButton = UIBarButtonItem(title: "删除", style: .plain, target: self, action: #selector(deleteButtonClicked))
                // 设置bar button item 字体颜色
                // https://stackoverflow.com/questions/664930/uibarbuttonitem-with-color
                deleteButton.tintColor = UIColor.red
                let editButton = UIBarButtonItem(title: "编辑", style: .plain, target: self, action: #selector(editButtonClicked))
                
                navigationItem.rightBarButtonItems = [deleteButton, editButton]
            }else {
                print("Current task is nil!")
            }
        default:
            print("Status default.")
        }

    }
    
    // 根据传入的任务设置日期和时间标签
    private func setDateTimeLabels(e: Task) {
        let weekday = Utils.weekDayMap[Calendar.current.component(.weekday, from: e.startDate!)]!
        startDateLabel.text = "\(Utils.getDateAsFormat(date: e.startDate!, format: "yyyy年M月d日")) \(weekday)"
        startTimeButton.setTitle(Utils.getDateAsFormat(date: e.startTime!, format: "HH:mm"), for: .normal)
        
        let eWeekday = Utils.weekDayMap[Calendar.current.component(.weekday, from: e.endDate!)]!
        endDateLabel.text = "\(Utils.getDateAsFormat(date: e.endDate!, format: "yyyy年M月d日")) \(eWeekday)"
        endTimeButton.setTitle(Utils.getDateAsFormat(date: e.endTime!, format: "HH:mm"), for: .normal)
    }
    
    // 设置DateTimePicker的初始状态
    private func setDateTimePickers(){
        startDateTimePicker.isHidden = true
        startDateTimePicker.datePickerMode = .date
        startDateTimePicker.locale = Locale(identifier: "zh")
        
        endDateTimePicker.isHidden = true
        endDateTimePicker.datePickerMode = .date
        endDateTimePicker.locale = Locale(identifier: "zh")
        
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
    
    // MARK: - View Life Cycle
    // 从storyboard加载viewcontroller时viewdidload不会被调用，但viewWillAppear会被调用
    // https://stackoverflow.com/questions/23474339/instantiateviewcontrollerwithidentifier-seems-to-call-viewdidload
    override func viewWillAppear(_ animated: Bool) {
        print("Event process view appear")
        print("Status: \(status.rawValue)")
        super.viewWillAppear(animated)
        setVisibleContent()
        
        setDateTimePickers()
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        //titleTextField.becomeFirstResponder()
        tableView.keyboardDismissMode = .onDrag
        setupTextFields()
        
        if status == .Edit {
            // 邀请
            if !tmpInvitations.isEmpty {
                invitationLabel.text = "已邀请\(tmpInvitations.count)位"
                invitationLabel.textColor = UIColor.black
            }else {
                invitationLabel.text = "添加邀请对象"
                invitationLabel.textColor = UIColor.lightGray
            }
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Actions
    
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
        
        cachedST = getTimeCombined(date: tmpStartDate, time: tmpStartTime)
        print("cachedST: \(Utils.getDateAsFormat(date: cachedST!, format: "yyyy/M/d HH:mm"))")
        print("cachedET: \(Utils.getDateAsFormat(date: cachedET!, format: "yyyy/M/d HH:mm"))")
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
        
        cachedET = getTimeCombined(date: tmpEndDate, time: tmpEndTime)
        print("cachedST: \(Utils.getDateAsFormat(date: cachedST!, format: "yyyy/M/d HH:mm"))")
        print("cachedET: \(Utils.getDateAsFormat(date: cachedET!, format: "yyyy/M/d HH:mm"))")
    }
    
    @IBAction func allDaySwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            ifTimeSettingValid = true
            startDateLabel.textColor = UIColor.black
            startTimeButton.setTitleColor(UIColor.black, for: .normal)
            endDateLabel.textColor = UIColor.black
            endTimeButton.setTitleColor(UIColor.black, for: .normal)
            
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
        guard let tmpST = tmpStartTime else {
            fatalError("tmpStartTime does not exist!")
        }
        startDateTimePicker.date = tmpST
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
        guard let tmpET = tmpEndTime else {
            fatalError("tmpEndTime does not exist!")
        }
        endDateTimePicker.date = tmpET
        endDateTimePicker.isHidden = !ifShowEdPicker
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    // 添加事件完成
    @IBAction func saveEventAction(_ sender: Any) {
        // https://learnappmaking.com/uialertcontroller-alerts-swift-how-to/
        if !ifTimeSettingValid {
            let alert = UIAlertController(title: "时间设置错误", message: "开始时间不能晚于结束时间!", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "好", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        currentEvent = Task(context: Utils.context)
        if let stDate = tmpStartDate, let stTime = tmpStartTime, let edDate = tmpEndDate, let edTime = tmpEndTime {
            currentEvent?.startDate = stDate
            currentEvent?.startTime = stTime
            currentEvent?.endDate = edDate
            currentEvent?.endTime = edTime
            currentEvent?.nDays = ifAllDaySwitch.isOn ? 0 : Int16(numOfDaysBetween(start: stDate, end: edDate))
            print("Number of days: \(currentEvent!.nDays)")
        }else{
            fatalError("Time settings inadequate!")
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
            
            // 添加邀请信息
            for inv in tmpInvitations {
                let NS_inv = Invitation(context: Utils.context)
                NS_inv.phoneNumber = inv.phoneNumber
                NS_inv.lastEditTime = Date()
                currentEvent.invitations = currentEvent.invitations?.adding(NS_inv) as NSSet?
            }
            
            // 备注
            currentEvent.note = noteTextField.text!.isEmpty ? "(未添加备注)" : noteTextField.text!
            currentEvent.colorPoint = Int16(Utils.currentColorPoint)
            Utils.currentColorPoint = (Utils.currentColorPoint + 1) % Utils.eventColorArray.count
            
            // 设置通知
            
            if notificationSettingStatus != .None {
                print("Notification setting status: \(notificationSettingStatus)")
                let notification = generateNotification(task: currentEvent)
                notificationManager.addNotification(notification: notification!)
                let notiPersist = Notification(context: Utils.context)      // 持久化
                notiPersist.id = notification!.id
                notiPersist.title = notification!.title
                notiPersist.body = notification!.body
                notiPersist.datetime = notification!.datetime
                notiPersist.range = notification!.range
                notiPersist.number = Int16(notification!.number)
                currentEvent.notification = notiPersist
            }
            
            // print("ColorPoint: \(colorPoint)")
            delegate?.addEvent(e: currentEvent)
        }else{
            print("No task to add error.")
        }
        
        navigationController?.popViewController(animated: true)
        
    }
    
    
    @IBAction func notificationNoneButtonClicked(_ sender: UIButton) {
        notificationSettingStatus = .None
        ifShowCustomNotificationSettings = false
        notificationCurrentSettingLabel.text = "无"
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    @IBAction func notificationTenMinutesButtonClicked(_ sender: UIButton) {
        notificationSettingStatus = .TenMinutes
        ifShowCustomNotificationSettings = false
        notificationCurrentSettingLabel.text = "提前10分钟通知"
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    @IBAction func notificationHalfAnHourButtonClicked(_ sender: UIButton) {
        notificationSettingStatus = .HalfAnHour
        ifShowCustomNotificationSettings = false
        notificationCurrentSettingLabel.text = "提前30分钟通知"
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    @IBAction func notificationOneHourButtonClicked(_ sender: UIButton) {
        notificationSettingStatus = .AnHour
        ifShowCustomNotificationSettings = false
        notificationCurrentSettingLabel.text = "提前1小时通知"
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 6
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return numberOfRows[section]
    }
    
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // 若是展示事务内容则将cell设置为不可选择
        // https://stackoverflow.com/questions/812426/uitableview-setting-some-cells-as-unselectable
        if status == .Show {
            
            // 此时地点和邀请栏可以交互
            // https://stackoverflow.com/questions/2267993/uitableview-how-to-disable-selection-for-some-rows-but-not-others
            return (indexPath.section == 2) ? indexPath : nil
            
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
            self.view.endEditing(true)
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
            guard let tmpSD = tmpStartDate else {
                fatalError("tmpStartDate doesn't exist!")
            }
            startDateTimePicker.date = tmpSD
            startDateTimePicker.isHidden = !ifShowStPicker
        case "endTimeCell":
            self.view.endEditing(true)
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
            guard let tmpED = tmpEndDate else {
                fatalError("tmpEndDate doesn't exist!")
            }
            endDateTimePicker.date = tmpED
            endDateTimePicker.isHidden = !ifShowEdPicker
        case "notificationCell":
            self.view.endEditing(true)
            ifShowCustomNotificationSettings = !ifShowCustomNotificationSettings
            
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
        // 通知设置栏
        if indexPath.section == 4 {
            if ifShowCustomNotificationSettings {
                res = 220
            }
        }
        
        return res
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
    

    // MARK: - Objc Functions
    @objc func doneButtonAction(){
        self.view.endEditing(true)
    }
    
    @objc func deleteButtonClicked(){
        if currentEvent?.notification != nil {
            let id = currentEvent?.notification?.id!
            print("Delete notification with ID = \(id!.uuidString)")
            notificationManager.deleteNotification(id: id!)
        }
        
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
        status = .Edit
        //titleTextField.becomeFirstResponder()
        
        let editConfirmButton = UIBarButtonItem(title: "保存", style: .plain, target: self, action: #selector(confirmEditButtonClicked))
        navigationItem.rightBarButtonItems = [editConfirmButton]
        
        // 设置这两个变量相当于开启时间检查
        cachedST = getTimeCombined(date: tmpStartDate, time: tmpStartTime)
        cachedET = getTimeCombined(date: tmpEndDate, time: tmpEndTime)
        
        // 邀请
        if !tmpInvitations.isEmpty {
            invitationLabel.text = "已邀请\(tmpInvitations.count)位"
            invitationLabel.textColor = UIColor.black
        } else {
            invitationLabel.text = "添加邀请对象"
            
        }
    }
    
    @objc func confirmEditButtonClicked(){
        // 删除原有通知
        if currentEvent?.notification != nil {
            Utils.context.delete((currentEvent?.notification!)!)
        }
        // 重新加入通知
        if notificationSettingStatus != .None {
            let notification = generateNotification(task: currentEvent!)
            notificationManager.addNotification(notification: notification!)
            let notiPersist = Notification(context: Utils.context)      // 持久化
            notiPersist.id = notification!.id
            notiPersist.title = notification!.title
            notiPersist.body = notification!.body
            notiPersist.datetime = notification!.datetime
            notiPersist.range = notification!.range
            notiPersist.number = Int16(notification!.number)
            currentEvent!.notification = notiPersist
        }
        
        if !ifTimeSettingValid {
            let alert = UIAlertController(title: "时间设置错误", message: "开始时间不能晚于结束时间!", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "好", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        if let currentEvent = currentEvent {
            // 日期是否发生改变
            let newDateIndex = Utils.getDateAsFormat(date: tmpStartDate!, format: "yyyy-MM-dd")
            let ifDateChanged = currentEvent.dateIndex! != newDateIndex
            let nDays = ifAllDaySwitch.isOn ? 0 : numOfDaysBetween(start: tmpStartDate!, end: tmpEndDate!)
            let ifNumDaysChanged = currentEvent.nDays != Int16(nDays)
            
            if (ifDateChanged || ifNumDaysChanged){
                // print("Date changed to \(newDateIndex)")
                delegate?.deleteEvent(index: currentEventIndex, eventId: currentEvent.objectID)
                
                let newTask = Task(context: Utils.context)
                newTask.dateIndex = newDateIndex
                newTask.nDays = Int16(nDays)
                newTask.type = EventType.Task.rawValue
                
                newTask.title = titleTextField.text!.isEmpty ? "(无主题)" : titleTextField.text!
                newTask.ifAllDay = ifAllDaySwitch.isOn
                if let stDate = tmpStartDate, let stTime = tmpStartTime {
                    newTask.startDate = stDate
                    newTask.startTime = stTime
                }
                if let edDate = tmpEndDate, let edTime = tmpEndTime {
                    newTask.endDate = edDate
                    newTask.endTime = edTime
                }
                
                if let location = tmpLocation {
                    newTask.locTitle = location.name
                    newTask.locAddrDetail = location.title
                    newTask.locLongitude = location.coordinate.longitude
                    newTask.locLatitude = location.coordinate.latitude
                }
                // 添加邀请信息
                for inv in tmpInvitations {
                    let NS_inv = Invitation(context: Utils.context)
                    NS_inv.phoneNumber = inv.phoneNumber
                    NS_inv.lastEditTime = Date()
                    newTask.invitations = newTask.invitations?.adding(NS_inv) as NSSet?
                }
                
                
                
                // 备注
                newTask.note = noteTextField.text!.isEmpty ? "(未添加备注)" : noteTextField.text!
                newTask.colorPoint = currentEvent.colorPoint
                //Utils.currentColorPoint = (Utils.currentColorPoint + 1) % Utils.eventColorArray.count
                delegate?.addEvent(e: newTask)
                
            }else{
                currentEvent.dateIndex = Utils.getDateAsFormat(date: tmpStartDate!, format: "yyyy-MM-dd")
                
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
                // 删除当前邀请记录并重新添加
                for inv in currentEvent.invitations! {
                    Utils.context.delete(inv as! NSManagedObject)
                }
                
                for inv in tmpInvitations{
                    let NS_Inv = Invitation(context: Utils.context)
                    NS_Inv.belongedTo = currentEvent
                    NS_Inv.lastEditTime = inv.lastEditTime
                    NS_Inv.phoneNumber = inv.phoneNumber
                    currentEvent.invitations = currentEvent.invitations?.adding(NS_Inv) as NSSet?
                }
                
                currentEvent.note = noteTextField.text!.isEmpty ? "(未添加备注)" : noteTextField.text!
                
                delegate?.editEvent(e: currentEvent, index: currentEventIndex, eventId: currentEvent.objectID)
            }
            
        }else {
            print("No task to edit error.")
        }
        
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Private utils
    private func getTimeCombined(date: Date?, time: Date?) -> Date {
        guard let tmpD = date, let tmpT = time else {
            fatalError("date or time does not exist!")
        }
        let dateString = Utils.getDateAsFormat(date: tmpD, format: "yyyyMMdd")
        let timeString = Utils.getDateAsFormat(date: tmpT, format: "HHmm")
        let f = DateFormatter()
        f.dateFormat = "yyyyMMddHHmm"
        let getT = f.date(from: "\(dateString)\(timeString)")
        guard let T = getT else {
            fatalError("Current time invalid!")
        }
        return T
    }
    
    // 两个日期之间的天数
    // https://iostutorialjunction.com/2019/09/get-number-of-days-between-two-dates-swift.html
    private func numOfDaysBetween(start: Date, end: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: start, to: end).day!
    }
    
    // 生成一个通知
    private func generateNotification(task: Task) -> CachedNotification? {
        guard let stDate = task.startDate, let stTime = task.startTime else {
            fatalError("Task start time invalid!")
        }
        let taskStartTime = getTimeCombined(date: stDate, time: stTime)
        let id = UUID()
        let title = task.title ?? "(无主题)"
        var datetime = Date()
        var body = ""
        var range = ""
        var number = 0
        
        switch notificationSettingStatus {
        case .TenMinutes:
            datetime = Date(timeInterval: -10*60, since: taskStartTime)
            range = "分钟"
            number = 10
        case .HalfAnHour:
            datetime = Date(timeInterval: -30*60, since: taskStartTime)
            range = "分钟"
            number = 30
        case .AnHour:
            datetime = Date(timeInterval: -60*60, since: taskStartTime)
            range = "小时"
            number = 1
        case .Custom:
            guard let seconds = customNotificationSecondsFromNow else {
                fatalError("Set custom notification but customNotificationSecondsFromNow is nil!")
            }
            datetime = Date(timeInterval: Double(-seconds), since: taskStartTime)
        default:
            print("Current notification setting not handled.")
        }
        
        if let loc = task.locTitle {
            body = "⏰ \(Utils.getDateAsFormat(date: taskStartTime, format: "HH:mm"))\n 地点: \(loc)"
        }else{
            body = "⏰ \(Utils.getDateAsFormat(date: taskStartTime, format: "HH:mm"))"
        }
        
        var noti: CachedNotification? = nil
        
        if notificationSettingStatus != .None {
            if notificationSettingStatus != .Custom {
                noti = CachedNotification(id: id, title: title, body: body, datetime: datetime, range: range, number: number)
            } else {
                guard let tr = tmpNotiRange, let tn = tmpNotiNumber else {
                    fatalError("tmpNotiRange or tmpNotiNumber not set!")
                }
                noti = CachedNotification(id: id, title: title, body: body, datetime: datetime, range: tr, number: tn)
            }
        }
        
        return noti
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        // 添加地点
        if segue.identifier == "showMap"{
            let dest = (segue.destination) as! MapViewController
            
            // 进入时设置Map状态
            if status == .Add {
                dest.state = .add
            } else if status == .Show {
                dest.state = .show
                
                dest.showTitle = self.currentEvent?.locTitle
                dest.showLongitude = self.currentEvent?.locLongitude
                dest.showLatitude = self.currentEvent?.locLatitude
            } else if status == .Edit {
                dest.state = .edit
                
                dest.showTitle = self.currentEvent?.locTitle
                dest.showLongitude = self.currentEvent?.locLongitude
                dest.showLatitude = self.currentEvent?.locLatitude
            }
            dest.delegate = self
        } else if segue.identifier == "addInvitation"{
            // 添加邀请对象
            let dest = (segue.destination) as! InvitationViewController
            dest.addDelegate = self
            dest.deleteDelegate = self
            if !tmpInvitations.isEmpty {
                dest.currentInvitations = tmpInvitations
                // dest.invitationTable?.invitations = tmpInvitations
            }
        } else if segue.identifier == "customizeNotificationSegue" {
            // 自定义通知设置
            notificationSettingStatus = .Custom
            let dest = (segue.destination) as! CustomizeNotificationController
            dest.delegate = self
        }
    }
    

}

// MARK: - Extensions
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

// 添加邀请
extension EventProcessController: AddInvitationDelegate {
    func addInvitation(inv: CachedInvitation) {
        print("Add invitation \(inv.phoneNumber) in event process controller.")
        tmpInvitations.append(inv)
    }
}
// 删除邀请
extension EventProcessController: DeleteInvitationSecondDelegate {
    func deleteInvitation(index: Int, inv: CachedInvitation) {
        print("Delete invitation \(inv.phoneNumber) in event process controller.")
        tmpInvitations.remove(at: index)
    }
}

// 自定义notification
extension EventProcessController: CustomNotificationDelegate {
    func setNotificationPara(secondsFromNow: Int, sentence: String, range: String, number: Int) {
        self.customNotificationSecondsFromNow = secondsFromNow
        notificationCurrentSettingLabel.text = sentence
        tmpNotiRange = range
        tmpNotiNumber = number
    }
    
}
