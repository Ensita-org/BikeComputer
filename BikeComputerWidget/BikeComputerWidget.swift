import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

struct BikeActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BikeActivityAttributes.self) { context in
            // Lock Screen UI
            ActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text("\(Int(context.state.currentSpeed * (context.state.useMetricUnits ? 3.6 : 2.23694)))")
                            .font(.title2)
                    } icon: {
                        Image(systemName: "speedometer")
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Label {
                        Text(formatDuration(context.state.duration))
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "timer")
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Controls
                    HStack {
                         Button(intent: PauseActivityIntent()) {
                             Image(systemName: context.state.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                 .resizable()
                                 .frame(width: 40, height: 40)
                         }
                         
                         Spacer()
                         
                         Button(intent: StopActivityIntent()) {
                             Image(systemName: "stop.circle.fill")
                                 .resizable()
                                 .frame(width: 40, height: 40)
                                 .foregroundColor(.red)
                         }
                    }
                    .padding()
                }
            } compactLeading: {
                Image(systemName: "bicycle")
            } compactTrailing: {
                Text("\(Int(context.state.currentSpeed * (context.state.useMetricUnits ? 3.6 : 2.23694)))")
            } minimal: {
                Image(systemName: "bicycle")
            }
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }
}

struct ActivityView: View {
    let context: ActivityViewContext<BikeActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // Main Stats Row
            HStack(alignment: .bottom, spacing: 0) {
                // Speed (Big)
                VStack(alignment: .leading, spacing: -5) {
                    Text("Speed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", context.state.currentSpeed * (context.state.useMetricUnits ? 3.6 : 2.23694)))
                            .font(.system(size: 80, weight: .heavy, design: .rounded))
                            .minimumScaleFactor(0.5)
                        
                        Text(context.state.useMetricUnits ? "km/h" : "mph")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                    }
                }
                
                Spacer()
                
                // Secondary Stats (Vertical stack on right)
                VStack(alignment: .trailing, spacing: 8) {
                    // Duration
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Time")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text(formatDuration(context.state.duration))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    
                    // Distance
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Dist")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: "%.2f", context.state.distance / 1000))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                            Text(context.state.useMetricUnits ? "km" : "mi")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // Buttons
            HStack(spacing: 20) {
                if context.state.isPaused {
                    Button(intent: ResumeActivityIntent()) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Resume")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                } else {
                    Button(intent: PauseActivityIntent()) {
                        HStack {
                            Image(systemName: "pause.fill")
                            Text("Pause")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                Button(intent: StopActivityIntent()) {
                    Image(systemName: "stop.fill")
                        .font(.headline)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }
            }
        }
        .padding(.vertical)
        .activityBackgroundTint(Color(UIColor.systemBackground))
        .activitySystemActionForegroundColor(Color.primary)
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }
}
