/// 물리적 충돌의 의미적 타입
public enum ContactType: Equatable {
    case ground   // 바닥 (점프 초기화 가능)
    case wall     // 벽
    case ceiling  // 천장
    case hazard   // 위험물 (게임 오버)
}
