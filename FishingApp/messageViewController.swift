//
//  messageViewController.swift
//  FishingApp
//
//  Created by 待寺翼 on 2023/09/17.

import UIKit
import Firebase
import CoreLocation

class messageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var posts: [CustomPin] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        loadPostsFromFirebase()
    }
    
    func loadPostsFromFirebase() {
        let timeLineDB = Database.database().reference().child("timeLine")
        
        timeLineDB.observe(.value) { (snapshot) in
            self.posts = []
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let pinData = childSnapshot.value as? [String: Any] {
                    
                    let latitude = pinData["latitude"] as? Double ?? 0.0
                    let longitude = pinData["longitude"] as? Double ?? 0.0
                    let title = pinData["title"] as? String ?? ""
                    let address = pinData["address"] as? String ?? ""
                    let fishType = pinData["fishType"] as? String ?? ""
                    let tackle = pinData["tackle"] as? String ?? ""
                    let memo = pinData["memo"] as? String ?? ""
                    let imageUrlString = pinData["imageUrl"] as? String ?? ""

                    let pin = CustomPin(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), title: title, address: address, fishType: fishType, tackle: tackle, image: nil, memo: memo)
                    pin.imageUrl = imageUrlString
                    self.posts.append(pin)
                }
            }
            
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)
        
        let post = posts[indexPath.row]
        cell.textLabel?.text = post.title
        if let date = post.date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let dateString = dateFormatter.string(from: date)
            cell.detailTextLabel?.text = dateString
        }
        
        return cell
    }

}

    // MARK: - Navigation
/*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


