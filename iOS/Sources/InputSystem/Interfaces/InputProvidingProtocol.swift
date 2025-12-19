import Combine

/// InputSystem 외부(Gameplay 등)에 InputSnapshot을 제공하기 위한 인터페이스
public protocol InputProvidingProtocol {
    var snapshotPublisher: AnyPublisher<InputSnapshot, Never> { get }
}
