//
//  ViewController.swift
//  Places
//
//  Created by Marc Langsman on 03/10/2019.
//  Copyright © 2019 Marc Langsman. All rights reserved.
//

import UIKit
import MapKit

class PlacesViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet var mapView:MKMapView?
    @IBOutlet var tableView:UITableView?
    
    var locationManager:CLLocationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    
        locationManager = CLLocationManager()
        locationManager?.requestWhenInUseAuthorization()
        
        locationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager?.distanceFilter = 50
        
        locationManager?.delegate = self
        locationManager?.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print ("gay")
        
        /*
        if let newLocation = locations.last
        {
            print(newLocation)
            mapView?.setCenter(newLocation.coordinate, animated: true)
        }
        */
        
        guard mapView != nil else {
            return
        }
        
        guard let newLocation = locations.last else {
            return
        }
        
        let region = MKCoordinateRegion(center: newLocation.coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
        
        let adjustedRegion = mapView!.regionThatFits(region)
        
        mapView!.setRegion(adjustedRegion, animated: true)
        
        //mapView?.setCenter(newLocation.coordinate, animated: true)
        
        
        
        
    }


}

