//
//  ViewController.swift
//  Calcupad
//
//  Created by Will Kwon on 7/30/16.
//  Copyright © 2016 Will Kwon. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    @IBOutlet weak var divideButton: CalculatorButton!
    @IBOutlet weak var multiplyButton: CalculatorButton!
    @IBOutlet weak var minusButton: CalculatorButton!
    @IBOutlet weak var plusButton: CalculatorButton!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    let calculator: Calculator
    let calculationEntityName = "Calculation"
    let equationAttributeName = "equation"
    let cellIdentifier = "Cell"
    var results = [NSManagedObject]()
    var operationButtons: [CalculatorButton]?
    
    required init?(coder aDecoder: NSCoder) {
        calculator = Calculator()
        super.init(coder: aDecoder)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: calculationEntityName)

        do {
            let resultsRequest = try managedContext.fetch(fetchRequest)
            results = resultsRequest
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        operationButtons = [divideButton, multiplyButton, minusButton, plusButton];
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.reloadData()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        
        let result = results[results.count - 1 - (indexPath as NSIndexPath).row]
        
        cell!.backgroundColor = UIColor.darkText
        cell!.textLabel!.textColor = UIColor.white
        cell!.textLabel!.text = result.value(forKey: equationAttributeName) as? String
        
        return cell!
    }
    
    @IBAction func onNumberTapped(_ sender: CalculatorButton) {
        let inputNumber = Int(sender.titleLabel!.text!)
        calculator.inputNumber(number: inputNumber!)
        
        resultLabel.text = calculator.printableValue()
    }
    
    @IBAction func onPeriodTapped() {
        if !calculator.isDecimalInput {
            calculator.isDecimalInput = true
            resultLabel.text = calculator.printableValue()
        }
    }
    
    @IBAction func onBackspaceTapped() {
        calculator.delete()
        
        resultLabel.text = calculator.printableValue()
    }
    
    @IBAction func onNegativeTapped() {
        if calculator.currentValue != 0 {
            calculator.currentValue = calculator.currentValue! * -1.0
        }
        
        resultLabel.text = calculator.printableValue()
    }
    
    @IBAction func onOperationTapped(_ sender: CalculatorButton) {
        if calculator.previousValue != nil {
            calculator.previousValue = calculator.currentValue!
            onEqualsTapped()
        }
        calculator.currentOperator = sender.titleLabel!.text!
        highlightOperationButton()
        calculator.previousValue = calculator.currentValue!
        calculator.currentValue = nil
    }
    
    @IBAction func onClearTapped() {
        calculator.clear()
        resultLabel.text = calculator.printableValue()
    }
    
    @IBAction func onAllClearTapped() {
        calculator.clearAll()
        highlightOperationButton()
        resultLabel.text = calculator.printableValue()
    }
    
    @IBAction func onEqualsTapped() {
        guard let solution = calculator.solveEquation(calculator.previousValue, secondValue: calculator.currentValue, currentOperator: calculator.currentOperator) else {
            return
        }
        
        saveToCoreData()
        calculator.previousValue = solution
        calculator.currentValue = nil
        calculator.currentOperator = nil
        highlightOperationButton()
    }
    
    @IBAction func onClearButtonTapped(_ sender: UIBarButtonItem) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: calculationEntityName)
        let fetchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            try appDelegate.managedObjectContext.execute(fetchDeleteRequest)
            results.removeAll()
        } catch let error as NSError {
            print("Couldn't save object because of error: \(error)")
        }
        
        tableView.reloadData()
    }
    
    func saveToCoreData() {
        let equation = "\(calculator.print(value: calculator.previousValue!)) \(calculator.currentOperator!) \(calculator.print(value: calculator.currentValue!)) = \(resultLabel.text!)"
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let entity = NSEntityDescription.entity(forEntityName: calculationEntityName, in: managedContext)
        
        let result = NSManagedObject(entity: entity!, insertInto: managedContext)
        
        result.setValue(equation, forKey: equationAttributeName)
        
        do {
            try managedContext.save()
            results.append(result)
        } catch let error as NSError {
            print("Couldn't save object because of error: \(error)")
        }
        
        tableView.reloadData()
    }
    
    func highlightOperationButton() {
        for button in operationButtons! {
            button.toggleHighlighted(button.titleLabel!.text == calculator.currentOperator)
        }
    }
    
    func readableString(_ value: Double?) -> String {
        guard let currentValue = value else {
            return NSLocalizedString("Ran into an error", comment: "Ran into an error")
        }
        if currentValue > Double(Int.max) {
            return NSLocalizedString("Number too large", comment: "Number being too large")
        }
        
        if value!.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(currentValue))
        } else {
            return String(currentValue)
        }
    }
}

