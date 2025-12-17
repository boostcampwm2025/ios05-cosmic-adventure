/// 캐릭터의 논리적 상태
struct CharacterState: Equatable {
    /// 현재 이동 의도 (-1.0 ~ 1.0)
    var moveX: Double = 0
    
    /// 현재 사용한 점프 횟수 (0: 바닥, 1: 1단 점프 중, 2: 2단 점프 중)
    var jumpCount: Int = 0
    
    /// 바닥에 닿아있는지 여부
    var isGrounded: Bool = false
    
    /// 생존 여부
    var isAlive: Bool = true
}
