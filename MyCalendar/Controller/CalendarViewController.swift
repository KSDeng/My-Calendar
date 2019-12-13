//
//  InitCalendarController.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/11/25.
//  Copyright © 2019 dks. All rights reserved.
//

// MARK: References
// 1. https://github.com/CoderMJLee/MJRefresh
// 2. https://learnappmaking.com/urlsession-swift-networking-how-to/
// 3. http://timor.tech/api/holiday     // 节假日API文档
// 4. https://stackoverflow.com/questions/31018447/how-to-programmatically-have-uitableview-scroll-to-a-specific-section
// 5. https://digitalleaves.com/segues-navigation-ios-basics/

// MARK: TODOs
// 只有列表视图翻起来不方便，最好再加上日历视图
// 无事务且无节假日的日期可以缩略显示
// 一个tableview定制多种Cell
// https://medium.com/@stasost/ios-how-to-build-a-table-view-with-multiple-cell-types-2df91a206429
// https://www.journaldev.com/15077/ios-uitableview-multiple-cell-types
// 顶部的title展示目前所在的时间范围
// 联系人头像
// https://stackoverflow.com/questions/51100121/how-to-generate-an-uiimage-from-custom-text-in-swift

// MARK: Bugs
// 1. 添加事件的时候通知选"无"，再展示，发现显示"提前30分钟通知"
// 2. 添加事件时自定义开始时间和结束时间，点“添加邀请对象”，再返回，时间又变成默认时间

import UIKit
import Foundation
import MJRefresh
import Alamofire
import SwiftyJSON
import CoreData

class CalendarViewController: UITableViewController {

    // MARK: - Constants
    // Refresh 一页大小
    let pageSize = 15
    
    // 节假日请求接口地址
    let holidayRequestURL = "http://timor.tech/api/holiday/year"
    
    // 日期索引格式
    let dateIndexFormat = "yyyy-MM-dd"
    
    // 一行的高度
    let rowHeight: CGFloat = 44
    
    // 一个事件卡片的高度
    let evHeight: CGFloat = 40
    
    // MARK: - Variables
    
    // 日期数组，用refresh动态加载
    // 第一个元素为形如"2019-11-27"的索引，第二个元素为初始显示的文字
    var days:[(String, String)] = []
    
    // 每一行的高度，避免遍历整个events数组
    var heights: [String: CGFloat] = [:]
    
    var taskCount: [String: Int] = [:]
    // 事件数组，通过Delegate添加、编辑，并用CoreData进行本地化
    var tasks: [Task] = []
    
    // 特殊日期，通过网络请求动态获取，不进行本地化
    var specialDays: [String:[SpecialDay]] = [:]
    
    var dateToday = ""
    
    // refresh位置指针
    var startIndex = 0, endIndex = 0
    
    // 年份是否已经获取了节假日信息
    var ifHolidayGot = Set<String>()
    
    // 第一次加载
    var ifFirstTime = true
    
    // MARK: - Setups
    
