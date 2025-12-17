import Combine

protocol InputSourceProtocol {
    associatedtype Raw

    var rawPublisher: AnyPublisher<Raw, Never> { get }

    func start()
    func stop()
}
