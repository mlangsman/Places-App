//
//  FoursquareAPI.swift
//  Places
//
//  Created by Marc Langsman on 29/10/2019.
//  Copyright © 2019 Marc Langsman. All rights reserved.
//

import Foundation
import MapKit

class FoursquareAPI
{
    static let shared = FoursquareAPI()
    
    var isQueryPending  = false
    
    private init() { }
    
    func query(location: CLLocation, completionHandler: @escaping ([[String: Any]]) -> Void)
    {
        print("Calling Foursquare...")
        // Semaphore
               
        if (self.isQueryPending)
        {
            return
        }
        
        self.isQueryPending = true
        var places          = [[String: Any]]()
               
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
                print("*** Error: \(error!.localizedDescription)")
                return
            }
        
            if response == nil || data == nil
            {
                print("Something went wrong")
                return
            }
        
        
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
                            places.append([
                                "name": name,
                                "address": formattedAddress.joined(separator: " "),
                                "latitude": latitude,
                                "longitude": longitude,
                            ])
                        }
                    }
                }
            
                print("places \(places.count): \(places)")
                
                places.sort()
                { item1, item2 in
                    let name1 = item1["name"] as! String
                    let name2 = item2["name"] as! String
                    return name1 < name2
                }
            }
          
            catch
            {
                print("JSon Error: \(error.localizedDescription)")
                return
            }
        
            
            self.isQueryPending = false
        
            DispatchQueue.main.async {
                completionHandler(places)
            }
        
        })
        
               
        task.resume()

    }
            
    
    
}