    private func setup(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        // 设置下拉刷新控件
        tableView.mj_header = MJRefreshGifHeader()
        // 设置下拉刷新处理函数
        tableView.mj_header.setRefreshingTarget(self, refreshingAction: #selector(downPullRefresh))
        
        // 设置上拉刷新控件
        tableView.mj_footer = MJRefreshAutoGifFooter()
        // 设置上拉刷新处理函数
        tableView.mj_footer.setRefreshingTarget(self, refreshingAction: #selector(upPullRefresh))
        
        // 初始化加载数据
        // upPullRefresh()
        
    }
    
    // MARK: - View Life Cycle
    // 视图即将出现时完成初始化加载
    override func viewWillAppear(_ animated: Bool) {
        setup()
        if (startIndex == 0){
            loadRefresh(number: pageSize/2, direction: false)
        }
        if (endIndex == 0){
            loadRefresh(number: pageSize, direction: true)
        }
        let year = Utils.getDateAsFormat(date: Date(), format: "yyyy")
        if (!ifHolidayGot.contains(year)){
            requestHolidayInfo(year: Int(year)!)
            ifHolidayGot.insert(year)
        }
        
        if ifFirstTime{
            loadData()
            for e in tasks {
                for i in 0...Int(e.nDays) {
                    let getDate = Date(timeInterval: Double(i*24*60*60), since: e.startDate!)
                    let getDateIndex = Utils.getDateAsFormat(date: getDate, format: dateIndexFormat)
                    if taskCount.keys.contains(getDateIndex){
                        taskCount[getDateIndex]! += 1
                    }else{
                        taskCount[getDateIndex] = 1
                    }
                }
            }
            ifFirstTime = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // https://www.tutorialspoint.com/how-to-hide-back-button-on-navigation-bar-on-iphone-ipad
        self.navigationItem.setHidesBackButton(true, animated: false)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // tableView.scrollToRow(at: IndexPath(row: pageSize, section: 0), at: .middle, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        saveData()
    }
    
    
    
    
    // MARK: - Date Handlers
    
    // 请求某天详细信息，参数为该天到今天的距离(之前为负，之后为正)
    private func requestDayInfo(daysFromToday: Int){
        // print("Days from today: \(daysFromToday)")
        
        let date = dateForDayFromNow(daysInterval: daysFromToday)
        // print("Get date info of: \(date)")
        
        let dateKey = Utils.getDateAsFormat(date: date, format: "yyyy-MM-dd")
        
        let dateContent = Utils.getDateAsFormat(date: date, format: "yyyy.MM.dd")
        
        let weekDayContent = Utils.weekDayMap[Calendar.current.component(.weekday, from: date)]!
        
        let year = Utils.getDateAsFormat(date: date, format: "yyyy")
        if(!ifHolidayGot.contains(year)){
            requestHolidayInfo(year: Int(year)!)
            ifHolidayGot.insert(year)
        }
        updateDataSource(content: "\(dateContent)  \(weekDayContent)", index: daysFromToday, dateKey: dateKey)
        
    }
    
    // daysInterval为与今天的推移天数
    // -1表示昨天此时，1表示明天此时
    private func dateForDayFromNow(daysInterval: Int) -> Date {
        return Date.init(timeInterval:  Double(daysInterval) * 24 * 60 * 60, since: Date())
    }
    
    // 请求某天所在月份的节假日信息，参数为该天到今天的距离(之前为负，之后为正)
    private func requestHolidayInfo(year: Int){
        print("Request holiday info of \(year)")
        let url = "\(holidayRequestURL)/\(year)"
        Alamofire.request(url).responseJSON(completionHandler: {
            response in
            if let json = response.result.value {
                let data = JSON(json)
                let holidays = data["holiday"]
                // traverse the holidays
                for (_, holiday):(String, JSON) in holidays{
                    
                    let targetDate = holiday["date"].stringValue
                    let name = holiday["name"].stringValue
                    let ifHoliday = holiday["holiday"].boolValue
                    
                    
                    let specialDay = ifHoliday ? Holiday() : Adjust()
                    specialDay.title = name
                    // print("Date: \(targetDate), \(name)")
                    if self.specialDays.keys.contains(targetDate){
                        self.specialDays[targetDate]!.append(specialDay)
                    }else{
                        self.specialDays[targetDate] = [specialDay]
                    }
                    
                    if self.taskCount.keys.contains(targetDate){
                        self.taskCount[targetDate]! += 1
                    }else{
                        self.taskCount[targetDate] = 1
                    }
                    self.tableView.reloadData()
                    
                }
            }
        })
    }
    // 更新数据源
    private func updateDataSource(content: String, index: Int, dateKey: String){
        
        // print("Update data: \(content)")
        if index == 0 {
            days.append((dateKey, content))
            dateToday = dateKey
        } else if index < 0 {
            days.insert((dateKey, content), at: 0)
        } else{
            days.append((dateKey, content))
        }
        // 设置初始高度
        //heights[dateKey] = rowHeight
        
        // 未设置事件数量时才设为0，否则会把之前的覆盖掉！
        if !taskCount.keys.contains(dateKey){
            taskCount[dateKey] = 0
        }
        
        // days.sort(by: {$0.0 < $1.0})
        
    }
    
    // MARK: - Event/Task Handlers
    
    private func doAddEvent(e: Task){
        tasks.append(e)
        //print(e)
        for i in 0...Int(e.nDays) {
            let getDate = Date(timeInterval: Double(i*24*60*60), since: e.startDate!)
            let getDateIndex = Utils.getDateAsFormat(date: getDate, format: dateIndexFormat)
            if taskCount.keys.contains(getDateIndex){
                taskCount[getDateIndex]! += 1
            }else{
                taskCount[getDateIndex] = 1
            }
        }
        
        if EventType(rawValue: e.type!)! == .Task{
            tasks.sort(by: {$0.startTime! < $1.startTime!})
        }
        tableView.reloadData()
    }

    
    private func doDeleteEvent(eventIndex: Int, eventId: NSManagedObjectID){
        let task = tasks[eventIndex]
        for i in 0...Int(task.nDays){
            let getDate = Date(timeInterval: Double(i*24*60*60), since: task.startDate!)
            let getDateIndex = Utils.getDateAsFormat(date: getDate, format: dateIndexFormat)
            taskCount[getDateIndex]! -= 1
        }
        
        
        let dEvent = tasks.remove(at: eventIndex)
        Utils.context.delete(dEvent)
        
        tableView.reloadData()
    }
    
    
    // MARK: - CoreData Handlers
    // 保存CoreData上下文
    private func saveData(){
        do {
            try Utils.context.save()
        } catch{
            print(error)
        }
    }
    
    // 从CoreData中加载数据
    private func loadData(){
        do {
            try tasks = Utils.context.fetch(Task.fetchRequest())
        } catch {
            print(error)
        }
        
        tasks.sort(by: {$0.startTime! < $1.startTime!})
        tableView.reloadData()
    }
    
    // MARK: - Refresh Handlers
    // 下拉刷新
    @objc private func downPullRefresh() {
        loadRefresh(number: pageSize, direction: false)
    
    }
    
    // 上拉刷新
    @objc private func upPullRefresh() {
        loadRefresh(number: pageSize, direction: true)
    }
    
    // 刷新加载
    // direction == true, 上拉; direction == false, 下拉
    private func loadRefresh(number: Int, direction: Bool){
    
        if direction {
            for i in (endIndex ..< (endIndex + number)){
                self.requestDayInfo(daysFromToday: i)
            }
            endIndex += number
            tableView.reloadData()
            tableView.mj_footer.endRefreshing()
        }else {
            for i in ((startIndex - number) ..< startIndex).reversed() {
                self.requestDayInfo(daysFromToday: i)
            }
            startIndex -= pageSize
            tableView.reloadData()
            tableView.mj_header.endRefreshing()
        }
    }
    
    // MARK: - objc functions
    // 点击事件视图
    @objc func taskViewTapped(sender: UITapGestureRecognizer){
        // print("Event view tapped!")
        let getView = sender.view as! TaskView
        // 从storyboard加载View Controller
        // https://coderwall.com/p/cjuzng/swift-instantiate-a-view-controller-using-its-storyboard-name-in-xcode
        let detailController: EventProcessController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "AddEventController") as! EventProcessController
        // 传递数据
        detailController.currentEvent = getView.task!
        //print("Current event loc title:\(detailController.currentEvent!.locTitle)")
        detailController.currentEventIndex = getView.taskIndex!
        // print("Get view event id: \(getView.event!.id)")
        
        detailController.tmpStartDate = getView.task!.startDate
        detailController.tmpStartTime = getView.task!.startTime
        detailController.tmpEndDate = getView.task!.endDate
        detailController.tmpEndTime = getView.task!.endTime
        
        if let noti = getView.task!.notification {
            print("Set tmpNotification")
            detailController.tmpNotification = CachedNotification(id: noti.id!, title: noti.title!, body: noti.body!, datetime: noti.datetime!, range: noti.range!, number: Int(noti.number))
            
        }
        
        // 设置邀请列表
        // https://stackoverflow.com/questions/36954095/iterate-nsset-and-cast-to-type-in-one-step
        for case let inv as Invitation in getView.task!.invitations! {
            let cachedInv = CachedInvitation(phoneNumber: inv.phoneNumber!, editTime: inv.lastEditTime!)
            detailController.tmpInvitations.append(cachedInv)
        }
        // 按上次编辑时间排序
        detailController.tmpInvitations.sort(by: {$0.lastEditTime < $1.lastEditTime})
        
        detailController.status = .Show          // 仅展示
        
        detailController.delegate = self
        navigationItem.backBarButtonItem?.title = "返回"
        
        show(detailController, sender: self)
    }
    
    // MARK: - Private utils
    private func showTasks(){
        print("Show tasks:")
        for task in tasks {
            print(task)
        }
    }
    
    private func generateTaskView(task: Task) -> [TaskView] {
        
        var views:[TaskView] = []
        
        if task.ifAllDay {
            // 全天任务
            views = [getOneView(task: task)]
            
        }else{
            let daysCount = Int(task.nDays)
            if daysCount == 0 {
                // 单天任务
                let taskView = getOneView(task: task)
                // 时间标签
                let timeLabel = UILabel(frame: CGRect(x: view.frame.maxX - 150, y: taskView.frame.minY + 7, width: 150, height: evHeight * 0.6))
                
                let startTime = Utils.getDateAsFormat(date: task.startTime!, format: "HH:mm")
                let endTime = Utils.getDateAsFormat(date: task.endTime!, format: "HH:mm")
                
                timeLabel.text = "\(startTime) ~ \(endTime)"
                timeLabel.textColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.0)
                
                taskView.addSubview(timeLabel)
                views.append(taskView)
                
            }else {
                // 多天任务
                
                for i in 0...daysCount {
                    let taskView = getOneView(task: task)
                    
                    taskView.dateIndex = Utils.getDateAsFormat(date: Date(timeInterval: Double(i*24*60*60), since: task.startDate!), format: dateIndexFormat)
                    // 进度标签
                    let processLabel = UILabel(frame: CGRect(x: view.frame.maxX - 250, y: taskView.frame.minY + 7, width: 120, height: evHeight * 0.6))
                    processLabel.text = "(第\(i + 1)天/共\(daysCount + 1)天)"
                    processLabel.textColor = UIColor.white
                    processLabel.adjustsFontSizeToFitWidth = true
                    processLabel.baselineAdjustment = .alignCenters
                    taskView.addSubview(processLabel)
                    
                    if i == 0 {         // 第一天
                        
                        let startTimeLabel = UILabel(frame: CGRect(x: view.frame.maxX - 120, y: taskView.frame.minY + 7, width: 150, height: evHeight * 0.6))
                        
                        startTimeLabel.text = "\(Utils.getDateAsFormat(date: task.startTime!, format: "HH:mm"))开始"
                        startTimeLabel.textColor = UIColor.white
                        
                        taskView.addSubview(startTimeLabel)
                        
                    }else if i == daysCount {       // 最后一天
                        let endTimeLabel = UILabel(frame: CGRect(x: view.frame.maxX - 120, y: taskView.frame.minY + 7, width: 150, height: evHeight * 0.6))
                        
                        endTimeLabel.text = "直到\(Utils.getDateAsFormat(date: task.endTime!, format: "HH:mm"))"
                        endTimeLabel.textColor = UIColor.white
                        
                        taskView.addSubview(endTimeLabel)
                    }
                    
                    views.append(taskView)
                }
            }
        }
        
        return views
    }
    
    // 所有事件的View共有部分
    private func getOneView(task: Task) -> TaskView {
        let taskView = TaskView()
        taskView.dateIndex = task.dateIndex
        taskView.taskIndex = tasks.firstIndex(of: task)
        taskView.task = task
        
        // 根据事件类型设置不同的颜色
        switch EventType(rawValue: task.type!) {
        case .Task:
            taskView.backgroundColor = Utils.eventColorArray[Int(task.colorPoint)]
        case .Holiday:
            taskView.backgroundColor = Utils.holidayColor
        case .Adjust:
            taskView.backgroundColor = Utils.adjustDayColor
        default:
            print("Event type error while redering!")
        }
        
        // 标题标签
        let titleLabel = UILabel(frame: CGRect(x: taskView.bounds.minX + 16, y: taskView.bounds.minY + 7, width: 200, height: evHeight * 0.6))
        titleLabel.text = task.title
        titleLabel.textColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.0)
        titleLabel.adjustsFontSizeToFitWidth = true             // 字体自动适应宽度
        
        // 避免字体自适应后的位置偏移
        // https://stackoverflow.com/questions/26649909/text-not-vertically-centered-in-uilabel
        titleLabel.baselineAdjustment = .alignCenters
        taskView.addSubview(titleLabel)
        
        // 任务添加点击事件
        if EventType(rawValue: task.type!) == .Task{
            let gesture = UITapGestureRecognizer(target: self, action: #selector(taskViewTapped))
            taskView.addGestureRecognizer(gesture)
        }
        
        return taskView
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return days.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarCell", for: indexPath) as! CalendarCell
        let day = days[indexPath.row]
        // 显示该天对应的文字提示
        cell.dateLabel.text = day.1
        // 今天
        // duplicated cell error caused by reusing cell dequeue
        // Solved: https://fluffy.es/solve-duplicated-cells/
        if dateToday == day.0 {
            // ref: https://stackoverflow.com/questions/43655507/ios-swift-setting-view-frame-position-programmatically/43656052#43656052
            // print("This seems today? \(day.0)")
            cell.noteView.isHidden = false
            cell.noteView.frame.origin.x = cell.bounds.maxX - 35
            cell.noteView.frame.origin.y = cell.bounds.minY + 12
            cell.noteView.frame.size.width = 18
            cell.noteView.frame.size.height = 18
            cell.noteView.layer.cornerRadius = cell.noteView.frame.size.width / 2
            cell.noteView.backgroundColor = UIColor(red:0.10, green:0.71, blue:1.00, alpha:1.0)
            
        }
        
        var eventCount = 0
        
        // 特殊日期
        if let sds = specialDays[day.0]{
            for (index, sd) in sds.enumerated() {
                //print("Special day: \(sd.title)")
                let evWidth = cell.bounds.width - 32
                let evX = cell.bounds.minX + 16
                
                var evY = cell.bounds.minY + rowHeight + 2
                evY += (CGFloat(index) * (evHeight + 2))
                
                let sdView = UIView.init(frame: CGRect(x: evX, y: evY, width: evWidth, height: evHeight))
                if let _ = sd as? Holiday {
                    sdView.backgroundColor = Utils.holidayColor
                }else{
                    sdView.backgroundColor = Utils.adjustDayColor
                }
                
                let titleLabel = UILabel(frame: CGRect(x: sdView.bounds.minX + 16, y: sdView.bounds.minY + 7, width: 200, height: sdView.bounds.height * 0.6))
                titleLabel.text = sd.title
                titleLabel.textColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.0)
                titleLabel.adjustsFontSizeToFitWidth = true             // 字体自动适应宽度
                
                titleLabel.baselineAdjustment = .alignCenters           // 防止自适应后位置偏移
                sdView.addSubview(titleLabel)
                
                cell.addSubview(sdView)
                
                eventCount += 1
            }
        }
        
        
        // 显示该天对应的任务
        // 添加的事件其实也会被重用(duplicated)，看不到是因为高度的原因被隐藏了
        for task in tasks{
            let taskViews = generateTaskView(task: task)
            for taskView in taskViews {
                if taskView.dateIndex! == day.0 {
                    let evWidth = cell.bounds.width - 32
                    let evX = cell.bounds.minX + 16
                    var evY = cell.bounds.minY + rowHeight + 2
                    evY += (CGFloat(eventCount) * (evHeight + 2))
                    eventCount += 1
                    
                    taskView.frame = CGRect(x: evX, y: evY, width: evWidth, height: evHeight)
                    cell.addSubview(taskView)
                    
                }
            }
        }
        
        return cell
    }
    
