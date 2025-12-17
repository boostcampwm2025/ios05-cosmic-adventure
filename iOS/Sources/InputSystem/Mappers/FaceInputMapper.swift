import Foundation


/// 얼굴 raw 데이터를 게임 입력(InputSnapshot)으로 매핑
final class FaceInputMapper: InputMapperProtocol {
    typealias Raw = FaceRawInput
    
    // MARK: - Configuration
    
    struct Config {
        // 좌우 이동 (roll 기반)
        var deadZone: Double = 0.08          // ~5도, 작은 흔들림 무시
        var maxTilt: Double = 0.35           // ~20도, 최대 입력
        var minInput: Double = 0.25          // 최소 입력 보정 (답답함 방지)
        var smoothingAlpha: Double = 0.2     // lerp 계수 (낮을수록 부드러움)
        
        // mouthPucker 기반 점프 트리거
        var puckerThresholdOn: Double = 0.55
        var puckerThresholdOff: Double = 0.45
        var puckerCooldown: TimeInterval = 0.25  // 250ms
    }
    
    // MARK: - State
    
    private var config: Config
    private var smoothedMoveX: Double = 0
    private var isPuckerPressed: Bool = false
    private var lastPuckerTriggerTime: Date = .distantPast
    
    // MARK: - Init
    
    init(config: Config = Config()) {
        self.config = config
    }
    
    // MARK: - Mapping
    
    func map(_ raw: FaceRawInput) -> InputSnapshot {
        let moveX = mapRollToMoveX(raw.roll)
        let jumpTriggered = mapPuckerToJumpTriggered(raw.mouthPucker)

        return InputSnapshot(moveX: moveX, jumpTriggered: jumpTriggered)
    }

    /// raw 데이터를 InputSnapshot으로 매핑 (테스트/디버깅용 convenience)
    func map(roll: Double, mouthPucker: Double) -> InputSnapshot {
        map(.init(roll: roll, mouthPucker: mouthPucker))
    }
    
    // MARK: - Roll → MoveX
    
    private func mapRollToMoveX(_ roll: Double) -> Double {
        let absRoll = abs(roll)
        
        // Deadzone 내면 0
        guard absRoll > config.deadZone else {
            smoothedMoveX = lerp(smoothedMoveX, 0, config.smoothingAlpha)
            return smoothedMoveX
        }
        
        // 정규화: (absRoll - deadZone) / (maxTilt - deadZone) → 0..1
        let normalized = (absRoll - config.deadZone) / (config.maxTilt - config.deadZone)
        var clamped = min(max(normalized, 0), 1)
        
        // 최소 입력 보정 (살짝 기울여도 너무 느리지 않게)
        if clamped > 0 {
            clamped = max(clamped, config.minInput)
        }
        
        // 방향 적용 (roll+ = 왼쪽 기울임 = 왼쪽 이동 = -moveX)
        let target = roll > 0 ? -clamped : clamped
        
        // 스무딩
        smoothedMoveX = lerp(smoothedMoveX, target, config.smoothingAlpha)
        
        return smoothedMoveX
    }
    
    // MARK: - Pucker → Jump Trigger
    
    private func mapPuckerToJumpTriggered(_ pucker: Double) -> Bool {
        let now = Date()
        
        // 히스테리시스: on threshold를 넘으면 pressed, off threshold 아래로 내려가면 released
        if pucker > config.puckerThresholdOn && !isPuckerPressed {
            isPuckerPressed = true
            
            // 쿨다운 체크
            if now.timeIntervalSince(lastPuckerTriggerTime) >= config.puckerCooldown {
                lastPuckerTriggerTime = now
                return true
            }
        } else if pucker < config.puckerThresholdOff {
            isPuckerPressed = false
        }
        
        return false
    }
}
