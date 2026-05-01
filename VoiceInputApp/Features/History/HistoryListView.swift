import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Query(sort: [SortDescriptor(\HistoryEntry.createdAt, order: .reverse)])
    private var entries: [HistoryEntry]

    var body: some View {
        List(entries) { entry in
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.finalText).lineLimit(3)
                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView("还没有历史记录", systemImage: "clock")
            }
        }
        .navigationTitle("历史记录")
    }
}
