//
//  ViewController.swift
//  FishingApp
//
//  Created by 待寺翼 on 2023/09/14.
//

import UIKit
import MapKit
import CoreLocation
import Photos
import Firebase
import FirebaseStorage
import FirebaseDatabase
import FirebaseFirestore
import Kingfisher
import ProgressHUD


class CustomPin: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var address: String?
    var fishType: String?
    var tackle: String?
    var image: UIImage?
    var memo: String?
    var imageUrl: String?
    
    
    init(coordinate: CLLocationCoordinate2D, title: String, address: String, fishType: String, tackle: String, image: UIImage?, memo: String) {
        self.coordinate = coordinate
        self.title = title
        self.address = address
        self.fishType = fishType
        self.tackle = tackle
        self.image = image
        self.memo = memo
    }
}

extension MapViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            self.selectedImage = image
        }
        dismiss(animated: true) {
            // 写真選択後に再度UIAlertControllerを表示
            self.showPinInfoAlert(coordinate: self.selectedCoordinate!)
        }
        
    }
}
class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var seachBar: UISearchBar!
    var overlayView: UIView!
    var titleLabel: UILabel!
    var addressLabel: UILabel!
    var fishTypeLabel: UILabel!
    var tackleLabel: UILabel!
    var memoLabel: UILabel!
    var pinImageView: UIImageView!
    
    private var locationManager: CLLocationManager!
    var selectedImage: UIImage?
    var selectedCoordinate: CLLocationCoordinate2D?
    var isTapGestureEnabled = false
    var imageUrl: String?
    @IBOutlet weak var weatherTextView: UITextView!
    
        let apiKey = "5d3ae33b20fa31c74bf3ed56490e389b"
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        // 位置情報の設定
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() // 位置情報の利用許可をリクエスト
        
        // タップジェスチャーの追加
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        loadPinsFromFirebaseDatabase { (pins) in
            self.mapView.addAnnotations(pins)
            
        }
        setupWeatherTextView()
    }
    func setupOverlayView() {
        overlayView = UIView(frame: CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: 300))
        overlayView.backgroundColor = .white
        overlayView.alpha = 0.9
        
        titleLabel = UILabel(frame: CGRect(x: 10, y: 10, width: overlayView.frame.width - 20, height: 30))
        addressLabel = UILabel(frame: CGRect(x: 10, y: 50, width: overlayView.frame.width - 20, height: 30))
        fishTypeLabel = UILabel(frame: CGRect(x: 10, y: 90, width: overlayView.frame.width - 20, height: 30))
        tackleLabel = UILabel(frame: CGRect(x: 10, y: 130, width: overlayView.frame.width - 20, height: 30))
        memoLabel = UILabel(frame: CGRect(x: 10, y: 170, width: overlayView.frame.width - 20, height: 30))
        pinImageView = UIImageView(frame: CGRect(x: 10, y: 210, width: 60, height: 60))
        
        overlayView.addSubview(titleLabel)
        overlayView.addSubview(addressLabel)
        overlayView.addSubview(fishTypeLabel)
        overlayView.addSubview(tackleLabel)
        overlayView.addSubview(memoLabel)
        overlayView.addSubview(pinImageView)
        
        self.view.addSubview(overlayView)
    }
    func setupWeatherTextView() {
           view.addSubview(weatherTextView)
           
           NSLayoutConstraint.activate([
               weatherTextView.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 8),
               weatherTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
               weatherTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
               weatherTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
           ])
       }
    
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            if !isTapGestureEnabled {
                return
            }
            let location = gesture.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            self.selectedCoordinate = coordinate // 座標を一時的に保存
            
            // 天気情報を取得
            fetchWeatherData(for: coordinate)
            
            showPinInfoAlert(coordinate: coordinate)
        }
    func showPinInfoAlert(coordinate: CLLocationCoordinate2D) {
        let alertController = UIAlertController(title: "ピンの情報を入力", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { (textField) in textField.placeholder = "タイトル" }
        alertController.addTextField { (textField) in textField.placeholder = "住所" }
        alertController.addTextField { (textField) in textField.placeholder = "魚種" }
        alertController.addTextField { (textField) in textField.placeholder = "タックル" }
        alertController.addTextField { (textField) in textField.placeholder = "メモ" }
        alertController.addTextField { (textField) in
            textField.placeholder = "画像を選択"
            textField.isUserInteractionEnabled = false
        }
        
        let imagePickerAction = UIAlertAction(title: "画像を選択", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }
        alertController.addAction(imagePickerAction)
        let addAction = UIAlertAction(title: "追加", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let title = alertController.textFields?[0].text ?? ""
            let address = alertController.textFields?[1].text ?? ""
            let fishType = alertController.textFields?[2].text ?? ""
            let tackle = alertController.textFields?[3].text ?? ""
            let memo = alertController.textFields?[4].text ?? ""
            let customPin = CustomPin(coordinate: coordinate, title: title, address: address, fishType: fishType, tackle: tackle, image: self.selectedImage, memo: memo)
            
            self.mapView.addAnnotation(customPin)
            
            self.savePinToFirebaseDatabase(customPin: customPin)
        }
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func toggleTapGesture(_ sender: UIButton) {
        isTapGestureEnabled.toggle()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 現在地のアノテーションはカスタマイズしない
        
        
        
        if annotation is MKUserLocation {
                   return nil
               }

               guard let customPin = annotation as? CustomPin else { return nil }

               let identifier = "customPin"
               var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

               if annotationView == nil {
                   annotationView = MKMarkerAnnotationView(annotation: customPin, reuseIdentifier: identifier)
                   annotationView?.canShowCallout = true
               } else {
                   annotationView?.annotation = annotation
               }
        
        // 画像をアノテーションビューに追加
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
             if let imageUrl = customPin.imageUrl {
                 imageView.kf.setImage(with: URL(string: imageUrl)) // Kingfisherを使用して画像をダウンロード
             }
             annotationView?.leftCalloutAccessoryView = imageView

             return annotationView
    }
 func savePinToFirebaseDatabase(customPin: CustomPin) {
     let timeLineDB = Database.database().reference().child("timeLine").childByAutoId()
     
     if let imageData = customPin.image?.jpegData(compressionQuality: 0.8) {
         let storageRef = Storage.storage().reference().child("pin_images/\(UUID().uuidString).jpg")
         storageRef.putData(imageData, metadata: nil) { (metadata, error) in
             guard metadata != nil else {
                 print("Error uploading image: \(error!)")
                 return
             }
             
             storageRef.downloadURL { (url, error) in
                 guard let downloadURL = url else {
                     print("Error getting download URL: \(error!)")
                     return
                 }
                 
                 let pinInfo = [
                     "latitude": customPin.coordinate.latitude,
                     "longitude": customPin.coordinate.longitude,
                     "title": customPin.title ?? "",
                     "address": customPin.address ?? "",
                     "fishType": customPin.fishType ?? "",
                     "tackle": customPin.tackle ?? "",
                     "memo": customPin.memo ?? "",
                     "imageUrl": downloadURL.absoluteString
                 ] as [String : Any]
                 
                 timeLineDB.setValue(pinInfo)
             }
         }
     }
 }


    func loadPinsFromFirebaseDatabase(completion: @escaping ([CustomPin]) -> Void) {
        let timeLineDB = Database.database().reference().child("timeLine")
        
        timeLineDB.observe(.value) { (snapshot) in
            var pins: [CustomPin] = []
            
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
                    pins.append(pin)
                }
            }
            
            completion(pins)
        }
    }

    func fetchWeatherData(for coordinate: CLLocationCoordinate2D) {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appid=\(apiKey)&units=metric"
        
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error:", error.localizedDescription)
                    return
                }
                
                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let main = json["main"] as? [String: Any],
                           let weatherArray = json["weather"] as? [[String: Any]],
                           let weather = weatherArray.first,
                           let wind = json["wind"] as? [String: Any],
                           let sys = json["sys"] as? [String: Any] {
                            
                            let description = weather["description"] as? String ?? ""
                            let mainWeather = weather["main"] as? String ?? ""
                            let temp = main["temp"] as? Double ?? 0.0
                            let tempMin = main["temp_min"] as? Double ?? 0.0
                            let tempMax = main["temp_max"] as? Double ?? 0.0
                            let windSpeed = wind["speed"] as? Double ?? 0.0
                            let windDeg = wind["deg"] as? Int ?? 0
                            
                            // ここを修正
                            let rainData = json["rain"] as? [String: Any]
                            let rain = rainData?["1h"] as? Double ?? 0.0
                            
                            let sunrise = sys["sunrise"] as? Int ?? 0
                            let sunset = sys["sunset"] as? Int ?? 0
                            
                            let weatherText = """
                            天気概要: \(mainWeather) (\(description))
                            気温: \(temp)°C
                            最低気温: \(tempMin)°C
                            最高気温: \(tempMax)°C
                            風速: \(windSpeed) m/s
                            風向: \(windDeg)°
                            降水量: \(rain) mm
                            日の出: \(Date(timeIntervalSince1970: TimeInterval(sunrise)))
                            日の入り: \(Date(timeIntervalSince1970: TimeInterval(sunset)))
                            """
                            
                            DispatchQueue.main.async {
                                self.weatherTextView.text = weatherText
                            }
                        }
                    } catch {
                        print("JSON解析エラー:", error.localizedDescription)
                    }
                }
            }
            task.resume()
        }
    }

}



