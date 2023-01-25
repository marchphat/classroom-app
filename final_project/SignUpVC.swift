//
//  ViewController.swift
//  final_project
//
//  Created by Nantanat Thongthep on 2/12/2564 BE.
//

import UIKit
import GoogleSignIn
import GRDB

class SignUpVC: UIViewController {
    
    //ui
    @IBOutlet weak var firstnameTextField: UITextField!
    @IBOutlet weak var lastnameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passTextField: UITextField!
    @IBOutlet weak var conpassTextField: UITextField!

    @IBOutlet weak var nameDesc: UILabel!
    @IBOutlet weak var emailDesc: UILabel!
    @IBOutlet weak var passDesc: UILabel!
    @IBOutlet weak var conpassDesc: UILabel!
    
    @IBOutlet weak var signUpGoogle: UIButton!

    var validatorType: TextFieldValidatorType! = .None

    //sign up with google
    var existsGmail: Bool = false
    let signInConfig = GIDConfiguration.init(clientID: "629469457357-8ra2vg115qg2g1kflu2di04f83he5eet.apps.googleusercontent.com")
    
    //session
    var userData = [String]()
    var defaults = UserDefaults.standard
    
    //database
    var dbPath : String = ""
    var dbResourcePath : String = ""
    var config = Configuration()
    let fileManager = FileManager.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setInterface()
        connect2DB()
    }
    
    // MARK: - Interface
    
    func setInterface() {
        signUpGoogle.layer.cornerRadius = 6
        signUpGoogle.layer.borderWidth = 1
        signUpGoogle.layer.borderColor = UIColor.lightGray.cgColor
        
        nameDesc.text = " "
        emailDesc.text = " "
        passDesc.text = " "
        conpassDesc.text = " "
    }
    
    // MARK: - Action
    
    @IBAction func signUpWithGoogle(_ sender: Any) {
        GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: self) { user, error in
            guard error == nil else { return }
            guard let user = user else { return }
            
            /* let fullName = user.profile?.name
            let profilePicUrl = user.profile?.imageURL(withDimension: 320) */
            let givenName = user.profile?.givenName
            let familyName = user.profile?.familyName
            let emailAddress = user.profile?.email
            
            self.selectQuery(user_email: emailAddress!, "Sign up with google")
            if !self.existsGmail {
                self.insert2AR(firstname: givenName!, lastname: familyName!, email: emailAddress!, password: "email")
                self.insertQuery()
                self.changeView("signUpwithGoogle")
            } else {
                self.alert("Email already exists")
            }
        }
    }
    
    @IBAction func textFieldDidEndEditing(_ textField: UITextField) {
        checkTextFieldType(textField)
        selectQuery(user_email: emailTextField.text!, "Sign Up")
    }
    
    @IBAction func textFieldDidTextChange(_ textField: UITextField) {
        checkTextFieldType(textField)
    }
    
    @IBAction func signUp(_ sender: Any) {
        if textFieldisComplete() {
            insert2AR(firstname: firstnameTextField.text!, lastname: lastnameTextField.text!, email: emailTextField.text!, password: passTextField.text!)
            insertQuery()
            changeView("signUp")
        }
        else {
            alert("Please fill up this form")
        }
    }
    
    @IBAction func signIn(_ sender: Any) {
        changeView("signIn")
    }
    
    // MARK: - Validator
    
    func checkTextFieldType(_ textField: UITextField) {
        let tag = textField.tag

        switch tag {
        case 0:
            validatorType = .Firstname
            validate(textField, tag)
        case 1:
            validatorType = .Lastname
            validate(textField, tag)
        case 2:
            validatorType = .Email
            validate(textField, tag)
        case 3:
            validatorType = .Password
            validate(textField, tag)
        case 4:
            validate(textField, tag)
        default:
            validatorType = .None
        }
    }
    
    func validate(_ textField: UITextField, _ tag: Int) {
        let label:[UILabel] = [nameDesc, nameDesc, emailDesc, passDesc, conpassDesc]
        guard let text = textField.text else { return }
        let validatedText = validatorType.validate(text)
        
        if tag == 4 {
            if text != passTextField.text {
                validateHandler(false, textField, label[tag], "Passwords do not match")
            } else {
                validateHandler(true, textField, label[tag], "")
            }
        }
        else {
            validateHandler(validatedText.result, textField, label[tag], validatedText.desc)
        }
    }
    
    func textFieldisComplete() -> Bool {
        let textField: [UITextField] = [firstnameTextField, lastnameTextField, emailTextField, passTextField, conpassTextField]
        var isComplete = true
        
        for field in textField {
            if field.text!.isEmpty || field.layer.borderColor == UIColor.red.cgColor {
                isComplete = false
            }
        }
        return isComplete
    }

    // MARK: - Error Handler
    
    func validateHandler(_ isSuccess: Bool, _ textField: UITextField, _ validationDescLabel: UILabel, _ desc: String) {
        if isSuccess {
            textField.layer.borderColor = #colorLiteral(red: 0.8000000119, green: 0.8000000119, blue: 0.8000000119, alpha: 1)
        } else {
            textField.layer.borderColor = UIColor.red.cgColor
        }
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 5
        validationDescLabel.text = desc
    }
    
    func alert(_ message: String) {
        let alertVC = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alertVC, animated: true, completion: nil)
    }
    
    // MARK: - Store Data
    
    func insert2AR(firstname: String, lastname: String, email: String, password: String) {
        userData.insert(firstname, at: 0)
        userData.insert(lastname, at: 1)
        userData.insert(email, at: 2)
        userData.insert(password, at: 3)
        defaults.set(userData, forKey: "savedUser")
    }
        
    // MARK: - Database
    
    func connect2DB() {
        config.readonly = true
        do {
            dbPath = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("final_project.sqlite")
                .path
            if !fileManager.fileExists(atPath: dbPath) {
                dbResourcePath = Bundle.main.path(forResource: "final_project", ofType: "sqlite")!
                try fileManager.copyItem(atPath: dbResourcePath, toPath: dbPath)
            }
        } catch {
            print("An error has occured")
        }
    }
    
    func insertQuery() {
        do {
            config.readonly = false
            let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)
            
            try dbQueue.write {
                db in
                try db.execute(sql: "INSERT INTO user (user_firstname, user_lastname, user_email, user_password) VALUES (?, ?, ?, ?)", arguments: [userData[0], userData[1], userData[2], userData[3]])
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func selectQuery(user_email: String, _ action: String) {
        do {
            let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)
            try dbQueue.inDatabase { db in
                
                let rows = try Row.fetchCursor(db, sql: "SELECT user_email FROM user WHERE user_email = (?)", arguments: [user_email])
                
                while let _ = try rows.next() {
                    if action == "Sign up with google" {
                        existsGmail = true
                    } else {
                        validateHandler(false, emailTextField, emailDesc, "Email already exists")
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Change View
    
    func changeView(_ button: String) {
        if userData.count == 4 {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let navigationView = storyboard.instantiateViewController(withIdentifier: "navigationView")
            
            self.view.window?.rootViewController = navigationView
        }
        if button == "signIn" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let signInView = storyboard.instantiateViewController(withIdentifier: "signInView") as! SignInVC
            
            self.view.window?.rootViewController = signInView
        }
    }
}

extension SignUpVC {
    
    enum TextFieldValidatorType {
        case Password
        case Email
        case Firstname
        case Lastname
        case None
        
        func validate(_ text: String) -> (result: Bool, desc: String) {
            
            switch self {
            case .Password:
                if (text.count < 8) {
                    return (false, "Password must longer than 8 characters")
                } else if (text.count > 16) {
                    return (false, "Password must not longer than 16 characters")
                } else if (text.hasSpecialCharacters()) {
                    return (false, "Password cannot contain any special character")
                }
                return (true, "")
    
            case .Email:
                if (!text.isEmailFormat()) {
                    return (false, "Invalid email format")
                }
                return (true, "")
                
            case .Firstname:
                if (text.count < 2) {
                    return (false, "Your name must longer than 1 characters")
                } else if (!text.isCharacter()) {
                    return (false, "Only character is allowed")
                }
                return (true, "")
                
            case .Lastname:
                if (text.count < 2) {
                    return (false, "Your name must longer than 1 characters")
                } else if (!text.isCharacter()) {
                    return (false, "Only character is allowed")
                }
                return (true, "")
                
            case .None:
                return (false, "Something went wrong")
    
            }
        }
    }
}

