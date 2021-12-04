//
//  DetailViewController.swift
//  azs0243_finalproject_fall21
//
//  Created by Ashlie Scharmann on 11/25/21.
//

import UIKit
import MobileCoreServices

class DetailViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var masterViewController: ViewController!
    var itemIndex = 0
    
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var authorField: UITextField!
    @IBOutlet weak var genreField: UITextField!
    @IBOutlet weak var publishField: UITextField!
    @IBOutlet weak var coverPicker: UIPickerView!
    @IBOutlet weak var notesField: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(getDocumentsDirectory())

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.notesField.layer.borderColor = UIColor.lightGray.cgColor
        self.notesField.layer.borderWidth = 1
        
        titleField.text = masterViewController.objects[itemIndex].title
        authorField.text = masterViewController.objects[itemIndex].author
        genreField.text = masterViewController.objects[itemIndex].genre
        publishField.text = masterViewController.objects[itemIndex].published
        notesField.text = masterViewController.objects[itemIndex].notes
        coverChoice[coverPicker.selectedRow(inComponent: 0)] = masterViewController.objects[itemIndex].cover
        imageURLString = masterViewController.objects[itemIndex].coverArt
    }
    
    
    @IBAction func cancelPressed(_ sender: UIButton) {
        if masterViewController.newFlag {
        masterViewController.objects.remove(at: itemIndex)
        masterViewController.tableView.reloadData()
            masterViewController.newFlag = false
        }
    }
    
    
    @IBAction func savePressed(_ sender: UIButton) {
        masterViewController.objects[itemIndex].title = titleField.text!
        masterViewController.objects[itemIndex].author = authorField.text!
        masterViewController.objects[itemIndex].genre = genreField.text!
        masterViewController.objects[itemIndex].published = publishField.text!
        masterViewController.objects[itemIndex].notes = notesField.text!
        masterViewController.objects[itemIndex].cover = coverChoice[coverPicker.selectedRow(inComponent: 0)]
        masterViewController.objects[itemIndex].coverArt = imageURLString
        masterViewController.tableView.reloadData()
    }
    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    
    //picker for cover choice of paperback or hardcover
    var coverChoice = ["", "Paperback", "Hardcover", "eBook"]
    
    //picker data source
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return coverChoice.count
    }
    
    
    //picker delegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return coverChoice[row]
        
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        coverPicker.reloadComponent(0)
    }
    
    
    @IBOutlet weak var coverArt: UIImageView!
    @IBOutlet weak var pickButton: UIButton!
    
    var image: UIImage?
    var thumbnail: UIImage?
    var imageURLString = ""
    

    //image methods
    func showCameraUserInterface() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        #if targetEnvironment(simulator)
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        #else
        imagePicker.sourceType = UIImagePickerController.SourceType.camera
        imagePicker.showsCameraControls = true
        #endif
        imagePicker.mediaTypes = [kUTTypeImage as String]
        imagePicker.allowsEditing = true
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated:true, completion:nil)
    }
                                        
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info : [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        if let img = image {
            self.thumbnail = generate(image: img, ratio: CGFloat(102))
            self.image = generate(image: img, ratio: CGFloat(752))
        }
       
        //write the picked image to a file in the documents directory
        
        let imageName = UUID().uuidString
        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        if let jpegData = image?.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: imagePath)
        }
        print("wrote image")
        print(imagePath.path)
        
        //write the name (generated with uuid) to the plist so you can get it later
        
        let filenameURL = getDocumentsDirectory().appendingPathComponent("data.plist")
        var info = NSDictionary(contentsOfFile: filenameURL.path) as? [String:String]
        if(info != nil) {
            if info!.keys.contains("image") {
            info!["image"] = imageName
            }
        }
        else {
            info = [:]
            info!["image"] = imageName
        }
        let nsinfo = info! as NSDictionary
        print(nsinfo)
        nsinfo.write(to: filenameURL, atomically: true)
        
        imageURLString = imageName
        masterViewController.objects[itemIndex].coverArt = imageURLString
        
        dismiss(animated:true)
        picker.dismiss(animated: true)
        self.coverArt.image = self.image!
    }
    
    func generate(image: UIImage, ratio: CGFloat) -> UIImage {
        let size = image.size
        var croppedSize: CGSize?
        var offsetX: CGFloat = 0.0
        var offsetY: CGFloat = 0.0
        if size.width > size.height {
            offsetX = (size.height - size.width) / 2
            croppedSize = CGSize(width: size.height, height: size.height)
        }
        else {
            offsetY = (size.width - size.height) / 2
            croppedSize = CGSize(width: size.width, height: size.width)
        }
        guard let cropped = croppedSize, let cgImage = image.cgImage
        else {
            return UIImage()
        }
        let clippedRect = CGRect(x: offsetX * -1, y: offsetY * -1, width: cropped.width, height: cropped.height)
        let imgRef = cgImage.cropping(to: clippedRect)
        let rect = CGRect(x: 0.0, y: 0.0, width: ratio, height: ratio)
        UIGraphicsBeginImageContext(rect.size)
        if let ref = imgRef {
            UIImage(cgImage: ref).draw(in: rect)
        }
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let thumb = thumbnail else {
            return UIImage()
        }
        return thumb
    }
    
    
    @IBAction func loadPressed(_ sender: UIButton) {
        if (imageURLString != "") {
            coverArt.image = UIImage(contentsOfFile : imageURLString)
            coverArt.image = UIImage(contentsOfFile: getDocumentsDirectory().appendingPathComponent(imageURLString).path)
        }
    }
    
    
    @IBAction func chooseImagePressed(_ sender: UIButton) {
        showCameraUserInterface()
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
