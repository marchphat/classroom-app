//
//  addCourseVC.swift
//  final_project
//
//  Created by Nantanat Thongthep on 5/12/2564 BE.
//

import UIKit
import GRDB

class addCourseVC: UIViewController {
    
    //ui
    @IBOutlet weak var coursename: UITextField!
    @IBOutlet weak var lecturer: UITextField!
    @IBOutlet weak var classType: UITextField!
    @IBOutlet weak var classLocation: UITextField!
    @IBOutlet weak var studyDay: UITextField!
    @IBOutlet weak var studyStartTime: UITextField!
    @IBOutlet weak var studyEndTime: UITextField!
    @IBOutlet weak var courseColor: UITextField!
    
    @IBOutlet weak var courseDescLabel: UILabel!
    @IBOutlet weak var lectDescLabel: UILabel!
    @IBOutlet weak var stuDayDescLabel: UILabel!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    let timePicker = UIDatePicker()
    
    //init data
    var days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    var colors = ["Orange", "Blue", "Brown", "Green", "Purple", "Red", "Pink", "Yellow"]
    var course_id = "1"
    
    //from CoursesVC
    var actionFromCourseVC = " "
    var courseDetails = [String]()
    
    //session
    var userData = [String]()
    var defaults = UserDefaults.standard
    
