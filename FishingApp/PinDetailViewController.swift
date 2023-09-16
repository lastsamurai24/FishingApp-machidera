//
//  PinDetailViewController.swift
//  FishingApp
//
//  Created by 待寺翼 on 2023/09/16.
//

import UIKit

class PinDetailViewController: UIViewController {
    var customPin: CustomPin?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var fishTypeLabel: UILabel!
    @IBOutlet weak var tackleLabel: UILabel!
    @IBOutlet weak var memoLabel: UILabel!
    @IBOutlet weak var pinImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let pin = customPin {
            titleLabel.text = pin.title
            addressLabel.text = pin.address
            fishTypeLabel.text = pin.fishType
            tackleLabel.text = pin.tackle
            memoLabel.text = pin.memo
            
            // 画像のダウンロードと表示
            if let imageUrl = pin.imageUrl, let url = URL(string: imageUrl) {
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.pinImageView.image = image
                        }
                    }
                }.resume()
            }
        }
    }
    
}
