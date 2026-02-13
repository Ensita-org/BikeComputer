import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var activities: [Activity]
    @AppStorage("useMetricUnits") private var useMetricUnits: Bool = true
    @State private var showingSettings = false
    
    var totalOdometer: Double {
        activities.reduce(0) { $0 + $1.distance }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Bike Computer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Odometer
                VStack {
                    Text("Total Odometer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: useMetricUnits ? "%.1f km" : "%.1f mi", useMetricUnits ? totalOdometer / 1000 : (totalOdometer / 1000) * 0.621371))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                }
                .padding()
                
                NavigationLink(destination: DashboardView()) {
                    Label("Start Ride / Computer", systemImage: "bicycle")
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                
                NavigationLink(destination: HistoryView()) {
                    Label("History", systemImage: "clock")
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(.primary)
                        .cornerRadius(15)
                }
            }
            .padding()
            .navigationTitle("Menu")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}
