//
//  SignUpViewController.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/12/10.
//  Copyright © 2019 dks. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {

    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passWordTextField: UITextField!
    
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    @IBOutlet weak var messageLabel: UILabel!
    
    var ifSignedUp = false
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        messageLabel.isHidden = true
        messageLabel.layer.cornerRadius = 5
        messageLabel.layer.masksToBounds = true
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.baselineAdjustment = .alignCenters
        
        setupTextFields()
        
        emailTextField.clearButtonMode = .whileEditing
        passWordTextField.clearButtonMode = .whileEditing
        confirmPasswordTextField.clearButtonMode = .whileEditing
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
        self.confirmPasswordTextField.inputAccessoryView = toolBar
    }
    
    @objc func doneButtonAction(){
        self.view.endEditing(true)
    }
    
    @IBAction func signUpButtonClicked(_ sender: UIButton) {
        let signUpManager = FirebaseAuthManager()
        // res is true if sign up successfully, else res is false.
        if let email = emailTextField.text, let password = passWordTextField.text {
            if validateInput() {
                signUpManager.createUser(email: email, password: password){ res in
                    if res {
                        self.showMessage(message: "注册成功!", color: UIColor(red:0.15, green:0.76, blue:0.51, alpha:1.0))
                        self.ifSignedUp = true
                        self.performSegue(withIdentifier: "signUpSuccessSegue", sender: self)
                    } else {
                        fatalError("注册失败!")
                    }
                }
            }
            
        }
    }
    
    @IBAction func cancelButtonClicked(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    
    private func validateInput() -> Bool {
        if emailTextField.text == nil || emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            showMessage(message: "邮箱不能为空!", color: UIColor.red)
            ifSignedUp = false
            return false
        }
        
        if passWordTextField.text == nil || passWordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            showMessage(message: "密码不能为空!", color: UIColor.red)
            ifSignedUp = false
            return false
        }
        
        if confirmPasswordTextField.text == nil || confirmPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            showMessage(message: "确认密码不能为空!", color: UIColor.red)
            ifSignedUp = false
            return false
        }
        
        if !emailTextField.text!.isValidEmail() {
            showMessage(message: "不是合法的邮箱地址!", color: UIColor.red)
            ifSignedUp = false
            return false
        }
        if passWordTextField.text!.count < 6 {
            showMessage(message: "密码不能少于6位", color: UIColor.red)
            ifSignedUp = false
            return false
        }
        
        if passWordTextField.text! != confirmPasswordTextField.text! {
            showMessage(message: "密码不一致!", color: UIColor.red)
            ifSignedUp = false
            return false
        }
        
        
        return true
    }
    
    
    private func showMessage(message: String, color: UIColor) {
        messageLabel.text = message
        messageLabel.isHidden = false
        messageLabel.backgroundColor = color
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: {
            self.messageLabel.isHidden = true
        })
        
    }
    
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "signUpSuccessSegue" {
            return ifSignedUp
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