    //database
    var dbPath : String = " "
    var dbResourcePath : String = " "
    var config = Configuration()
    let fileManager = FileManager.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setInterface()
        useSession()
        connect2DB()
        selectQuery()
    }
    
    // MARK: - Interface
    
    func setInterface() {
        courseDescLabel.text = " "
        lectDescLabel.text = " "
        stuDayDescLabel.text = " "
        
        if actionFromCourseVC == "didSelectRow" {
            deleteButton.isHidden = false
            coursename.text = courseDetails[1]
            lecturer.text = courseDetails[2]
            studyDay.text = courseDetails[3]
            studyStartTime.text = courseDetails[4]
            studyEndTime.text = courseDetails[5]
            classType.text = courseDetails[6]
            classLocation.text = courseDetails[7]
            courseColor.text = courseDetails[8]
        }
    }
    
    func useSession() {
        self.userData = defaults.object(forKey: "savedUser") as! [String]
    }
    
    // MARK: - Action
    
    @IBAction func textFieldTouchDown(_ textField: UITextField) {
        sendToErrorHandler(textField)
        sendToSetPicker(textField)
    }
    
    @IBAction func textFieldDidTextChange(_ textField: UITextField) {
        sendToErrorHandler(textField)
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        changeView()
    }
    
    @IBAction func doneButton(_ sender: Any) {
        guard deleteButton.isHidden else {
            updateQuery()
            changeView()
            return
        }
        
        if textFieldisEmpty() {
            validateHandler(isEmpty: true, coursename, courseDescLabel)
            validateHandler(isEmpty: true, lecturer, lectDescLabel)
            validateHandler(isEmpty: true, studyDay, stuDayDescLabel)
        } else {
            insertQuery()
            changeView()
        }
    }
    
    @IBAction func deleteButton(_ sender: Any) {
        deleteQuery()
        changeView()
    }
    
    // MARK: - Picker
    
    func setPicker(_ textField: UITextField, tag: Int) {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        textField.inputView = picker
        picker.tag = tag
    }
    
    func setBarButton(_ textField: UITextField) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneDay))
        toolbar.setItems([doneButton], animated: true)
        toolbar.isUserInteractionEnabled = true
        textField.inputAccessoryView = toolbar
    }
    
    @objc func doneDay() {
        self.view.endEditing(true)
    }
    
    // Time Picker
    
    func setTimePicker(_ timeTextField: UITextField, _ doneButton: UIBarButtonItem) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [doneButton]
        timeTextField.inputAccessoryView = toolbar
    
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels
        timeTextField.inputView = timePicker
    }
    
    @objc func doneStartTime() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        studyStartTime.text = formatter.string(from: timePicker.date)
        self.view.endEditing(true)
    }
    
    @objc func doneEndTime() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        studyEndTime.text = formatter.string(from: timePicker.date)
        self.view.endEditing(true)
    }
    
    // MARK: - Picker Handler
    
    func sendToSetPicker(_ textField: UITextField) {
        let tag = textField.tag
        
        switch tag {
        case 2:
            setPicker(studyDay, tag: 2)
            setBarButton(studyDay)
        case 3:
            let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneStartTime))
            setTimePicker(textField, button)
        case 4:
            let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneEndTime))
            setTimePicker(textField, button)
        case 7:
            setPicker(courseColor, tag: 7)
            setBarButton(courseColor)
        default:
            break
        }
    }
    
    // MARK: - Validator
    
    func textFieldisEmpty() -> Bool {
        if coursename.text!.isEmpty { return true }
        if lecturer.text!.isEmpty { return true }
        if studyDay.text!.isEmpty { return true }
        if courseColor.text!.isEmpty { courseColor.text = "Orange" }
        
        return false
    }
    
    func sendToErrorHandler(_ textField: UITextField) {
        let tag = textField.tag

        switch tag {
        case 0:
            validateHandler(isEmpty: false, textField, courseDescLabel)
        case 1:
            validateHandler(isEmpty: false, textField, lectDescLabel)
        case 2:
            validateHandler(isEmpty: false, textField, stuDayDescLabel)
        default:
            break
        }
    }
    
    // MARK: - Error Handler
    
    func validateHandler(isEmpty: Bool, _ textField: UITextField, _ descLabel: UILabel) {
        if isEmpty {
            textField.layer.borderColor = UIColor.red.cgColor
            descLabel.text = "Please fill in the form"
        } else {
            textField.layer.borderColor = #colorLiteral(red: 0.8775331378, green: 0.8775331378, blue: 0.8775331378, alpha: 1)
            descLabel.text = " "
        }
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 5
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
    
    func selectQuery() {
        do {
            let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)
            try dbQueue.inDatabase { db in

                let rows = try Row.fetchCursor(db, sql: "SELECT course_id FROM course")

                while let row = try rows.next() {
                    if course_id == row["course_id"] {
                        course_id = String(Int(course_id)! + 1)
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    func insertQuery() {
        do {
            config.readonly = false
            let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)

            try dbQueue.write {
                db in
                try db.execute(sql: "INSERT INTO course (course_id, user_email, course_name, course_lecturer, course_day, course_startTime, course_endTime, course_type, course_location, course_color) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", arguments: [course_id, userData[2], coursename.text!, lecturer.text!, studyDay.text!, studyStartTime.text!, studyEndTime.text!, classType.text!, classLocation.text!, courseColor.text!])
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func deleteQuery() {
        do {
            config.readonly = false
            let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)

            try dbQueue.write {
                db in
                try db.execute(sql: "DELETE FROM course WHERE course_id = (?)", arguments: [courseDetails[0]])
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updateQuery() {
        do {
            config.readonly = false
            let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)

            try dbQueue.write {
                db in
                try db.execute(sql: "UPDATE course SET course_name = (?), course_lecturer = (?), course_day = (?), course_startTime = (?), course_endTime = (?), course_type = (?), course_location = (?), course_color = (?) WHERE course_id = (?)", arguments: [coursename.text!, lecturer.text!, studyDay.text!, studyStartTime.text!, studyEndTime.text!, classType.text!, classLocation.text!, courseColor.text!, courseDetails[0]])
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Change View
    
    func changeView() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension addCourseVC: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 2:
            return days.count
        case 7:
            return colors.count
        default:
            return 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 2:
            return days[row]
        case 7:
            return colors[row]
        default:
            return "Data not found"
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 2:
            studyDay.text = days[row]
        case 7:
            courseColor.text = colors[row]
        default:
            return
        }
    }
    
}
