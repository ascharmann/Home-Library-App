//
//  ViewController.swift
//  azs0243_finalproject_fall21
//
//  Created by Ashlie Scharmann on 11/25/21.
//

/*
 
// This is a Home Library app that keeps information about the books in your home library -
   Title, Author, Genre, Year Published, Cover (Hardcover/Paperback//eBook), Notes, and a Cover image.
 
 //TableView can be sorted by Genre, Author, or Title
 
 //I have added a JSON file that includes examples to begin - file includes
   all details for each book except image. User can add an image to the book's details from the phone's camera roll.
 
 //Persistent storage is used - object array is stored in a JSON file.
 
*/


import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!

    var objects:[DetailObject] = []
    
    var newFlag = false
    
    @IBOutlet weak var totalBooksLabel: UILabel!
    
    //table view methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let object = objects[indexPath.row]
        cell.textLabel!.text = object.title
        cell.detailTextLabel!.text = object.author
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //look for json file - if found, load data from file.
        
        let fileURL = dataFileURL()
        print(fileURL)
        
        if(FileManager.default.fileExists(atPath: fileURL.path)) {
            
            print("found file")
                //initialize from the data file in the directory if there is one
                do {
                    let data = try Data(contentsOf: fileURL)
                    let decoder = JSONDecoder()
                    objects = try decoder.decode(Array<DetailObject>.self, from: data)
                }
                catch {
                    print("error finding file")
                }
            }
         
        else {
            
            //if json file is not found, it means that this is the first time we have opened the app - so it will load 5 preloaded albums from local json file
            //these will get saved to the new json file in the directory when the app is closed so that when the app is opened again,
            //the json file is found and these are included.
            
            if let fileLocation = Bundle.main.url(forResource: "data", withExtension: "json") {
                do {
                    let data = try Data(contentsOf: fileLocation)
                    let jsonDecoder = JSONDecoder()
                    let dataFromJson = try jsonDecoder.decode([DetailObject].self, from: data)
                    self.objects = dataFromJson
                }
                catch {
                    print(error)
                }
            }
            
            //else no initialization
            print("file not found")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillResignActive(notification:)), name: UIApplication.willResignActiveNotification, object: nil)
        
        totalBooksLabel.text = "Total Books: " + (String(objects.count))
        
    }
    
    //new button - uses segue
    @IBAction func newPressed(_ sender: UIButton) {
    }
    
    
    //edit button
    @IBAction func editPressed(_ sender: UIButton) {
        tableView.isEditing = !tableView.isEditing
        if sender.currentTitle == "Edit" || sender.currentTitle == nil {
            sender.setTitle("Done", for: .normal)
        }
        else {
            sender.setTitle("Edit", for: .normal)
        }
        
    }
    
    //alphabetize table view by title
    @IBAction func alphaPressed(_ sender: UIButton) {
        
        objects.sort {
            $0.title < $1.title
        }
        
        tableView.reloadData()
    }
    
    //alphabetize table view by author
    @IBAction func alphaAuthorPressed(_ sender: UIButton) {
        objects.sort {
            $0.author < $1.author
        }
        
        tableView.reloadData()
    }
    
    //sort table view by genre
    @IBAction func genreSortPressed(_ sender: UIButton) {
        objects.sort {
            ($0.genre, $0.title) < ($1.genre, $1.title)
        }
        
        tableView.reloadData()
    }
    
    
    //segue - when edit is pressed segue using showDetail identifier,
    //when new is pressed, segue using new identifier
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = (segue.destination as! DetailViewController)
        controller.masterViewController = self
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                controller.itemIndex = indexPath.row
            }
        }
        else { //identifier is New
            controller.itemIndex = 0
            let newObject = DetailObject()
            newObject.title = ""
            newObject.author = ""
            newObject.cover = ""
            newObject.genre = ""
            newObject.published = ""
            newObject.notes = ""
            newObject.coverArt = ""
            objects.insert(newObject, at:0)
            newFlag = true
        }
    }
    
    //save and cancel unwind to main view controller
    @IBAction func unwindToThisViewController(segue: UIStoryboardSegue) {
        // because viewWillAppear does not run when unwinding a modal segue
        tableView.reloadData()
        totalBooksLabel.text = "Total Books: " + (String(objects.count))
    }
    
    //ability to edit and move rows
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //reorder rows
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let objectToBeMoved = objects[sourceIndexPath.row]
        objects.remove(at: sourceIndexPath.row)
        objects.insert(objectToBeMoved, at: destinationIndexPath.row)
    }
    
    //delete rows
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            objects.remove(at: indexPath.row)
            tableView.reloadData()
            totalBooksLabel.text = "Total Books: " + (String(objects.count))
        }
    }
    
    //function to get json file
    func dataFileURL() -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        var url:URL?
        url = URL(fileURLWithPath: "")
        url = urls.first!.appendingPathComponent("data.json")
        return url!
    }
    
    //data is saved to json file when app is terminated
    @objc func applicationWillResignActive(notification: NSNotification) {
        let fileURL = self.dataFileURL()
        
        //this prints the path of the json file where the data is stored in persistent storage:
        print(fileURL)
        
        print("data saved")
        
        //write data to json file
        
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(self.objects) {
            do {
                try data.write(to: fileURL)
                print("wrote data using coding")
            }
            catch {
                print("error writing to data file")
            }
        }
    }

    


}

