//
//  TaskCell.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/11/26.
//  Copyright © 2019 dks. All rights reserved.
//

import Foundation
import FoldingCell

class TaskCell: FoldingCell {
    
    @IBOutlet weak var detailTimeView: UIView!
    
    @IBOutlet weak var locationView: UIView!
    
    @IBOutlet weak var peopleView: UIView!
    
    @IBOutlet weak var noteView: UIView!
    
    @IBOutlet weak var startTimeLabel: UILabel!
    
}
