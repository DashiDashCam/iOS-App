//
//  DashiAPI.swift
//  Dashi
//
//  Created by Chris Henk on 11/20/17.
//  Copyright © 2017 Senior Design. All rights reserved.
//

import Foundation
import PromiseKit
import Alamofire
import SwiftyJSON
import CoreData

// This class is a set of wrapper functions for easy use of the Dashi API

class DashiAPI {
    /** Base URL to be prepended to all routes */
    private static let API_ROOT: String = {
        if TARGET_OS_SIMULATOR != 0 {
            return "http://192.168.33.105"
        } else {
            return "http://45.33.31.110"
        }
    }()

    // TODO: Documentation implies NFC is now accesible on iOS, confirm if this is the case.
    // TODO: Determine if read/write refreshToken to disk is best handled here or externally
    /** The refresh token used to request new access tokens */
    private static var refreshToken: String?

    /** The access token that is supplied in the Authorization header of all authenticated API calls */
    private static var accessToken: String?

    /** The timestamp that the current access token expires at */
    private static var accessTokenExpires: Date?

    /** Custom session manager manually adds host header to all requests, which allows us to use IPs */
    private static var sessionManager: SessionManager = {
        var defaultHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        defaultHeaders["Host"] = "api.dashidashcam.com"

        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = defaultHeaders

        return Alamofire.SessionManager(configuration: configuration)
    }()

    /**
     *  Convenience function that adds the Authroization header to the given request.
     *  Intended to be used in all functions that make use of authenticated API calls.
     *  This function tests the access token's validity before adding to the request.
     *  If the token is invalid it will automatically initiate the necessary API calls
     *  to replace it with a valid one.
     *  @param headers (optional) The request headers the Authorization header is added to
     *  @return The supplied request headers with an added Authroization
     */
    private static func addAuthToken(headers: HTTPHeaders = [:]) -> Promise<HTTPHeaders> {
        // Add authorization header to the HTTPHeaders object
        var new_headers = headers
        new_headers["Authorization"] = "Bearer " + accessToken!

        // Load the current timestamp for the expiration test
        let now = Date()

        // If access token has expired, create a new one
        if accessToken == nil || accessTokenExpires! < now {
            // Chain modified headers to login request to allow it time to complete
            return loginWithToken().then { _ -> HTTPHeaders in
                new_headers
            }
        } else {
            // Wrap the headers in a promise manually, writing function in this way allows chaining
            // on the hidden login request if necessary
            return Promise { fulfill, _ in
                fulfill(new_headers)
            }
        }
    }

    /**
     * Used to store a new refresh token in coredata
     * Stores token, loggedOut as false, and current date
     */
    private static func storeRefreshTokenLocal(token: String) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        // coredata context
        let managedContext =
            appDelegate.persistentContainer.viewContext

        // create refresh token entity
        let entity =
            NSEntityDescription.entity(forEntityName: "RefreshTokens",
                                       in: managedContext)!

        // insert entity into context
        let tokenRow = NSManagedObject(entity: entity,
                                       insertInto: managedContext)

        tokenRow.setValue(token, forKeyPath: "refreshToken")
        tokenRow.setValue(false, forKeyPath: "loggedOut")
        tokenRow.setValue(Date(), forKeyPath: "created")

        do {
            // commit changes to context
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    /**
     * Fetches the most recently created refresh token
     * Checks if it was created within the last 3 months and was not logged out
     * @return the token if two previous conditions are true, else return empty string
     */
    private static func fetchRefreshTokenLocal() -> String {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
            return ""
        }

        // get coredata context
        let managedContext =
            appDelegate.persistentContainer.viewContext

        // init fetch request for refresh tokens
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "RefreshTokens")

        fetchRequest.fetchLimit = 1
        let sort = NSSortDescriptor(key: "created", ascending: false)
        fetchRequest.sortDescriptors = [sort]

        do {
            let tokens = try managedContext.fetch(fetchRequest)

            // expect 1 or 0 results
            if tokens.count > 0 {
                let token = tokens[0]
                let loggedOut = token.value(forKeyPath: "loggedOut") as! Bool
                let created = token.value(forKeyPath: "created") as! Date

                // finds the time after which the token must have been created to still be valid
                let cal = Calendar.current
                var createdAfter = cal.date(byAdding: .month, value: -3, to: Date())

                // decreases valid interval length by 1 minute to account for effect of network latency
                // ie. to prevent the token from dieing in transit to the backend
                createdAfter = cal.date(byAdding: .minute, value: 1, to: createdAfter!)

                if loggedOut == false && created >= createdAfter! {
                    print(token.value(forKeyPath: "refreshToken"))
                    return token.value(forKeyPath: "refreshToken") as! String
                }
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }
        return ""
    }

    /**
     * Marks the most recently created refresh token as logged out
     */
    private static func logoutRefreshTokenLocal() {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        // get coredata context
        let managedContext =
            appDelegate.persistentContainer.viewContext

        // init fetch request for refresh tokens
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "RefreshTokens")

