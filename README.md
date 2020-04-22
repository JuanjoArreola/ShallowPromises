# ShallowPromises

[![License](https://img.shields.io/github/license/JuanjoArreola/ShallowPromises)](https://github.com/JuanjoArreola/ShallowPromises/blob/master/LICENSE)

A Promises Library for Swift 5.

This is a simple library that provides basic Promise functionality.

#### Features:
- Threadsafe
- Lightweight
- Cancellable

#### Considerations:

- The promises themselves don't manage all the threading functionality. 
- It is the responsibility of the *owner* who makes the *Promise* to decide the *Queues* in which 
to create and fulfill the Promise.
- The receiver of the Promise can always change the Queue in which to receive the result of 
the Promise.
- Promises can only be fulfilled once.

#### Installation
- Swift Package Manager

### Making Promises

Typically the *Promiser* creates a Promise in a determined *Queue* and returns it immediately to
the *Receiver*:

```swift
    func requestUser() -> Promise<User> {
        let promise = Promise<User>()
        networkingQueue.async {
            // make HTTP request to get the user
        }
        return promise
    }
```

### Fulfilling Promises
 
Some time in the future the *Promiser* fulfills the promise on a determined *Queue* and the 
*Receiver* uses the result.

```swift
    do {
        let result = try JSONDecoder().decode(User.self, from: data)
        promise.fulfill(with: result, in: responseQueue)
    } catch {
        promise.complete(with: error, in: responseQueue)
    }
```

### How the *Receiver* uses the Promise

The *Receiver* of the *Promise* adds the necessary closures to it, there are four kinds of
closures that can be added the the *Promise*: `then` `onSuccess` `onError` and `finally`:

```swift
    requestUser()
        .then(requestFavorites(of:))
        .onSuccess(updateFavorites)
        .onError(logError)
        .finally(updateView)
```
        
More than one closure can be added to every *Promise*.

### Chaining Promises

It is possible to chain promises using `then`, this method accepts a closure or function that
will be called with the result of the previous promise once completed and will return a new
promise:

```swift
     requestInt(from: "1")
        .then(requestString(from:))
        .then(requestInt(from:))
        .then(requestString(from:))
        .onSuccess { result in
        print(result)
     }
```
     
### Cancelling Promises

A promise can be cancelled by the *Receiver* by calling it's `cancel` method,  in which case 
the `onError` closures will be called with the `` error:

```swift
    let promise = requestUser().onError(logError)
    promise.cancel()
```
