//
//  InitCalendarController.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/11/25.
//  Copyright © 2019 dks. All rights reserved.
//

// References:
// 1. https://github.com/CoderMJLee/MJRefresh


// MARK: TODO
// 在未加载的日期添加事件
// 一件事跨越多天
// 点击事务卡片弹出详细视图
// 地点调用地图进行选择
// 联系人输入邮箱，发邮件邀请

import UIKit
import MJRefresh
import Alamofire
import SwiftyJSON

class InitCalendarController: UITableViewController {

    // 日期数组，用refresh动态加载
    // 第一个元素为形如"2019-11-27"的索引，第二个元素为初始显示的文字
    var days:[(String, String)] = []
    
    // 事件数组，通过Delegate添加、编辑，并用CoreData进行本地化
    // key为形如"2019-11-27"的索引，value为该天对应的事件
    var events: [String: [Event]] = [:]
    
    // 每行的行高
    var heights: [String:CGFloat] = [:]
    
    // refresh相关参数
    let pageSize = 2        // 请求次数每天限100次，省着点用
    var startIndex = 0, endIndex = 0
    
    // 日历请求接口地址
    let requestURL = "http://v.juhe.cn/calendar/day"        // 当前日期详细信息
    // 日历请求账号标识
    let calendarAppkey = "3fb0cb0d93e61a2b4bfe80d74922735c"
    
    // 请求的日期参数格式
    let requestDateFormat = "yyyy-M-d"
    // 日期索引格式
    let dateIndexFormat = "yyyy-MM-dd"
    
    // 一行的高度
    let rowHeight: CGFloat = 44
    
    // 一个事件卡片的高度
    let evHeight: CGFloat = 40
    
    // 时间格式化器
    let formatter = DateFormatter()
    
    
    // 视图即将出现时完成初始化加载
    override func viewWillAppear(_ animated: Bool) {
        setup()
        if (endIndex == 0){
            upPullRefresh()
        }
        if (startIndex == 0){
            downPullRefresh()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
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
        let getDate = Date.init(timeIntervalSinceNow: 60*60*24*Double(daysFromToday))
        let requestDate = getDateAsFormat(date: getDate, format: requestDateFormat) // 发送请求的日期格式
        let dateKey = getDateAsFormat(date: getDate, format: dateIndexFormat)       // 加入days数组中用于查询的索引
        
        print("Request date: \(requestDate)")
        
        let parameters = [
            "key": calendarAppkey,
            "date": requestDate
        ]
        
        // 当请求次数用完时用于调试的替代内容
        
        //let content = "aaaaaaaaaaaaaaaaa"
        //updateDataSource(content: content, index: daysFromToday, dateKey: dateKey)
        
        
        Alamofire.request(requestURL, parameters: parameters).responseJSON(completionHandler: { response in
            if let json = response.result.value {
                let dataJSON = JSON(json)
                    
                let dateToday = dataJSON["result","data","date"].stringValue
                let weekday = dataJSON["result","data","weekday"].stringValue
                let lunar = dataJSON["result","data","lunar"].stringValue
                    
                // 获取显示的内容
                //let content = "\(dateToday) \(weekday) 农历\(lunar)"
                let content = "11.28 星期四 农历十一月初三"
                //print("Content: \(content)")
                self.updateDataSource(content: content, index: daysFromToday, dateKey: dateKey)
            }
        })
        
        
    }
    
    
    // 请求某天所在月份的节假日信息，参数为该天到今天的距离(之前为负，之后为正)
    private func requestHolidayInfo(aroundDateFromToday: Int){
        
    }
    
    // 更新数据源
    private func updateDataSource(content: String, index: Int, dateKey: String){
        
        // print("Update data: \(content)")
        
        index < 0 ? days.insert((dateKey, content), at: 0) : days.append((dateKey, content))
        days.sort(by: {$0.0 < $1.0})
        
        // 设置对应行高
        heights[dateKey] = rowHeight
        
        // MARK: TODO 不需要每次都重新加载tableview
        tableView.reloadData()
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
        
        // 显示该天对应的事件
        if let getEvents = events[day.0]{
            // print("Get events \(day.0): \(getEvents)")
            
            let evWidth = cell.bounds.width - 32
            let evX = cell.bounds.minX + 16
            
            for (index, getEvent) in getEvents.enumerated() {
                
                // let evY = cell.bounds.minY + rowHeight + index * (evHeight + 2) + 2      // Too long to be compiled
                var evY = cell.bounds.minY + rowHeight + 2
                evY += (CGFloat(index) * (evHeight + 2))
                let eventView = UIView.init(frame: CGRect(x: evX, y: evY, width: evWidth, height: evHeight))
                eventView.backgroundColor = getEvent.color!
                eventView.layer.cornerRadius = 5
                
                let label = UILabel(frame: CGRect(x: eventView.bounds.minX + 16, y: eventView.bounds.minY + 7, width: eventView.bounds.width * 0.8, height: eventView.bounds.height * 0.6))
                
                
                let startTime = getDateAsFormat(date: getEvent.startTime, format: "HH:mm")
                let endTime = getDateAsFormat(date: getEvent.endTime, format: "HH:mm")
                label.text = "\(getEvent.title)    \(startTime) ~ \(endTime)"
                label.textColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.0)
                eventView.addSubview(label)
                cell.addSubview(eventView)
                
            }
        }
        
        return cell
    }
    
    
    // 设置每个cell的高度
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(heights[days[indexPath.row].0]!)
    }
    
    
    // 下拉刷新
    @objc private func downPullRefresh() {
        
        for i in ((startIndex - pageSize) ..< startIndex).reversed() {
            DispatchQueue.global(qos: .userInteractive).async {
                self.requestDayInfo(daysFromToday: i)
            }
        }
        
        startIndex -= pageSize
        tableView.mj_header.endRefreshing()
    
    }
    
    // 上拉刷新
    @objc private func upPullRefresh() {
        
        for i in (endIndex ..< (endIndex + pageSize)) {
            DispatchQueue.global(qos: .userInteractive).async {
                self.requestDayInfo(daysFromToday: i)
            }
        }
        
        endIndex += pageSize
        tableView.mj_footer.endRefreshing()
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
            let dest = (segue.destination) as! AddEventController
            dest.delegate = self
        }
        
    }
    
    // 获取Date的指定部分
    private func getDateAsFormat(date: Date, format: String) -> String {
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
}

extension InitCalendarController: EditEventDelegate {
    func addEvent(e: Event) {
        // print("Add \(e) in init calendar controller.")
        
        let targetDateIndex = getDateAsFormat(date: e.startTime, format: dateIndexFormat)
        
        if events.keys.contains(targetDateIndex) {
            events[targetDateIndex]!.append(e)
            events[targetDateIndex]!.sort(by: {$0.startTime < $1.startTime})
        } else {
            events[targetDateIndex] = [e]
        }
        // print("Events: \(events)")
        
        // MARK: TODO what if this day hasn't been loaded?
        // 则从当前位置加载到那一天，并显示上去
        if heights.keys.contains(targetDateIndex){
            heights[targetDateIndex]! += (evHeight + 2)
        } else {
            
            heights[targetDateIndex] = rowHeight + evHeight + 2
        }
        
        tableView.reloadData()
        
    }
    
    
}
