import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "BigPlan", category: "SettingsViewModel")

@MainActor
class SettingsViewModel: ObservableObject {
    private let context: ModelContext
    private var settings: Settings?

    @Published var initialWeight: Double = 0.0
    @Published var weightTarget: Double = 100.0
    @Published var isSaving = false

    init(context: ModelContext) {
        self.context = context
    }

    func load() {
        do {
            let descriptor = FetchDescriptor<Settings>()
            let settingsArray = try context.fetch(descriptor)
            if let existingSettings = settingsArray.first {
                settings = existingSettings
                weightTarget = existingSettings.weightTarget ?? 100.0

                if let storedInitial = existingSettings.initialWeight {
                    initialWeight = storedInitial
                } else if let firstWeight = fetchFirstEntryWeight() {
                    initialWeight = firstWeight
                    existingSettings.initialWeight = firstWeight
                    try? context.save()
                }
            } else {
                let newSettings = Settings()
                context.insert(newSettings)
                settings = newSettings

                if let firstWeight = fetchFirstEntryWeight() {
                    newSettings.initialWeight = firstWeight
                    initialWeight = firstWeight
                }
                try context.save()
                weightTarget = newSettings.weightTarget ?? 100.0
                initialWeight = newSettings.initialWeight ?? 0.0
            }
        } catch {
            logger.error("Failed to load settings: \(error.localizedDescription)")
        }
    }

    func save() {
        guard let settings = settings else { return }
        settings.weightTarget = weightTarget
        settings.initialWeight = initialWeight
        try? context.save()
    }

    private func fetchFirstEntryWeight() -> Double? {
        let descriptor = FetchDescriptor<DailyHealthEntry>(sortBy: [SortDescriptor(\DailyHealthEntry.date)])
        let entries = try? context.fetch(descriptor)
        return entries?.first?.weight
    }
}
