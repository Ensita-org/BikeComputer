//
//  BikeComputerWidgetLiveActivity.swift
//  BikeComputerWidget
//
//  Created by Daniel Borek on 11/02/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BikeComputerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct BikeComputerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BikeComputerWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension BikeComputerWidgetAttributes {
    fileprivate static var preview: BikeComputerWidgetAttributes {
        BikeComputerWidgetAttributes(name: "World")
    }
}

extension BikeComputerWidgetAttributes.ContentState {
    fileprivate static var smiley: BikeComputerWidgetAttributes.ContentState {
        BikeComputerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: BikeComputerWidgetAttributes.ContentState {
         BikeComputerWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: BikeComputerWidgetAttributes.preview) {
   BikeComputerWidgetLiveActivity()
} contentStates: {
    BikeComputerWidgetAttributes.ContentState.smiley
    BikeComputerWidgetAttributes.ContentState.starEyes
}