    // 设置每个cell的高度
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        // 使用map才能做到即时渲染
        return rowHeight + CGFloat(taskCount[days[indexPath.row].0]!) * (evHeight + 2)
        //return heights[days[indexPath.row].0]!
        // 以下方法会造成较大的延迟
        /*
        var res = rowHeight
        for task in events {
            if task.dateIndex! == days[indexPath.row].0 {
                res += (evHeight + 2)
            }
        }
        return res
        */
    }
    
    
    

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
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
        if segue.identifier == "addEventSegue" {
            let dest = (segue.destination) as! EventProcessController
            dest.delegate = self
            // 动作为增加事件
            dest.status = .Add
            // 在context中创建新事件
            // 此时创建为时过早，因为还有可能取消添加
            // dest.currentEvent = Task(context: Utils.context)
        }
    }

    // MARK: - Actions
    @IBAction func backToToday(_ sender: UIBarButtonItem) {
        tableView.scrollToRow(at: IndexPath(row: -startIndex - 8, section: 0), at: .middle, animated: true)
    }
    
}

// MARK: - Extensions
extension CalendarViewController: EventProcessDelegate {
    func editEvent(e: Task, index: Int, eventId: NSManagedObjectID) {
        
        tasks[index] = e
        tasks.sort(by: {$0.startTime! < $1.startTime!})
        tableView.reloadData()
    }
    
    func deleteEvent(index: Int, eventId: NSManagedObjectID) {
        doDeleteEvent(eventIndex: index, eventId: eventId)
        tableView.reloadData()
    }
    
    
    func addEvent(e: Task){
        doAddEvent(e: e)
        tableView.reloadData()
    }
    
    
}
