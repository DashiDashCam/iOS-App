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

// This class is a set of wrapper functions for easy use of the Dashi API

class DashiAPI {
    /** Base URL to be prepended to all routes */
    private static let API_ROOT = "http://api.dashidashcam.com"
    
    // TODO: Documentation implies NFC is now accesible on iOS, confirm if this is the case.
    // TODO: Determine if read/write refreshToken to disk is best handled here or externally
    /** The refresh token used to request new access tokens */
    private static var refreshToken: String? = nil;
    
    /** The access token that is supplied in the Authorization header of all authenticated API calls */
    private static var accessToken: String? = nil;
    
    /** The timestamp that the current access token expires at */
    private static var accessTokenExpires: Date? = nil;
    
    /**
     *  Convenience function that adds the Authroization header to the given request.
     *  Intended to be used in all functions that make use of authenticated API calls.
     *  This function test the access token's validity before adding to the request.
     *  If the token is invalid it will automatically initiate the necessary API calls
     *  to replace it with a valid one.
     *  @param request The URLRequest to add the Authorization header to. Passed as an inout.
     */
    private static func addAuthToken(headers: HTTPHeaders = [:]) -> Promise<HTTPHeaders> {
        // Add authorization header to the HTTPHeaders object
        var new_headers = headers
        new_headers["Authorization"] = "Bearer " + self.accessToken!
        
        // Load the current timestamp for the expiration test
        let now = Date()
        
        // If access token has expired, create a new one
        if self.accessTokenExpires! < now {
            // Chain modified headers to login request to allow it time to complete
            return self.loginWithToken().then {
                return new_headers
            }
        }
        else {
            // Wrap the headers in a promise manually, writing function in this way allows chaining
            // on the hidden login request if necessary
            return Promise { fulfill, reject in
                fulfill(new_headers)
            }
        }
    }
    
    static func getAllVideoMetaData() {
    
    }
    
    static func downloadVideoContent() {
    
    }
    
    static func uploadVideoMetaData(id _: String, timestamp _: String, size _: Int, length _: Int) {
    
    }
    
    static func uploadVideoContent() {
    
    }
    
    static func createAccount(name _: String, email _: String, password _: String, callback: (() -> Void)) {
        callback()
    }
    
    static func modifiyAccount() {
    
    }
    
    static func getAccountDetails() -> Promise<JSON> {
        // TODO: Play around with alamofire .validate()
        return firstly {
            self.addAuthToken()
        }.then { headers in
            return Alamofire.request(API_ROOT + "/Account", headers: headers).responseJSON().then { value in
                return JSON(value)
            }
        }
    }
    
    /**
     *  Authenticates the user with username/password credentials by POSTing to API
     *  route /oauth/token to create a bearer token. It stores this token internally
     *  for use in subsequent function calls via the addAuthToken helper function.
     *  @param The username portion of the user's username/password credentials.
     *  @param The password portion of the user's username/password credentials.
     */
    static func loginWithPassword(username: String, password: String) -> Promise<Void> {
        let parameters: Parameters = [
            "grant_type": "password",
            "password": password,
            "username": username
        ]
        
        return self.login(parameters: parameters)
    }
    
    /**
     *  Authenticates the user with refresh token credential by POSTing to API route
     *  /oauth/token to create the bearer token. It stores this token internally for
     *  use in subsequent function calls via the addAuthToken helper function.
     *  @param refreshToken The user's refresh token credential. If non supplied will use internal value.
     */
    static func loginWithToken(refreshToken: String? = nil) -> Promise<Void> {
        // Store the token internally if one is suppplied
        if refreshToken != nil {
            self.refreshToken = refreshToken
        }
        // TODO: What is the default value of allows celluar access? Does this need to be set?
        let parameters: Parameters = [
            "grant_type": "refresh_token",
            "refresh_token": self.refreshToken!
        ]
        
        return self.login(parameters: parameters)
    }
    
    /**
     *  Handles the response from a login request. Both grant types generate the same
     *  response format so that portion is seperated here to avoid code duplication.
     *  @param data The json body of the login request.
     *  @return The promise chain (empty or with error for caller to catch)
     */
    private static func login(parameters: Parameters) -> Promise<Void> {
        return Alamofire.request(API_ROOT + "/oauth/token", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON().then { value -> Void in
            let json = JSON(value)
            self.accessToken = json["access_token"].string
            self.accessTokenExpires = Date().addingTimeInterval(json["expires_in"].double!)
            self.refreshToken = json["refresh_token"].string
        }
    }
    
    /**
     *  Logs out the user by deleting their bearer token (meaning both refresh and access).
     */
    static func logout() -> Promise<Void> {
        let parameters: Parameters = [
            "refresh_token": self.refreshToken!
        ]
        
        return Alamofire.request(API_ROOT + "/oauth/token", method: .delete, parameters: parameters, encoding: JSONEncoding.default).responseJSON().then { value -> Void in
            // Reset all static variables
            self.accessToken = nil
            self.accessTokenExpires = nil
            self.refreshToken = nil
        }
    }
}