        fetchRequest.fetchLimit = 1
        let sort = NSSortDescriptor(key: "created", ascending: false)
        fetchRequest.sortDescriptors = [sort]
 
        do {
            let tokens = try managedContext.fetch(fetchRequest)

            // expect 1 or 0 results
            if tokens.count > 0 {
                let token = tokens[0]
                token.setValue(true, forKeyPath: "loggedOut")
                do {
                    // commit changes to context
                    try managedContext.save()
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }
    }

    /**
     *  Retreives the metadata for each of the videos in the user's library and populates
     *  an array of video objects with that data. To reduce bandwidth utilization and
     *  make caching simpler, the actual video content is not included and will be nil in
     *  the video objects. Refer to DashiAPI.downloadVideoContent to download the actual
     *  video data.
     *  @return The array of video objects populated by the user's video library metadata
     */
    public static func getAllVideoMetaData() -> Promise<[Video]> {
        return firstly {
            self.addAuthToken()
        }.then { headers in
            self.sessionManager.request(API_ROOT + "/Account/Videos", headers: headers).validate().responseJSON(with: .response).then { value -> [Video] in
                var videos: [Video] = []
                let data = JSON(value.0)
                for datum in data {
                    videos.append(Video(video: datum.1))
                }
                return videos
            }
        }
    }

    public static func downloadVideoContent(video: Video) -> Promise<Data> {
        let url = API_ROOT + "/Account/Videos/" + video.getId() + "/content"
        return firstly {
            self.addAuthToken()
        }.then { headers in
            Alamofire.request(url, method: .get, headers: headers).validate().responseData().then { value -> Data in

                return value
            }
        }.catch { error in
            // convert the error body to a readable string and print
            if let e = error as? DashiServiceError {
                print(String(data: e.body, encoding: .utf8)!)
            }
        }
    }

    /**
     *  Uploads a video's metadeta to the user's library. This function is intended
     *  to be used when the user creates a new recording. The metadata portion should
     *  always be uploaded to cloud storage. The actual video is not included to avoid
     *  consuming the user's wireless data plan. The video content should be uploaded
     *  at an appropriate time according to the user's preferences using
     *  DashAPI.uploadVideoContent
     *  @param video The video object (only the metadata will be used, content != nil will be ignored)
     *  @return The JSON response from the server
     */
    public static func uploadVideoMetaData(video: Video) -> Promise<JSON> {
        let parameters: Parameters = [
            "started": DateConv.toString(date: video.getStarted()),
            "length": video.getLength(),
            "size": video.getSize(),
            "thumbnail": video.getImageContent()!.base64EncodedString(),
            "startLat": video.getStartLat(),
            "startLong": video.getStartLong(),
            "endLat": video.getEndLat(),
            "endLong": video.getEndLong(),
        ]

        return firstly {
            self.addAuthToken()
        }.then { headers in
            self.sessionManager.request(API_ROOT + "/Account/Videos/" + String(video.getId()), method: .put, parameters: parameters, encoding: JSONEncoding.default, headers: headers).validate().responseJSON(with: .response).then { value in
                return JSON(value)
            }
        }
    }

    /**
     *  Uploads a video's content to the user's library. This function is intended
     *  to be used when the user wishes to backup one of their videos in the cloud.
     *  This can be manually trigerred by the user and/or automatically done in the
     *  background at an appropriate time according to the user's preferences. This
     *  function does NOT upload the metadata. Metadata MUST be uploaded BEFORE the
     *  video content is uploading using DahsiAPI.uploadVideoMetaData
     *  @param video The video object (only the content and ID will be used, other metadata will be ignored)
     *  @return The JSON response from the server
     */
    public static func uploadVideoContent(video: Video, offset: Int? = nil) -> Promise<JSON> {
        var url = API_ROOT + "/Account/Videos/" + String(video.getId()) + "/content"

        if let o = offset {
            url = url + "?offset=\(o)"
        }

        print("url: " + url)

        return firstly {
            self.addAuthToken()
        }.then { headers in
            Alamofire.upload(video.getContent()!, to: url, method: .put, headers: headers).validate().responseJSON(with: .response).then { value in
                return JSON(value)
            }
        }.catch { error in
            print(String(data: (error as! DashiServiceError).body, encoding: String.Encoding.utf8)!)
        }
    }

    /**
     *  Modifies the user's profile by uploading a set of fields to update in the
     *  database. This can include fields that haven't actually changed in the case
     *  of programmer error. It will not cause issues but it will waster server
     *  resources. If nonexistant or protected fields are included the server will
     *  reject the request with a 400 error and JSON identifying the offending
     *  portion of the request If the ratio of modified to unmodified fields is low
     *  this function will be more efficient than its overloaded companion.
     *  @param parameters The key-value pairs that will be updated in the database
     *  @return The JSON response from the server
     */
    public static func modifyAccount(parameters: Parameters) -> Promise<JSON> {
        return firstly {
            self.addAuthToken()
        }.then { headers in
            let url: String = API_ROOT + "/Accounts/" + String(parameters["id"] as! Int)
            return self.sessionManager.request(url, method: .patch, parameters: parameters, encoding: JSONEncoding.default, headers: headers).validate().responseJSON(with: .response).then { value in
                JSON(value)
            }
        }
    }

    /**
     *  Modifies the user's profile by uploading the current representation with
     *  every value that is valid to modify. This includes any fields that haven't
     *  actually been changed. This version of the function is intended for when it
     *  is unclear what values have been modified and/or the number of fields is large
     *  enough that is is inconvient to specify them manually with the other function.
     *  If there is a large number of unmodified fields this function will be less
     *  efficient than its overloaded companion.
     *  @param account The account object used to update all relevant fields in the database
     *  @return The JSON response from the server
     */
    public static func modifyAccount(account: Account) -> Promise<JSON> {
        return modifyAccount(parameters: account.toParameters())
    }

    /**
     *  Retreives the user's profile / account information from the server and
     *  places it into an Account object.
     *  @return The JSON response from the server
     */
    public static func getAccountDetails() -> Promise<Account> {
        return firstly {
            self.addAuthToken()
        }.then { headers in
            self.sessionManager.request(API_ROOT + "/Account", headers: headers).validate().responseJSON(with: .response).then { value in
                return Account(account: JSON(value))
            }
        }
    }

    /**
     *  Authenticates the user with username/password credentials by POSTing to API
     *  route /oauth/token to create a bearer token. It stores this token internally
     *  for use in subsequent function calls via the addAuthToken helper function.
     *  @param The username portion of the user's username/password credentials.
     *  @param The password portion of the user's username/password credentials.
     *  @return The JSON response from the server
     */
    public static func loginWithPassword(username: String, password: String) -> Promise<JSON> {
        let parameters: Parameters = [
            "grant_type": "password",
            "password": password,
            "username": username,
        ]

        return login(parameters: parameters)
    }

    /**
     *  Authenticates the user with refresh token credential by POSTing to API route
     *  /oauth/token to create the bearer token. It stores this token internally for
     *  use in subsequent function calls via the addAuthToken helper function.
     *  @param refreshToken The user's refresh token credential. If non supplied will use internal value.
     *  @return The JSON response from the server
     */
    public static func loginWithToken(refreshToken: String? = nil) -> Promise<JSON> {
        // Store the token internally if one is suppplied
        if refreshToken != nil {
            self.refreshToken = refreshToken
        }
        // TODO: What is the default value of allows celluar access? Does this need to be set?
        let parameters: Parameters = [
            "grant_type": "refresh_token",
            "refresh_token": self.refreshToken!,
        ]

        return login(parameters: parameters)
    }

    /**
     *  Handles the response from a login request. Both grant types generate the same
     *  response format so that portion is seperated here to avoid code duplication.
     *  @param data The json body of the login request.
     *  @return The promise chain (empty or with error for caller to catch)
     */
    private static func login(parameters: Parameters) -> Promise<JSON> {
        return sessionManager.request(API_ROOT + "/oauth/token", method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON(with: .response).then { value, _ -> JSON in
            let json = JSON(value)
            
            print(json)

            self.accessToken = json["access_token"].stringValue
            self.accessTokenExpires = Date(timeIntervalSinceNow: json["expires_in"].doubleValue)
            self.refreshToken = json["refresh_token"].stringValue

            storeRefreshTokenLocal(token: self.refreshToken!)

            return json
        }
    }

    /**
     *  Logs out the user by deleting their bearer token (meaning both refresh and access).
     *  @return The JSON response from the server
     */
    public static func logout() -> Promise<JSON> {
        let parameters: Parameters = [
            "refresh_token": self.refreshToken!,
        ]

        return sessionManager.request(API_ROOT + "/oauth/token", method: .delete, parameters: parameters, encoding: JSONEncoding.default).responseJSON(with: .response).then { value -> JSON in
            // Reset all static variables
            self.accessToken = nil
            self.accessTokenExpires = nil
            self.refreshToken = nil

            logoutRefreshTokenLocal()

            return JSON(value)
        }
    }

    /**
     *  Creates a new user account. This function is used exclusively by the signup page.
     *  @param email The email address used to login. Must meet pattern requirements.
     *  @param password The password used to login. Must meet complexity requirements.
     *  @param fullName The user's full name. Stored as one value to avoid issues where the number of names the users have vary.
     *  @return The JSON response from the server
     */
    public static func createAccount(email: String, password: String, fullName: String) -> Promise<JSON> {
        let parameters: Parameters = [
            "email": email,
            "password": password,
            "fullName": fullName,
        ]

        return sessionManager.request(API_ROOT + "/Accounts", method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON(with: .response).then { value -> JSON in
            let json = JSON(value.0)

            return json
        }
    }

    public static func fetchStoredRefreshToken() {
        let rToken = fetchRefreshTokenLocal()
        if rToken != "" {
            refreshToken = rToken
        } else {
            refreshToken = nil
        }
    }

    /**
     * Used to check if the user is currently logged in.
     * Logged in is defined as the presence of a refresh token.
     */
    public static func isLoggedIn() -> Bool {
        print("refresh token:")
        print(refreshToken != nil)
        return refreshToken != nil
    }
}
