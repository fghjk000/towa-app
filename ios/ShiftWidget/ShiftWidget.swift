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

        // ── 잠금화면 (vibrancy 렌더링 — 색상 미적용) ──────
        case .accessoryCircular:
            VStack(spacing: 2) {
                Image(systemName: "clock.fill")
                    .font(.caption2)
                Text(entry.shiftName.prefix(2))
                    .font(.caption2)
                    .fontWeight(.bold)
            }

        case .accessoryRectangular:
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
            Label(entry.shiftName, systemImage: "clock")

        // ── 홈화면 medium: 이름 왼쪽 + 시간 오른쪽 ────────
        case .systemMedium:
            HStack(spacing: 0) {
                Text(entry.shiftName)
                    .font(.title)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !entry.shiftTime.isEmpty {
                    Text(entry.shiftTime)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

        // ── 홈화면 large: 이름 크게 + 시간 ─────────────────
        case .systemLarge:
            VStack(spacing: 8) {
                Text(entry.shiftName)
                    .font(.system(size: 52, weight: .bold))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                if !entry.shiftTime.isEmpty {
                    Text(entry.shiftTime)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()

        // ── 홈화면 small (기본): 이름 + 시간 가운데 ─────────
        default:
            VStack(spacing: 4) {
                Text(entry.shiftName)
                    .font(.title)
                    .fontWeight(.bold)
                if !entry.shiftTime.isEmpty {
                    Text(entry.shiftTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }
}

/// iOS 16 래퍼: accessory 위젯에는 배경 미적용
private struct _IOS16ContainerView: View {
    var entry: ShiftEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        let isAccessory = family == .accessoryCircular
            || family == .accessoryRectangular
            || family == .accessoryInline
        if isAccessory {
            ShiftWidgetEntryView(entry: entry)
        } else {
            ShiftWidgetEntryView(entry: entry)
                .background(Color.clear)
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
                    .containerBackground(.thinMaterial, for: .widget)
            } else {
                _IOS16ContainerView(entry: entry)
            }
        }
        .configurationDisplayName("교대근무")
        .description("오늘의 근무를 확인합니다.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}
