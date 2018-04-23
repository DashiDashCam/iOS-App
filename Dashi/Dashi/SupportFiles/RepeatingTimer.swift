//
//  RepeatingTimer.swift
//  Dashi
//
//  Created by Chris Henk on 3/27/18.
//  Copyright © 2018 Senior Design. All rights reserved.
//
//  The original version of this class was written by: Daniel Galasko [https://github.com/danielgalasko]
//  Original Source: https://gist.github.com/danielgalasko/1da90276f23ea24cb3467c33d2c05768
//  Written as an example for the blog post: https://medium.com/@danielgalasko/a-background-repeating-timer-in-swift-412cecfd2ef9
//
//  The majority of this work is the work of the original author, with the exception of modifications
//  make to the initialization of the class and of the timer variable. These changes replace hard coded
//  example values with variables that can be externally configured, making the object reusable. Also
//  there is some minor refactoring of the original code.

import Dispatch

/// RepeatingTimer mimics the API of DispatchSourceTimer but in a way that prevents
/// crashes that occur from calling resume multiple times on a timer that is
/// already resumed (noted by https://github.com/SiftScience/sift-ios/issues/52
class RepeatingTimer {
    private var timer: DispatchSourceTimer

    init(deadline: DispatchTime = .now(), repeating: DispatchTimeInterval, leeway: DispatchTimeInterval? = nil, callback: @escaping () -> Void) {
        // Initialize the timer
        timer = DispatchSource.makeTimerSource()
        if leeway == nil {
            timer.schedule(deadline: deadline, repeating: repeating)
        } else {
            timer.schedule(deadline: deadline, repeating: repeating, leeway: leeway!)
        }
        timer.setEventHandler(handler: callback)
    }

    private enum State {
        case suspended
        case resumed
    }

    private var state: State = .suspended

    deinit {
        self.timer.setEventHandler {}
        self.timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        self.resume()
    }

    func resume() {
        print("resume")
        if state != .resumed {
            state = .resumed
            timer.resume()
        }
    }

    func suspend() {
        print("suspend")
        if state != .suspended {
            state = .suspended
            timer.suspend()
        }
    }
}
