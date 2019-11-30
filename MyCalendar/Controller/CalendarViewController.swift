//
//  InitCalendarController.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/11/25.
//  Copyright © 2019 dks. All rights reserved.
//

// References:
// 1. https://github.com/CoderMJLee/MJRefresh
// 2. https://learnappmaking.com/urlsession-swift-networking-how-to/
// 3. http://timor.tech/api/holiday     // 节假日API文档
// 4. https://stackoverflow.com/questions/31018447/how-to-programmatically-have-uitableview-scroll-to-a-specific-section
// 5. https://digitalleaves.com/segues-navigation-ios-basics/

// MARK: TODO
// 一件事跨越多天
// 地点调用地图进行选择
// 联系人输入邮箱，发邮件邀请
// 目前使用的datetimepicker不够方便
// 只有列表视图翻起来不方便，最好再加上日历视图
// 添加事务时不合理弹出Alert
// 事务开始前提醒
// 无事务且无节假日的日期可以缩略显示
// 顶部的title展示目前所在的时间范围

import UIKit
import MJRefresh
import Alamofire
import SwiftyJSON
import CoreData

class CalendarViewController: UITableViewController {

    // 日期数组，用refresh动态加载
    // 第一个元素为形如"2019-11-27"的索引，第二个元素为初始显示的文字
    var days:[(String, String)] = []
    
    // 事件数组，通过Delegate添加、编辑，并用CoreData进行本地化
    // key为形如"2019-11-27"的索引，value为该天对应的事件
    var events: [String: [Event]] = [:]
    
    // 每行的行高
    var heights: [String:CGFloat] = [:]
    
    var dateToday = ""
    
    // refresh相关参数
    let pageSize = 15
    var startIndex = 0, endIndex = 0
    
    // 节假日请求接口地址
    let holidayRequestURL = "http://timor.tech/api/holiday/year"
    
    // 日期索引格式
    let dateIndexFormat = "yyyy-MM-dd"
    
    // 一行的高度
    let rowHeight: CGFloat = 44
    
    // 一个事件卡片的高度
    let evHeight: CGFloat = 40
    
    // 时间格式化器
    let formatter = DateFormatter()
    
    // weekday与中文描述对应的map
    // https://stackoverflow.com/questions/27990503/nsdatecomponents-returns-wrong-weekday
    let weekDayMap = [ 1:"星期天", 2:"星期一", 3:"星期二", 4:"星期三", 5:"星期四", 6:"星期五", 7:"星期六" ]
    
    // 年份是否已经获取了节假日信息
    var ifHolidayGot = Set<String>()
    
    // 视图即将出现时完成初始化加载
    override func viewWillAppear(_ animated: Bool) {
        setup()
        if (startIndex == 0){
            loadRefresh(number: pageSize/2, direction: false)
        }
        if (endIndex == 0){
            loadRefresh(number: pageSize, direction: true)
        }
        let year = getDateAsFormat(date: Date(), format: "yyyy")
        if (!ifHolidayGot.contains(year)){
            requestHolidayInfo(year: Int(year)!)
            ifHolidayGot.insert(year)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // tableView.scrollToRow(at: IndexPath(row: pageSize, section: 0), at: .middle, animated: true)
    }
    
    
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
    
    // 请求某天详细信息，参数为该天到今天的距离(之前为负，之后为正)
    private func requestDayInfo(daysFromToday: Int){
        // print("Days from today: \(daysFromToday)")
        
        let date = dateForDayFromNow(daysInterval: daysFromToday)
        // print("Get date info of: \(date)")
        
        let dateKey = getDateAsFormat(date: date, format: "yyyy-MM-dd")
        
        let dateContent = getDateAsFormat(date: date, format: "yyyy.MM.dd")
        
        let weekDayContent = weekDayMap[Calendar.current.component(.weekday, from: date)]!
        
        let year = getDateAsFormat(date: date, format: "yyyy")
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
                    // print("")
                    // print(holiday)
                    let targetDate = holiday["date"].stringValue
                    let name = holiday["name"].stringValue
                    var hEvent = Event()
                    hEvent.type = .Holiday
                    hEvent.title = name
                    self.doAddEvent(targetDateIndex: targetDate, e: hEvent)
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
        
        // days.sort(by: {$0.0 < $1.0})
        
        // 设置对应行高
        // 当前不包含该天时设置，否则会将添加的事件遮盖
        if !heights.keys.contains(dateKey){
            heights[dateKey] = rowHeight
        }
        
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
        // MARK: TODO, this will cause reuse error, reason unknown
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
        
        // 显示该天对应的事件
        // 添加的事件其实也会被重用(duplicated)，看不到是因为高度的原因被隐藏了
        if let getEvents = events[day.0]{
            // print("Get events \(day.0): \(getEvents)")
            
            let evWidth = cell.bounds.width - 32
            let evX = cell.bounds.minX + 16
            
            for (index, getEvent) in getEvents.enumerated() {
                
                // let evY = cell.bounds.minY + rowHeight + index * (evHeight + 2) + 2      // Too long to be compiled
                var evY = cell.bounds.minY + rowHeight + 2
                evY += (CGFloat(index) * (evHeight + 2))
                
                let eventView = UIEventView.init(frame: CGRect(x: evX, y: evY, width: evWidth, height: evHeight))
                // let eventView = UIView.init(frame: CGRect(x: evX, y: evY, width: evWidth, height: evHeight))
                eventView.dateIndex = day.0
                eventView.eventIndex = index
                eventView.event = getEvent
                
                // 根据事件类型设置不同的颜色
                switch getEvent.type {
                case .Task:
                    eventView.backgroundColor = Utils.eventColorArray[getEvent.colorPoint]
                case .Holiday:
                    eventView.backgroundColor = Utils.holidayColor
                case .Adjust:
                    eventView.backgroundColor = Utils.adjustDayColor
                }
                
                eventView.layer.cornerRadius = 5
                
                let titleLabel = UILabel(frame: CGRect(x: eventView.bounds.minX + 16, y: eventView.bounds.minY + 7, width: 200, height: eventView.bounds.height * 0.6))
                titleLabel.text = getEvent.title
                titleLabel.textColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.0)
                titleLabel.adjustsFontSizeToFitWidth = true             // 字体自动适应宽度
                // 避免字体自适应后的位置偏移
                // https://stackoverflow.com/questions/26649909/text-not-vertically-centered-in-uilabel
                titleLabel.baselineAdjustment = .alignCenters
                eventView.addSubview(titleLabel)
                
                if getEvent.type == .Task {
                    let timeLabel = UILabel(frame: CGRect(x: eventView.bounds.maxX - 120, y: eventView.bounds.minY + 7, width: 150, height: eventView.bounds.height * 0.6))
                    
                    let startTime = getDateAsFormat(date: getEvent.startTime, format: "HH:mm")
                    let endTime = getDateAsFormat(date: getEvent.endTime, format: "HH:mm")
                    
                    timeLabel.text = "\(startTime) ~ \(endTime)"
                    timeLabel.textColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.0)
                    
                    // 任务添加点击事件
                    let gesture = UITapGestureRecognizer(target: self, action: #selector(eventViewTapped))
                    eventView.addGestureRecognizer(gesture)
                    
                    eventView.addSubview(timeLabel)
                }
                cell.addSubview(eventView)
                
            }
        }
        
        return cell
    }
    
