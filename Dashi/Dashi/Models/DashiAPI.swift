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
    public static func addAuthToken(headers: HTTPHeaders = [:]) -> Promise<HTTPHeaders> {
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

    private static func updateUploadProgress(id: String, progress: Int) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        // coredata context
        let managedContext =
            appDelegate.persistentContainer.viewContext

        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Videos")
        fetchRequest.predicate = NSPredicate(format: "id == %@  && accountID == %d", id, (sharedAccount?.id)!)
        var result: [NSManagedObject] = []
        // 3
        do {
            result = (try managedContext.fetch(fetchRequest))
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }
        let video = result[0]

        video.setValue(progress, forKey: "uploadProgress")

        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
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

    public static func downloadVideoContent(video: Video) {
        let url = URL(string: API_ROOT + "/Account/Videos/" + video.getId() + "/content")!
        let task = DownloadManager.shared.activate().downloadTask(with: url)
        task.taskDescription = video.getId()
        task.resume()
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
        print("Uploading MetaData")
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
     *  Helper function for file upload chunking
     */
    private static func uploadChunk(id: String, video: Data, part: Int, retry: Int) -> Promise<JSON> {
        // Constants
        let BASE_URL = API_ROOT + "/Account/Videos/" + id + "/content"
        let CHUNK_SIZE = 1_048_576 // Constant defining max file chunk size (in bytes)
        let RETRY_LIMIT = 3 // Constant defining the max number of retries allowed
        let UPLOAD_COMPELTED = -1 // Constant defining the finished uploading signal

        let config = URLSessionConfiguration.background(withIdentifier: "com.dashidashcam.sdf.background")
        config.httpAdditionalHeaders = ["Host": "api.dashidashcam.com"]

        return firstly {
            self.addAuthToken()
        }.then { headers in
            // Determine video slice
            let start = part * CHUNK_SIZE

            // Chunk(s) exist that haven't been uploaded
            if start < video.count {
                let url = BASE_URL + "?offset=\(part)"
                let end = (start + CHUNK_SIZE) < video.count ? (start + CHUNK_SIZE - 1) : (video.count - 1)
                print("Uploading Chunk: \(part)")
                // Background upload/downloads must occur from disk, so dump to temp file
                let tempFile = TempFile(extension: "MOV", content: video[start ... end])
                // sleep(1)
                return self.sessionManager.upload(tempFile.tmpFileURL.contentURL, to: url, method: .put, headers: headers).validate().responseJSON(with: .response).then { _ in
                    let progress = (Double(end) / Double(video.count)) * 100
                    self.updateUploadProgress(id: id, progress: Int(progress))
                    return uploadChunk(id: id, video: video, part: part + 1, retry: 0)
                }
            } else {
                let url = BASE_URL + "?offset=\(UPLOAD_COMPELTED)"
                return self.sessionManager.request(url, method: .put, headers: headers).validate().responseJSON(with: .response).then { value -> JSON in
                    self.updateUploadProgress(id: id, progress: 100)
                    return JSON(value)
                }
            }
        }.recover { error -> Promise<JSON> in
            // let asdfadfk = (String(data: (error as! DashiServiceError).body, encoding: String.Encoding.utf8)!)
            print(String(data: (error as! DashiServiceError).body, encoding: String.Encoding.utf8)!)

            // Retry if limit not hit
            guard retry < RETRY_LIMIT else {
                print("Retry Limit Exceeded on Part: \(part)")
                throw error
            }
            if let e = error as? DashiServiceError {
                print(e.statusCode)
                print(JSON(e.body))
            }

            return uploadChunk(id: id, video: video, part: part, retry: retry + 1)
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
    public static func uploadVideoContent(video: Video) -> Promise<JSON> {
        print("Uploading Content")

        // Video.getContent() loads each time, so load once and just pass the returned Data object
        let content = video.getContent()!

        // Begin recursive call chain (required b/c of promises; loop would spawn many parallel threads)
        return uploadChunk(id: video.getId(), video: content, part: 0, retry: 0)
    }

    public static func uploadVideoContent(id: String, url: URL) -> Promise<JSON> {
        print("Uploading Content")

        var content: Data?

        do {
            content = try Data(contentsOf: url)
        } catch let error {
            print("Could not get video content. \(error)")
        }

        return uploadChunk(id: id, video: content!, part: 0, retry: 0)
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
            self.sessionManager.request(API_ROOT + "/Account", headers: headers).validate().responseJSON(with: .response).then { value -> Account in
                return Account(account: JSON(value.0))
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
            DashiAPI.getAccountDetails().then { account in
                sharedAccount = account
            }

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

    /**
     *  Creates a shareable download link for a video with a given id.
     *  @param id The id of the video to create a download link for.
     *  @return A promise that fulfills with the download link
     */
    public static func createDownloadLink(id: String) -> Promise<String> {
        print(id)
        let parameters: Parameters = [
            "id": id,
        ]

        return sessionManager.request(API_ROOT + "/Share", method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON(with: .response).then { value -> String in
            let json = JSON(value.0)

            // print(json)
            // print(json["shareID"].stringValue)
            return API_ROOT + "/Share/" + json["shareID"].stringValue
        }.catch { error in
            if let e = error as? DashiServiceError {
                // prints a more detailed error message from slim
                print(String(data: (error as! DashiServiceError).body, encoding: String.Encoding.utf8)!)

                print(e.statusCode)
            }
        }
    }

    public static func fetchStoredRefreshToken() -> Bool {
        let rToken = fetchRefreshTokenLocal()
        if rToken != "" {
            refreshToken = rToken
            return true
        } else {
            refreshToken = nil
            return false
        }
    }

    /**
     * Used to check if the user is currently logged in.
     * Logged in is defined as the presence of an access token.
     */
    public static func isLoggedIn() -> Bool {
        return accessToken != nil
    }
}
