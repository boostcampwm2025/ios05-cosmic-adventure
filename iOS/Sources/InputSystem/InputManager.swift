import ARKit
import Combine

/// InputSystem의 진입점. `InputSourceProtocol` + `InputMapperProtocol`을 조합해 `InputSnapshot`을 제공합니다.
final class InputManager<Source: InputSourceProtocol, Mapper: InputMapperProtocol>: ObservableObject where Source.Raw == Mapper.Raw {

    // MARK: - Output

    @Published private(set) var currentSnapshot: InputSnapshot = .idle

    // MARK: - Dependencies

    private let source: Source
    private let mapper: Mapper
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(source: Source, mapper: Mapper) {
        self.source = source
        self.mapper = mapper
        bind()
    }

    // MARK: - Lifecycle

    func start() {
        source.start()
    }

    func stop() {
        source.stop()
    }

    // MARK: - Binding

    private func bind() {
        source.rawPublisher
            .map { [mapper] in mapper.map($0) }
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentSnapshot)
    }
}

// MARK: - Convenience

extension InputManager where Source == ARKitFaceInputSource, Mapper == FaceInputMapper {
    convenience init() {
        self.init(source: ARKitFaceInputSource(), mapper: FaceInputMapper())
    }
}

extension InputManager where Source: ARSessionProviding {
    var arSession: ARSession { source.arSession }
}
