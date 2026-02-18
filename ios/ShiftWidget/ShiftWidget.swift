import WidgetKit
import SwiftUI

struct ShiftEntry: TimelineEntry {
    let date: Date
    let shiftName: String
    let shiftTime: String
}

struct ShiftProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShiftEntry {
        ShiftEntry(date: Date(), shiftName: "주간", shiftTime: "08:00~17:00")
    }

    func getSnapshot(in context: Context, completion: @escaping (ShiftEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShiftEntry>) -> Void) {
        // 매일 자정에 갱신
        let nextMidnight = Calendar.current.startOfDay(
            for: Date().addingTimeInterval(86400)
        )
        completion(Timeline(entries: [currentEntry()], policy: .after(nextMidnight)))
    }

    private func currentEntry() -> ShiftEntry {
        let defaults = UserDefaults(suiteName: "group.com.shiftwidget")
        let name = defaults?.string(forKey: "shift_name") ?? "로딩 중"
        let time = defaults?.string(forKey: "shift_time") ?? ""
        return ShiftEntry(date: Date(), shiftName: name, shiftTime: time)
    }
}

struct ShiftWidgetEntryView: View {
    var entry: ShiftEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            // 잠금화면 원형 위젯
            VStack(spacing: 2) {
                Image(systemName: "clock.fill")
                    .font(.caption2)
                Text(entry.shiftName.prefix(2))
                    .font(.caption2)
                    .fontWeight(.bold)
            }
        case .accessoryRectangular:
            // 잠금화면 직사각형 위젯
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.shiftName)
                    .font(.headline)
                    .fontWeight(.bold)
                if !entry.shiftTime.isEmpty {
                    Text(entry.shiftTime)
                        .font(.caption)
                }
            }
        case .accessoryInline:
            // 잠금화면 인라인 위젯
            Label(
                entry.shiftName,
                systemImage: "clock"
            )
        default:
            // 홈화면 위젯 (systemSmall, systemMedium)
            VStack(spacing: 4) {
                Text(entry.shiftName)
                    .font(.title)
                    .fontWeight(.bold)
                if !entry.shiftTime.isEmpty {
                    Text(entry.shiftTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("오늘")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

@main
struct ShiftWidgetBundle: WidgetBundle {
    var body: some Widget {
        ShiftWidgetMain()
    }
}

struct ShiftWidgetMain: Widget {
    let kind: String = "ShiftWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShiftProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                ShiftWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                ShiftWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("교대근무")
        .description("오늘의 근무를 확인합니다.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}
