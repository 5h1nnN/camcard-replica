//
//  ContentView.swift
//  CamCardReplica
//
//  Created by Makoto Wu on 2026/10/29.
//

import SwiftUI

struct ContentView: View {
    @State private var navigation = AppNavigationModel()

    var body: some View {
        NavigationStack(path: $navigation.path) {
            VStack(spacing: AppSpacing.large) {
                Image(systemName: "rectangle.stack.badge.person.crop")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(AppColors.primary)

                VStack(spacing: AppSpacing.small) {
                    Text("CamCard Replica")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)

                    Text("工程基线已就绪")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.pageBackground)
            .navigationTitle("阶段 0")
        }
        .environment(navigation)
        .accessibilityIdentifier("stage0.root")
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.light)
}
