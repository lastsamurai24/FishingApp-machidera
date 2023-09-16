//
//  MypageViewController.swift
//  FishingApp
//
//  Created by 待寺翼 on 2023/09/15.
//

import UIKit
import Firebase

class MypageViewController: UIViewController {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let name = nameTextField.text, !name.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let phone = phoneTextField.text, !phone.isEmpty else {
            // 必要な情報が入力されていない場合の処理
            return
        
        }
        
        // ここで情報を保存する処理を行う (例: Firestoreに保存)
        
        let db = Firestore.firestore()
        db.collection("users").addDocument(data: [
            "name": name,
            "email": email,
            "phone": phone
        ]) { error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                print("Document added successfully!")
            }
        }
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
}

