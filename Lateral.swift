//
//  Lateral.swift
//  SwiftData2
//
//  Created by Ryan Fowler on 2015-01-07.
//  Copyright (c) 2015 Ryan Fowler. All rights reserved.
//

public class Lateral {
    
    
    // MARK: async
    
    public class func async(task: ()->Void) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), task)
    }
    
    
    // MARK: main
    
    public class func main(task: ()->Void) {
        dispatch_async(dispatch_get_main_queue(), task)
    }
    
    
    // MARK: for
    
    public class func times(times: UInt, task: (UInt)->Void) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
            dispatch_apply(times, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), task)
        })
    }
    
    
    // MARK: each
    
    public class func each<T>(array: [T], iterator: (T)->Void, callback: ()->Void) {
        let dGroup = dispatch_group_create()
        for item in array {
            dispatch_group_async(dGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
                iterator(item)
            })
        }
        dispatch_group_notify(dGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), callback)
    }
    
    public class func each<T>(array: [T], failableIterator: (T)->Bool, callback: (Bool)->Void) {
        var err = false
        let dGroup = dispatch_group_create()
        for item in array {
            dispatch_group_async(dGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
                if !failableIterator(item) {
                    err = true
                    callback(false)
                    return
                }
            })
        }
        dispatch_group_notify(dGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
            if !err {
                callback(true)
            }
        })
    }
    
    
    // MARK: eachSeries
    
    public class func eachSeries<T>(array: [T], iterator: (T)->Void, callback: (Bool)->Void) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
            for item in array {
                iterator(item)
            }
            callback(true)
        })
    }
    
    public class func eachSeries<T>(array: [T], failableIterator: (T)->Bool, callback: (Bool)->Void) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
            for item in array {
                if !failableIterator(item) {
                    callback(false)
                    return
                }
            }
            callback(true)
        })
    }
    
    
    // MARK: map
    
    public class func map<T,U>(array: [T], iterator: (T)->U, callback: ([U])->Void) {
        var dict: [Int: U] = [:]
        let dGroup = dispatch_group_create()
        for var i = 0; i < array.count; i++ {
            dispatch_group_async(dGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
                dict[i] = iterator(array[i])
            })
        }
        dispatch_group_notify(dGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
            var newArr: [U] = []
            for var i = 0; i < dict.count; i++ {
                newArr.append(dict[i]!)
            }
            callback(newArr)
        })
    }
    
    public class func map<T,U>(array: [T], failableIterator: (T)->(Bool, U), callback: ([U]?)->Void) {
        var dict: [Int: U] = [:]
        var err = false
        let dGroup = dispatch_group_create()
        for var i = 0; i < array.count; i++ {
            dispatch_group_async(dGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
                let (error, val) = failableIterator(array[i])
                if error {
                    err = true
                    callback(nil)
                    return
                }
                dict[i] = val
            })
        }
        dispatch_group_notify(dGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
            if !err {
                var newArr: [U] = []
                for var i = 0; i < dict.count; i++ {
                    newArr.append(dict[i]!)
                }
                callback(newArr)
            }
        })
    }
    
    
    // MARK: mapSeries
    
    public class func mapSeries<T,U>(array: [T], iterator: (T)->U, callback: ([U])->Void) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
            callback(array.map(iterator))
        })
    }
    
    public class func mapSeries<T,U>(array: [T], failableIterator: (T)->(Bool, U), callback: ([U]?)->Void) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
            var newArr: [U] = []
            for item in array {
                let (error, val) = failableIterator(item)
                if error {
                    callback(nil)
                    break
                }
                newArr.append(val)
            }
            callback(newArr)
        })
    }
    
    
    // MARK: series
    
    public class func series(tasks: [()->Void]) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
            for task in tasks {
                task()
            }
        })
    }
    
    public class func series(tasks: [()->Void], callback: ()->Void) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
            for task in tasks {
                task()
            }
            callback()
        })
    }
    
    public class func series(failableTasks: [()->Bool], callback: (Bool)->Void) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
            for task in failableTasks {
                if !task() {
                    callback(false)
                    return
                }
            }
            callback(true)
        })
    }
    
    
    // MARK: parallel
    
    public class func parallel(tasks: [()->Void]) {
        for task in tasks {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), task)
        }
    }
    
    public class func parallel(tasks: [()->Void], callback: ()->Void) {
        let dGroup = dispatch_group_create()
        for task in tasks {
            dispatch_group_async(dGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), task)
        }
        dispatch_group_notify(dGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), callback)
    }
    
    public class func parallel(failableTasks: [()->Bool], callback: (Bool)->Void) {
        var err = false
        let dGroup = dispatch_group_create()
        for task in failableTasks {
            dispatch_group_async(dGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
                if !task() {
                    err = true
                    callback(false)
                    return
                }
            })
        }
        dispatch_group_notify(dGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
            if !err {
                callback(true)
            }
        })
    }
    
    
    // MARK: waterfall
    
    public class func waterfall<T>(initial: T, tasks: [(T)->T], callback: (T)->Void) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
            var value = initial
            for task in tasks {
                value = task(value)
            }
            callback(value)
        })
    }
    
    public class func waterfall<T>(initial: T?, failableTasks: [(T?)->T?], callback: (T?)->Void) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
            var value = initial
            for task in failableTasks {
                value = task(value)
                if value == nil {
                    callback(nil)
                    break
                }
            }
            callback(value)
        })
    }
    
    
    // MARK: retry
    
    public class func retry(times: Int, task: ()->Bool, callback: (Bool)->Void) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
            var tries = 0
            while (tries < times) {
                if task() {
                    callback(true)
                    return
                }
                tries++
            }
            callback(false)
        })
    }
    
}
