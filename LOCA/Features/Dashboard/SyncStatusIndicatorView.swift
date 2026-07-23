//
//  SyncStatusIndicatorView.swift
//  LOCA
//
//  Phase 3.5 — Sync status indicator for multi-device sync.
//
//  Non-blocking indicator shows current sync state (idle/syncing/error).
//  Placed in toolbar; auto-hides on idle.
//

import SwiftUI

struct SyncStatusIndicatorView: View {

    let syncStatus: SyncStatusCoordinator.SyncStatus

    var body: some View {
        switch syncStatus {
        case .idle:
            EmptyView()
        case .syncing:
            ProgressView()
                .scaleEffect(0.8)
        case .error(let message):
            HStack(spacing: DS.Space.sm) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                Text("Sync failed")
                    .font(DS.Text.caption)
                    .foregroundStyle(.red)
            }
            .padding(.horizontal, DS.Space.md)
            .padding(.vertical, DS.Space.xs)
            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: DS.Radius.control))
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DS.Space.lg) {
        Group {
            Text("Idle (hidden):")
            SyncStatusIndicatorView(syncStatus: .idle)
                .frame(height: 20)
        }

        Group {
            Text("Syncing:")
            SyncStatusIndicatorView(syncStatus: .syncing)
                .frame(height: 20)
        }

        Group {
            Text("Error:")
            SyncStatusIndicatorView(syncStatus: .error("CloudKit unavailable"))
                .frame(height: 20)
        }
    }
    .padding(DS.Space.lg)
}