    // 点击事件视图
    @objc func eventViewTapped(sender: UITapGestureRecognizer){
        // print("Event view tapped!")
        let getView = sender.view as! UIEventView
        let detailController: EventProcessController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "AddEventController") as! EventProcessController
        // 传递数据
        detailController.dateIndex = getView.dateIndex
        detailController.eventIndex = getView.eventIndex
        detailController.currentEvent = getView.event!
        detailController.enterType = .Show          // 仅展示
        
        detailController.delegate = self
        navigationItem.backBarButtonItem?.title = "返回"
        
        show(detailController, sender: self)
        /*
        let detailController = EventDetailViewController()
        // 传递数据
        detailController.dateIndex = getView.dateIndex
        detailController.eventIndex = getView.eventIndex
        detailController.event = getView.event
        // 设置代理
        detailController.deleteDelegate = self
        detailController.editDelegate = self
        // 展示详细内容
        //show(detailController, sender: self)
        present(detailController, animated: true, completion: nil)
        */
    }
    
    
    // 设置每个cell的高度
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(heights[days[indexPath.row].0]!)
    }
    
    
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
            dest.enterType = .Add
        }
    }
    
    // 获取Date的指定部分
    private func getDateAsFormat(date: Date, format: String) -> String {
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    private func doAddEvent(targetDateIndex: String, e: Event){
        if events.keys.contains(targetDateIndex) {
            events[targetDateIndex]!.append(e)
            events[targetDateIndex]!.sort(by: {$0.startTime < $1.startTime})
        } else {
            events[targetDateIndex] = [e]
        }
        
        if heights.keys.contains(targetDateIndex){
            heights[targetDateIndex]! += (evHeight + 2)
        } else {
            // print("Here again!")
            heights[targetDateIndex] = rowHeight + evHeight + 2
        }
    }
    
    
    @IBAction func backToToday(_ sender: UIBarButtonItem) {
        tableView.scrollToRow(at: IndexPath(row: -startIndex - 8, section: 0), at: .middle, animated: true)
    }
    
    /*
    @IBAction func testLoadFromStoryBoard(_ sender: Any) {
        // 从storyboard加载View Controller
        // https://coderwall.com/p/cjuzng/swift-instantiate-a-view-controller-using-its-storyboard-name-in-xcode
        let vc: AddEventController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "AddEventController") as! AddEventController
        show(vc, sender: self)
        // present(vc, animated: true, completion: nil)
    }
    */
}

extension CalendarViewController: EventProcessDelegate {
    func addEvent(e: Event){
        let targetDateIndex = getDateAsFormat(date: e.startTime, format: dateIndexFormat)
        doAddEvent(targetDateIndex: targetDateIndex, e: e)
        tableView.reloadData()
    }
    func editEvent(e: Event, dateIndex: String, eventIndex: Int){
        if let eventsOfDay = events[dateIndex], eventsOfDay.count - 1 >= eventIndex {
            events[dateIndex]![eventIndex] = e
        } else {
            print("Edit error, event does not exist.")
        }
        tableView.reloadData()
    }
    func deleteEvent(dateIndex: String, eventIndex: Int){
        if let eventsOfDay = events[dateIndex], eventsOfDay.count - 1 >= eventIndex {
            events[dateIndex]!.remove(at: eventIndex)
            if events[dateIndex]!.count == 0{
                events[dateIndex] = nil
            }
        } else {
            print("Delete error, event does not exist.")
        }
        heights[dateIndex]! -= (evHeight + 2)
        tableView.reloadData()
    }
}
