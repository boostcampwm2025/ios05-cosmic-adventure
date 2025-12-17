import Combine
import Foundation

/// 게임 룰과 캐릭터 상태를 관리하는 매니저
final class GameplayManager: ObservableObject {
    
    // MARK: - Output

    @Published private(set) var state = CharacterState()
    
    /// 즉발적인 동작 명령 (예: 점프 힘 가하기)
    /// PhysicsKit이 이걸 구독해서 실제 물리력을 가함
    let jumpImpulseSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - Constants
    
    private let maxJumpCount = 2
    
    // MARK: - Private
    
    private var cancellables = Set<AnyCancellable>()
    private var lastJumpTriggered = false
    
    // MARK: - Init
    
    init() {}
    
    // MARK: - Setup
    
    /// InputSystem과 연결 (프로토콜 의존)
    func bind(inputProvider: InputProvidingProtocol) {
        inputProvider.snapshotPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.processInput(snapshot)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Logic (Input)
    
    private func processInput(_ snapshot: InputSnapshot) {
        state.moveX = snapshot.moveX
        
        if snapshot.jumpTriggered && !lastJumpTriggered {
            tryJump()
        }
        lastJumpTriggered = snapshot.jumpTriggered
    }
    
    private func tryJump() {
        guard state.isAlive else { return }
        
        // 점프 횟수 제한 체크
        if state.jumpCount < maxJumpCount {
            state.jumpCount += 1
            state.isGrounded = false
            jumpImpulseSubject.send() // PhysicsKit에 "점프해!" 명령 전달
        }
    }
    
    // MARK: - Logic (Physics Feedback)
    
    /// Scene으로부터 물리적 충돌 사실을 보고받음
    func handleContact(_ type: ContactType) {
        switch type {
        case .ground:
            if !state.isGrounded {
                state.isGrounded = true
                state.jumpCount = 0 // 점프 횟수 리셋
            }
        case .hazard:
            state.isAlive = false
            // TODO: 게임 오버 처리
        case .wall, .ceiling:
            break // 특별한 상태 변화 없음
        }
    }
}
