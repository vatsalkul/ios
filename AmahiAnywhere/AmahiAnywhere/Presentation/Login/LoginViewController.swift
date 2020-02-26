//
//  LoginViewController.swift
//  AmahiAnywhere
//
//  Created by Carlos Puchol on 1/27/18.
//  Copyright © 2018 Amahi. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField

class LoginViewController: BaseUIViewController {

    @IBOutlet private weak var usernameInputField: SkyFloatingLabelTextField!
    @IBOutlet private weak var passwordInputField: SkyFloatingLabelTextField!
    @IBOutlet private weak var showHideButton: UIButton!
    
    private var presenter: LoginPresenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()

        presenter = LoginPresenter(self)
        
        usernameInputField.delegate = self
        passwordInputField.delegate = self
        
        setupPasswordFieldPadding()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        usernameInputField.text = ""
        passwordInputField.text = ""
        passwordInputField.isSecureTextEntry = true
        showHideButton.setImage(UIImage(named: "passHidden"), for: .normal)
        showHideButton.isHidden = true
        
    }
    
    func setupPasswordFieldPadding(){
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 64, height: passwordInputField.frame.height))
        passwordInputField.rightView = paddingView
        passwordInputField.rightViewMode = .always
    }
    
    @IBAction func passFieldChanged(_ sender: Any) {
        showHideButton.isHidden = !passwordInputField.hasText
    }
    
    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameInputField {
            passwordInputField.becomeFirstResponder()
        }else if textField == passwordInputField {
            textField.resignFirstResponder()
            userclickSignIn(self)
        }
        
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        (textField as! SkyFloatingLabelTextField).errorMessage = nil
        return true
    }
    
    func checkInputsValid() -> Bool {
        var isValid = true
        
        if (usernameInputField.text?.isEmpty)! {
            showFieldErrorMessage(textField: usernameInputField)
            isValid = false
        }
        
        if (passwordInputField.text?.isEmpty)! {
            showFieldErrorMessage(textField: passwordInputField)
            isValid = false
        }
        
        return isValid
    }
    
    func showFieldErrorMessage(textField: SkyFloatingLabelTextField){
        textField.errorColor = .red
        textField.errorMessage = StringLiterals.fieldIsRequired
    }
    
    @IBAction func userClickForgotPassword(_ sender: UIButton) {
        UIApplication.shared.open(NSURL(string:"https://www.amahi.org/forgot")! as URL)
    }
    
    @IBAction func userclickSignIn(_ sender: Any) {
        if checkInputsValid(){
            presenter.login(username: usernameInputField.text!, password: passwordInputField.text!)
        }
    }
    
    @IBAction func showHideTapped(_ sender: UIButton) {
        if passwordInputField.isSecureTextEntry{
            showHideButton.setImage(UIImage(named: "passShown"), for: .normal)
        }else{
            showHideButton.setImage(UIImage(named: "passHidden"), for: .normal)
        }
        
        passwordInputField.isSecureTextEntry = !passwordInputField.isSecureTextEntry
    }
    
}

// Mark - Login view implementations
extension LoginViewController: LoginView {
    
    func showHome() {
        let serverVc = self.instantiateViewController (withIdentifier: "RootVC", from: StoryBoardIdentifiers.main)
        self.present(serverVc, animated: true, completion: nil)
    }
    
}
