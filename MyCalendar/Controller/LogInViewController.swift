//
//  LogInViewController.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/12/10.
//  Copyright © 2019 dks. All rights reserved.
//

// MARK: -TODOs
// 1. Push notification https://www.iosapptemplates.com/blog/ios-development/push-notifications-firebase-swift-5

import UIKit

class LogInViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passWordTextField: UITextField!
    
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var lineView: UIView!
    
    // 当前是否可登录
    var ifLoggedIn = false
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // https://stackoverflow.com/questions/29209453/how-to-hide-a-navigation-bar-from-first-viewcontroller-in-swift
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        lineView.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        messageLabel.isHidden = true
        messageLabel.layer.masksToBounds = true
        messageLabel.layer.cornerRadius = 5
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.baselineAdjustment = .alignCenters
        
        setupTextFields()
        
        // 编辑时打开清除按钮
        emailTextField.clearButtonMode = .whileEditing
        passWordTextField.clearButtonMode = .whileEditing
        
        emailTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // 添加输入完成按钮
    private func setupTextFields() {
        let toolBar = UIToolbar(frame: CGRect(origin: .zero, size: .init(width: view.frame.width, height: 30)))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(doneButtonAction))
        
        toolBar.setItems([flexSpace, doneBtn], animated: false)
        toolBar.sizeToFit()
        
        self.emailTextField.inputAccessoryView = toolBar
        self.passWordTextField.inputAccessoryView = toolBar
    }
    
    @objc func doneButtonAction(){
        self.view.endEditing(true)
    }
    
    
    @IBAction func logInButtonClicked(_ sender: UIButton) {
        let loginManager = FirebaseAuthManager()
        // res is true if sign up successfully, else res is false.
        if let email = emailTextField.text, let password = passWordTextField.text {
            if validateInput() {
                loginManager.loginUser(email: email, password: password){ res in
                    if !res { self.showMessage(message: "邮箱或密码不正确，请重试", color: UIColor.red) }
                    else {
                        self.showMessage(message: "欢迎！", color: UIColor(red:0.15, green:0.76, blue:0.51, alpha:1.0))
                        self.ifLoggedIn = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {self.performSegue(withIdentifier: "loginSegue", sender: self)})
                    }
                }
            }
        }
    }
    
    
    private func validateInput() -> Bool {
        if emailTextField.text == nil || emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            showMessage(message: "邮箱不能为空!", color: UIColor.red)
            ifLoggedIn = false
            return false
        }
        if passWordTextField.text == nil || passWordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            showMessage(message: "密码不能为空!", color: UIColor.red)
            ifLoggedIn = false
            return false
        }
        if !emailTextField.text!.isValidEmail() {
            showMessage(message: "不是合法的邮箱地址!", color: UIColor.red)
            ifLoggedIn = false
            return false
        }
        
        if passWordTextField.text!.count < 6 {
            showMessage(message: "密码不能少于6位", color: UIColor.red)
            ifLoggedIn = false
            return false
        }
        
        return true
    }
    
    private func showMessage(message: String, color: UIColor) {
        messageLabel.text = message
        messageLabel.isHidden = false
        messageLabel.backgroundColor = color
        // https://learnappmaking.com/timer-swift-how-to/#executing-code-with-a-delay
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: {
            self.messageLabel.isHidden = true
        })
    }
    
    // https://stackoverflow.com/questions/24614755/conditional-segue-in-swift
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "loginSegue" {
            return ifLoggedIn
        }
        return true
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
}

// https://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
extension String {
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}
