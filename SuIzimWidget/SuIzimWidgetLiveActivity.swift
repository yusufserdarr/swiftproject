//
//  SuIzimWidgetLiveActivity.swift
//  SuIzimWidget
//
//  Created by Yusuf Serdaroğlu on 12.12.2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SuIzimWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SuIzimWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SuIzimWidgetAttributes.self) { context in
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

extension SuIzimWidgetAttributes {
    fileprivate static var preview: SuIzimWidgetAttributes {
        SuIzimWidgetAttributes(name: "World")
    }
}

extension SuIzimWidgetAttributes.ContentState {
    fileprivate static var smiley: SuIzimWidgetAttributes.ContentState {
        SuIzimWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SuIzimWidgetAttributes.ContentState {
         SuIzimWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SuIzimWidgetAttributes.preview) {
   SuIzimWidgetLiveActivity()
} contentStates: {
    SuIzimWidgetAttributes.ContentState.smiley
    SuIzimWidgetAttributes.ContentState.starEyes
}
