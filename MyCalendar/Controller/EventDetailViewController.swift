//
//  EventDetailViewController.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/11/29.
//  Copyright © 2019 dks. All rights reserved.
//

import UIKit

protocol DeleteEventDelegate {
    // func editEvent(dateIndex: String, eventIndex: Int, newEvent: Event)
    func deleteEvent(dateIndex: String, eventIndex: Int)
}

protocol EditEventSecondDelegate {
    func editEventSecond(e: Event, dateIndex: String, eventIndex: Int)
}

class EventDetailViewController: UIViewController {

    var dateIndex: String?
    var eventIndex: Int?
    var event: Event?
    
    var deleteDelegate: DeleteEventDelegate?
    var editDelegate: EditEventSecondDelegate?
    
    override func loadView() {
        // 创建当前controller的根视图
        view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        view.backgroundColor = UIColor.white
        
        // 添加视图
        /*
        let titleText = UITextField(frame: CGRect(x: 20, y: 92, width: 200, height: 34))
        titleText.text = event!.title
        titleText.borderStyle = .none
        titleText.isUserInteractionEnabled = false
        view.addSubview(titleText)
        */
        
        let titleLabel = UILabel(frame: CGRect(x: 20, y: 105, width: 150, height: 21))
        titleLabel.text = event!.title
        // https://stackoverflow.com/questions/24356888/how-do-i-change-the-font-size-of-a-uilabel-in-swift
        titleLabel.font = titleLabel.font.withSize(20)
        view.addSubview(titleLabel)
        
        let closeButton = UIButton(frame: CGRect(x: 16, y: 57, width: 30, height: 30))
        closeButton.setImage(UIImage(named: "close"), for: .normal)
        // closeButton.setImage(#imageLiteral(resourceName: "close"), for: .normal)     // 两种方法一样
        
        closeButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        view.addSubview(closeButton)
        
        let editButton = UIButton(frame: CGRect(x: 292, y: 57, width: 50, height: 30))
        editButton.setTitle("编辑", for: .normal)
        // 默认的字体颜色是白色，可能因此导致按钮不可见
        editButton.setTitleColor(UIColor(red:0.13, green:0.65, blue:0.94, alpha:1.0), for: .normal)
        editButton.isUserInteractionEnabled = true
        editButton.addTarget(self, action: #selector(editButtonClicked), for: .touchUpInside)
        view.addSubview(editButton)
        
        let deleteButton = UIButton(frame: CGRect(x: 352, y: 57, width: 50, height: 30))
        //deleteButton.titleLabel?.text = "删除"      // 设置button文字的错误方式
        deleteButton.setTitle("删除", for: .normal)
        deleteButton.setTitleColor(UIColor.red, for: .normal)
        deleteButton.isUserInteractionEnabled = true
        deleteButton.addTarget(self, action: #selector(deleteButtonClicked), for: .touchUpInside)
        view.addSubview(deleteButton)
        
        let timeImage = UIImageView(frame: CGRect(x: 20, y: 146, width: 36, height: 37))
        timeImage.image = #imageLiteral(resourceName: "clock")
        view.addSubview(timeImage)
        
        let timeLabel = UILabel(frame: CGRect(x: 80, y: 155, width: 200, height: 21))
        let st = getDateAsFormat(date: event!.startTime, format: "HH:mm")
        let et = getDateAsFormat(date: event!.endTime, format: "HH:mm")
        timeLabel.text = "\(st) ~ \(et)"
        view.addSubview(timeLabel)
        
        let locationImage = UIImageView(frame: CGRect(x: 20, y: 203, width: 36, height: 37))
        locationImage.image = #imageLiteral(resourceName: "location")
        view.addSubview(locationImage)
        
        let locationLabel = UILabel(frame: CGRect(x: 80, y: 211, width: 200, height: 21))
        locationLabel.text = event!.location
        view.addSubview(locationLabel)
        
        let peopleImage = UIImageView(frame: CGRect(x: 20, y: 260, width: 36, height: 37))
        peopleImage.image = #imageLiteral(resourceName: "people")
        view.addSubview(peopleImage)
        
        let peopleLabel = UILabel(frame: CGRect(x: 80, y: 268, width: 250, height: 21))
        peopleLabel.text = event!.invitations?[0]
        view.addSubview(peopleLabel)
        
        let noteLabel = UILabel(frame: CGRect(x: 20, y: 321, width: 60, height: 21))
        noteLabel.text = "备注："
        view.addSubview(noteLabel)
        
        let noteTextField = UITextField(frame: CGRect(x: 20, y: 358, width: 363, height: 34))
        noteTextField.text = event!.note
        noteTextField.isUserInteractionEnabled = false      // 设为只读
        view.addSubview(noteTextField)
        
        
        let line1 = UIView(frame: CGRect(x: 16, y: 134, width: 374, height: 1))
        let line2 = UIView(frame: CGRect(x: 16, y: 191, width: 374, height: 1))
        let line3 = UIView(frame: CGRect(x: 16, y: 248, width: 374, height: 1))
        let line4 = UIView(frame: CGRect(x: 16, y: 305, width: 374, height: 1))
        line1.backgroundColor = UIColor.gray
        line2.backgroundColor = UIColor.gray
        line3.backgroundColor = UIColor.gray
        line4.backgroundColor = UIColor.gray
        view.addSubview(line1)
        view.addSubview(line2)
        view.addSubview(line3)
        view.addSubview(line4)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // 获取Date的指定部分
    private func getDateAsFormat(date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    @objc func closeButtonClicked(){
        dismiss(animated: true, completion: nil)
    }
    
    @objc func editButtonClicked(){
        // print("Edit button clicked")
        let vc: AddEventController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "AddEventController") as! AddEventController
        
        // TODO: 添加保存按钮
        
        let cancelButton = UIButton(frame: CGRect(x: 16, y: 560, width: 50, height: 30))
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(UIColor.red, for: .normal)
        cancelButton.isUserInteractionEnabled = true
        cancelButton.addTarget(self, action: #selector(cancelEditButtonClicked), for: .touchUpInside)
        vc.view.addSubview(cancelButton)
         
        
        let confirmButton = UIButton(frame: CGRect(x: 350, y: 560, width: 50, height: 30))
        confirmButton.setTitle("保存", for: .normal)
        confirmButton.setTitleColor(UIColor(red:0.13, green:0.65, blue:0.94, alpha:1.0), for: .normal)
        confirmButton.isUserInteractionEnabled = true
        confirmButton.addTarget(vc, action: #selector(vc.confirmEditButtonClicked), for: .touchUpInside)
        vc.view.addSubview(confirmButton)
        
        
        vc.currentEvent = self.event!
        vc.dateIndex = self.dateIndex
        vc.eventIndex = self.eventIndex
        vc.editDelegate = self
        vc.enterType = .Edit
        
        present(vc, animated: true, completion: nil)
        
    }
    
    @objc func deleteButtonClicked(){
        // print("Delete button clicked")
        deleteDelegate?.deleteEvent(dateIndex: dateIndex!, eventIndex: eventIndex!)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func cancelEditButtonClicked(){
        dismiss(animated: true, completion: nil)
    }
    
    
    //@objc func confirmEditButtonClicked(sender: UIViewController){
        //print("Confim button clicked in event detail view controller.")
        
        //let vc = (sender as! UIButton)
        //dismiss(animated: true, completion: nil)
        //print(vc.titleTextField.text)
    //}
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension EventDetailViewController: EditEventDelegate {
    func editEvent(e: Event, dateIndex: String, eventIndex: Int) {
        // Dismiss all modal view controllers
        // https://stackoverflow.com/questions/47322379/swift-how-to-dismiss-all-of-view-controllers-to-go-back-to-root/47322464
        DispatchQueue.main.async {
            self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        }
        
        //print("Edit event in event detail view controller")
        //print("event title: \(e.title)")
        editDelegate?.editEventSecond(e: e, dateIndex: dateIndex, eventIndex: eventIndex)
        //dismiss(animated: false, completion: nil)
        
    }
}
