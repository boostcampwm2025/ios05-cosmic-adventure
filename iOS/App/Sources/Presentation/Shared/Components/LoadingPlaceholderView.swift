//
//  LoadingPlaceholderView.swift
//  App
//

import SwiftUI

/// 비동기 데이터 로딩 중에 표시되는 공통 placeholder.
/// 확정되지 않은 상태에서 의미 있는 UI가 잘못 보이는 플리커를 방지하기 위해 사용한다.
struct LoadingPlaceholderView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(.white)
            Spacer()
        }
    }
}
