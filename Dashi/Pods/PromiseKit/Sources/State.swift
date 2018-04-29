import class Dispatch.DispatchQueue
import func Foundation.NSLog

enum Seal<T> {
    case pending(Handlers<T>)
    case resolved(Resolution<T>)
}

enum Resolution<T> {
    case fulfilled(T)
    case rejected(Error, ErrorConsumptionToken)

    init(_ error: Error) {
        self = .rejected(error, ErrorConsumptionToken(error))
    }
}

class State<T> {

    // would be a protocol, but you can't have typed variables of “generic”
    // protocols in Swift 2. That is, I couldn’t do var state: State<R> when
    // it was a protocol. There is no work around. Update: nor Swift 3

    func get() -> Resolution<T>? { fatalError("Abstract Base Class") }
    func get(body _: @escaping (Seal<T>) -> Void) { fatalError("Abstract Base Class") }

    final func pipe(_ body: @escaping (Resolution<T>) -> Void) {
        get { seal in
            switch seal {
            case let .pending(handlers):
                handlers.append(body)
            case let .resolved(resolution):
                body(resolution)
            }
        }
    }

    final func pipe(on q: DispatchQueue, to body: @escaping (Resolution<T>) -> Void) {
        pipe { resolution in
            contain_zalgo(q) {
                body(resolution)
            }
        }
    }

    final func then<U>(on q: DispatchQueue, else rejecter: @escaping (Resolution<U>) -> Void, execute body: @escaping (T) throws -> Void) {
        pipe { resolution in
            switch resolution {
            case let .fulfilled(value):
                contain_zalgo(q, rejecter: rejecter) {
                    try body(value)
                }
            case let .rejected(error, token):
                rejecter(.rejected(error, token))
            }
        }
    }

    final func always(on q: DispatchQueue, body: @escaping (Resolution<T>) -> Void) {
        pipe { resolution in
            contain_zalgo(q) {
                body(resolution)
            }
        }
    }

    final func `catch`(on q: DispatchQueue, policy: CatchPolicy, else resolve: @escaping (Resolution<T>) -> Void, execute body: @escaping (Error) throws -> Void) {
        pipe { resolution in
            switch (resolution, policy) {
            case (.fulfilled, _):
                resolve(resolution)
            case let (.rejected(error, _), .allErrorsExceptCancellation) where error.isCancelledError:
                resolve(resolution)
            case (let .rejected(error, token), _):
                contain_zalgo(q, rejecter: resolve) {
                    token.consumed = true
                    try body(error)
                }
            }
        }
    }
}

class UnsealedState<T>: State<T> {
    private let barrier = DispatchQueue(label: "org.promisekit.barrier", attributes: .concurrent)
    private var seal: Seal<T>

    /**
     Quick return, but will not provide the handlers array because
     it could be modified while you are using it by another thread.
     If you need the handlers, use the second `get` variant.
     */
    override func get() -> Resolution<T>? {
        var result: Resolution<T>?
        barrier.sync {
            if case let .resolved(resolution) = self.seal {
                result = resolution
            }
        }
        return result
    }

    override func get(body: @escaping (Seal<T>) -> Void) {
        var sealed = false
        barrier.sync {
            switch self.seal {
            case .resolved:
                sealed = true
            case .pending:
                sealed = false
            }
        }
        if !sealed {
            barrier.sync(flags: .barrier) {
                switch self.seal {
                case .pending:
                    body(self.seal)
                case .resolved:
                    sealed = true // welcome to race conditions
                }
            }
        }
        if sealed {
            body(seal) // as much as possible we do things OUTSIDE the barrier_sync
        }
    }

    required init(resolver: inout ((Resolution<T>) -> Void)!) {
        seal = .pending(Handlers<T>())
        super.init()
        resolver = { resolution in
            var handlers: Handlers<T>?
            self.barrier.sync(flags: .barrier) {
                if case let .pending(hh) = self.seal {
                    self.seal = .resolved(resolution)
                    handlers = hh
                }
            }
            if let handlers = handlers {
                for handler in handlers {
                    handler(resolution)
                }
            }
        }
    }

    #if !PMKDisableWarnings
        deinit {
            if case .pending = seal {
                NSLog("PromiseKit: Pending Promise deallocated! This is usually a bug")
            }
        }
    #endif
}

class SealedState<T>: State<T> {
    fileprivate let resolution: Resolution<T>

    init(resolution: Resolution<T>) {
        self.resolution = resolution
    }

    override func get() -> Resolution<T>? {
        return resolution
    }

    override func get(body: @escaping (Seal<T>) -> Void) {
        body(.resolved(resolution))
    }
}

class Handlers<T>: Sequence {
    var bodies: [(Resolution<T>) -> Void] = []

    func append(_ body: @escaping (Resolution<T>) -> Void) {
        bodies.append(body)
    }

    func makeIterator() -> IndexingIterator<[(Resolution<T>) -> Void]> {
        return bodies.makeIterator()
    }

    var count: Int {
        return bodies.count
    }
}

extension Resolution: CustomStringConvertible {
    var description: String {
        switch self {
        case let .fulfilled(value):
            return "Fulfilled with value: \(value)"
        case let .rejected(error):
            return "Rejected with error: \(error)"
        }
    }
}

extension UnsealedState: CustomStringConvertible {
    var description: String {
        var rv: String!
        get { seal in
            switch seal {
            case let .pending(handlers):
                rv = "Pending with \(handlers.count) handlers"
            case let .resolved(resolution):
                rv = "\(resolution)"
            }
        }
        return "UnsealedState: \(rv)"
    }
}

extension SealedState: CustomStringConvertible {
    var description: String {
        return "SealedState: \(resolution)"
    }
}
