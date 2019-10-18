//
//  ViewController.swift
//  Places
//
//  Created by Marc Langsman on 03/10/2019.
//  Copyright © 2019 Marc Langsman. All rights reserved.
//

import UIKit
import MapKit

class PlacesViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var mapView:MKMapView?
    @IBOutlet var tableView:UITableView?
    
    var locationManager:CLLocationManager?
    
    var places = [[String: Any]]()
    var isQueryPending = false
    
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    
        locationManager = CLLocationManager()
        locationManager?.requestWhenInUseAuthorization()
        
        locationManager!.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager!.distanceFilter = 50
        
        locationManager?.delegate = self
        locationManager?.startUpdatingLocation()
        
        mapView?.delegate = self
        
        tableView?.delegate = self
        tableView?.dataSource = self
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        
        guard mapView != nil else {
            return
        }
        
        guard let newLocation = locations.last else {
            return
        }
        
        let region = MKCoordinateRegion(center: newLocation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        let adjustedRegion = mapView!.regionThatFits(region)
        
        mapView!.setRegion(adjustedRegion, animated: true)
        
        //mapView!.setCenter(newLocation.coordinate, animated: true)
        
        queryFourSquare(location: newLocation)
        
    }
    
    func queryFourSquare(location: CLLocation)
    {
        print("Calling Foursquare...")
        // Semaphore
        
        if (self.isQueryPending) {
            return
        }
        
        self.isQueryPending = true
        
        // Set API request params
        
        let clientID        = URLQueryItem(name: "client_id", value: Constants.keys.foursquareClientID)
        let clientSecret    = URLQueryItem(name: "client_secret", value: Constants.keys.foursquareSecret)

        let version         = URLQueryItem(name: "v", value: "20190401")
        let coordinate      = URLQueryItem(name: "ll", value: "\(location.coordinate.latitude),\(location.coordinate.longitude)")
        let intent          = URLQueryItem(name: "intent", value: "browse")
        let radius          = URLQueryItem(name: "radius", value: "250")
        let query           = URLQueryItem(name: "query", value: "coffee")
        
        var urlComponents   = URLComponents(string: "https://api.foursquare.com/v2/venues/search")!
        
        
        // Build query
        
        urlComponents.queryItems = [clientID, clientSecret, version, coordinate, intent, radius, query]
        
        // Run query
        
        let task = URLSession.shared.dataTask(with: urlComponents.url!, completionHandler:
            
            { data, response, error in
                
                if error != nil
                {
                    print("*** Error: \(error?.localizedDescription)")
                    return
                }
                
                if response == nil || data == nil
                {
                    print("Something went wrong")
                    return
                }
                
                // Clear the places array before we start to fill it
                self.places.removeAll()
                
                do
                {
                    // Serialise Json to an object
                    let jsonData = try JSONSerialization.jsonObject(with: data!, options: [])
                    //print(jsonData)
                    
                    // Downcast json components to dictionaries / array of dictionaries so we can manipulate them
                    
                    if  let jsonObject = jsonData as? [String: Any],
                        let response = jsonObject["response"] as? [String: Any],
                        let venues = response["venues"] as? [[String: Any]]
                    {
                        // Add each venue to the places array
                        for venue in venues
                        {
                            if  let name             = venue["name"] as? String,
                                let location         = venue["location"] as? [String: Any],
                                let latitude         = location["lat"] as? Double,
                                let longitude        = location["lng"] as? Double,
                                let formattedAddress = location["formattedAddress"] as? [String]
                            {
                                self.places.append([
                                    "name": name,
                                    "address": formattedAddress.joined(separator: " "),
                                    "latitude": latitude,
                                    "longitude": longitude,
                                ])
                            }
                        }
                    }
                    
                    print("places \(self.places.count): \(self.places)")
                  
                    
                }
                catch
                {
                    print("JSon Error: \(error.localizedDescription)")
                    return
                }
                
                self.isQueryPending = false
                
                DispatchQueue.main.async {
                    self.updatePlaces()
                    self.tableView?.reloadData()
                }
                
            }
                
                
        )
        
        
        task.resume()

        }
     
    
    func updatePlaces()
    {
        
        // Best practice: mapView is an oulet - these can be nil before viewDidLoad is
        // called or if deallocted
        
        print("Updating Places")
        print("places \(self.places.count)")
        
        guard mapView != nil else {
            return
        }
        
        mapView!.removeAnnotations(mapView!.annotations)
        
        for place in places
        {
            if  let name        = place["name"] as? String,
                // let address     = place["address"] as? String,
                let latitude    = place["latitude"] as? CLLocationDegrees,
                let longitude   = place["longitude"] as? CLLocationDegrees
            {
                let annotation = MKPointAnnotation()
                annotation.coordinate =  CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                annotation.title = name
                
                mapView!.addAnnotation(annotation)
            }
            
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation.isKind(of: MKUserLocation.self)
        {
            print("Skipping blip")
            return nil
        }
        
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: "annotationView")
        
        if view == nil
        {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotationView")
            view?.canShowCallout = true
        }
        else
        {
            view!.annotation = annotation
        }
        
        // print ("mapView Returning")
        // print (view!.annotation!.title)
        // print (view!.annotation!.coordinate)
        return view
        
        
    }
    

    // Return the number of rows for the table.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print ("\(#function) --- Places count: \(places.count)")
        //. return places.count
        return places.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    

    // Provide a cell object for each row.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       // Fetch a cell of the appropriate type.
       
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
       
        if cell == nil
        {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        }
        
        // Configure the cell’s contents.
        cell!.textLabel?.text = places[indexPath.row]["name"] as? String
        cell!.detailTextLabel?.text = places[indexPath.row]["address"] as? String
           
        return cell!
    }
    

    
    
}

