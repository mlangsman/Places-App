//
//  ViewController.swift
//  Places
//
//  Created by Marc Langsman on 03/10/2019.
//  Copyright © 2019 Marc Langsman. All rights reserved.
//

import UIKit
import MapKit

class PlacesViewController: UIViewController, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var mapView:MKMapView?
    @IBOutlet var tableView:UITableView?
    
    // var locationManager:CLLocationManager?
    
    let locationManager = LocationManager()
    
    var places = [[String: Any]]()
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    
        locationManager.start { location in
            self.centerMapView(on: location)
            self.queryFourSquare(with: location)
            
        }
 
        mapView?.delegate = self
        
        tableView?.delegate = self
        tableView?.dataSource = self
        
    }
    
    func centerMapView(on location: CLLocation)
    {
        guard mapView != nil else {
                   return
               }
        
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        let adjustedRegion = mapView!.regionThatFits(region)
        
        mapView!.setRegion(adjustedRegion, animated: true)
        
    }
    
    func queryFourSquare(with location: CLLocation)
    {
        FoursquareAPI.shared.query(location: location, completionHandler: { places in
            self.places = places
            self.updatePlaces()
            self.tableView?.reloadData()
            
        })
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

