//
//  InitCalendarController.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/11/25.
//  Copyright © 2019 dks. All rights reserved.
//

// References:
// 1. https://github.com/CoderMJLee/MJRefresh

import UIKit
import MJRefresh

class InitCalendarController: UITableViewController {

    // 事件数组，通过Delegate添加、编辑，并用CoreData进行本地化
    var events:[Event] = []
    
    // 日期数组，用refresh动态加载
    var days = NSMutableArray()
    
    // refresh相关参数
    let pageSize = 15
    var startIndex = 0, endIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        
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
        
        upPullRefresh()
        
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

        cell.dateLabel.text = days[indexPath.row] as? String
        
        return cell
    }
    
    // 下拉刷新
    @objc private func downPullRefresh() {
        // TODO: insert at one time
        for i in ((startIndex - pageSize) ..< startIndex).reversed() {
            days.insert("这是日历第\(i)行", at: 0)
        }
        
        startIndex -= pageSize
        tableView.reloadData()
        tableView.mj_header.endRefreshing()
    
    }
    
    // 上拉刷新
    @objc private func upPullRefresh() {
        // TODO: add at one time
        for i in (endIndex ..< (endIndex + pageSize)) {
            days.add("这是日历第\(i)行")
        }
        
        endIndex += pageSize
        tableView.reloadData()
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
    
    
    private func showEvents(){
        print("")
        for e in events {
            print("\(e.title), \(e.startTime), \(e.endTime)")
        }
    }
    

}

extension InitCalendarController: EditEventDelegate {
    func addEvent(e: Event) {
        print("Add event in init calendar controller.")
        events.append(e)
        showEvents()
        tableView.reloadData()
    }
    
    func editEvent(e: Event) {
        print("Edit event in init calendar controller.")
    }
    
    
}
