/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import Foundation

/**
 Synchronize, on the given queue, the provided operation. This, in effect,
 creates an atomic operation on the value provided, if it is always accessed
 in this manner. This behaves similary to the `synchronized` keywork in Java.

 - parameter queue: The `dispatch_queue_t` (lock-like) to synchronized on
 - parameter block: The operation to perform on the queue
 */
public func syncWith(queue: dispatch_queue_t, block: (() -> Void)) {
    dispatch_sync(queue, block)
}

/**
 Delay the given operation by the specified amount of time.

 - parameter delay: How long to delay the operation by, in seconds
 - parameter block: The block to execute after the delay

 - returns: An object that you can use to pass to `cancelDelayedBlock(_:)` to cancel the operation from being performed
 */
public func delay(delay: NSTimeInterval, block: (() -> Void)) -> Any {
    var cancelled = false;
    let cancellableBlock: ((Bool) -> Void) = { (cancel) in
        if cancel {
            cancelled = true
            return
        }
        if !cancelled {
            block()
        }
        return
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * NSTimeInterval(NSEC_PER_SEC))), dispatch_get_main_queue()) {
        cancellableBlock(false)
    }
    return cancellableBlock
}

/**
 Cancel the delayed executiion of the block provided to the `delay(_:block:)` function.

 - parameter delayedBlock: The object returned as the result of calling the delay function
 */
public func cancelDelayedBlock(delayedBlock: Any) {
    if let cancellableBlock = delayedBlock as? ((Bool) -> Void) {
        cancellableBlock(true)
    }
}

/**
 Perform the specified operation on the given queue. The type parameter specified for this function indicates
 what type of return value the background function should return, as well as what type of value should be
 accepted by the function that will be executed on the main queue.

 - parameter queue:          The `dispatch_queue_t` to perform the background operation on
 - parameter closureOnQueue: The function to execute on this queue
 - parameter onMain:         The function to execute on the main queue with the result returned by the background operation
 */
private func dispatchOnQueue<T>(queue: dispatch_queue_t, closureOnQueue: (() -> T), onMain: ((T) -> Void)) {
    dispatch_async(queue) {
        let result = closureOnQueue()
        dispatchOnMainQueue {
            onMain(result)
        }
    }
}

/**
 Perform the specified operation on the given queue.

 - parameter queue:          The `dispatch_queue_t` to perform the background operation on
 - parameter closureOnQueue: The function to execute on this queue
 */
private func dispatchOnQueue(queue: dispatch_queue_t, closureOnQueue: (() -> Void)) {
    dispatch_async(queue, closureOnQueue)
}

/**
 Invokes `dispatchOnQueue(_:closureOnQueue:onMain:)` by getting the global queue for the specified `dispatch_qos_class_t`.

 - parameter qos:            The QOS classification (`dispatch_qos_class_t`)
 - parameter closureOnQueue: The function to execute on this queue
 - parameter onMain:         The function to execute on the main queue with the result returned by the background operation
 */
public func dispatchWithQOS<T>(qos: dispatch_qos_class_t, closureOnQueue: (() -> T), onMain: ((T) -> Void)) {
    dispatchOnQueue(dispatch_get_global_queue(qos, 0), closureOnQueue: closureOnQueue, onMain: onMain)
}

/**
 Invokes `dispatchOnQueue(_:closureOnQueue:)` by getting the global queue for the specified `dispatch_qos_class_t`.

 - parameter qos:     The QOS classification (`dispatch_qos_class_t`)
 - parameter closureOnQueue: The function to execute on this queue
 */
public func dispatchWithQOS(qos: dispatch_qos_class_t, closureOnQueue: (() -> Void)) {
    dispatchOnQueue(dispatch_get_global_queue(qos, 0), closureOnQueue: closureOnQueue)
}

/**
 Invokes `dispatchWithQOS(_:closureOnQueue:closureOnMain:)` with a QOS classification of `QOS_CLASS_BACKGROUND`.

 - parameter onBackground:  The function to execute on the background queue
 - parameter onMain:        The function to execute on the main queue with the result returned by the background operation
 */
public func doInBackground<T>(onBackground: (() -> T), onMain: ((T) -> Void)) {
    dispatchWithQOS(QOS_CLASS_BACKGROUND, closureOnQueue: onBackground, onMain: onMain)
}

/**
 Invokes `dispatchWithQOS(_:closureOnQueue:)` with a QOS classification of `QOS_CLASS_BACKGROUND`.

 - parameter onBackground: The function to execute on the background queue
 */
public func doInBackground(onBackground: (() -> Void)) {
    dispatchWithQOS(QOS_CLASS_BACKGROUND, closureOnQueue: onBackground)
}

/**
 Submit the given closure for execution on the main queue and return immediately

 - parameter closure: The block to executed
 */
public func dispatchOnMainQueue(closure: (() -> Void)) {
    dispatch_async(dispatch_get_main_queue(), closure)
}
