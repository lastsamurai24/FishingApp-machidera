

import UIKit
import Firebase

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func loginAction(_ sender: Any){
        
        
        
        Auth.auth().signInAnonymously{(authResult,error) in
            let user = authResult?.user
            print(user)
            
            /* 2行追加、画面遷移 */
            let mapVC = self.storyboard?.instantiateViewController(identifier: "MapViewController") as! MapViewController
            self.navigationController?.pushViewController(mapVC, animated: true)
        }
    }
    
}


