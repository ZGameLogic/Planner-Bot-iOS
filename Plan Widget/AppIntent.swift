//
//  AppIntent.swift
//  Plan Widget
//
//  Created by Benjamin Shabowski on 7/6/24.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("This is an example widget.")
}
