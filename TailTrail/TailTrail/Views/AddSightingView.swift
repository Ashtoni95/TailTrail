//
//  Views:AddSightingView.swift
//  TailTrail
//
//

// Views/AddSightingView.swift
import SwiftUI
import CoreLocation

struct AddSightingView: View {
    @Environment(\.dismiss) var dismiss
    let onAdd: (Double, Double, String, Int, String, String, String?, Int?, Bool) -> Void
    let currentUserId: Int?

    // Location fields
    @State private var showLocationPicker = true
    @State private var selectedCoordinate = CLLocationCoordinate2D(
        latitude: 49.888056,  // Default to Kelowna downtown
        longitude: -119.495556
    )
    
    // New fields
    @State private var selectedBreed: DogBreed = .unknown
    @State private var age = ""
    @State private var chippedStatus = "Unsure"
    @State private var area = ""
    @State private var description = ""
    
    // Validation
    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""
    
    @State private var isLost = false
    
    // For a better UX, you'd get this from your LocationManager
    private let defaultLocation = CLLocationCoordinate2D(
        latitude: 49.888056,
        longitude: -119.495556
    )
    @State private var locationName = ""
    let chippedOptions = ["Yes", "No", "Unsure"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("WHERE DID YOU SEE THE DOG?")) {
                    // Map preview for pin placement
                    ZStack(alignment: .topTrailing) {
                        // Mini map
                        LocationPickerMapView(
                            coordinate: $selectedCoordinate,
                            locationName: $locationName
                        )
                        .frame(height: 200)
                        .cornerRadius(10)
                        .onAppear {
                            // Force resign first responder when map appears
                            #if os(macOS)
                            DispatchQueue.main.async {
                                NSApp.keyWindow?.makeFirstResponder(nil)
                            }
                            #endif
                        }
                        
                        Text("Drag pin to exact spot")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemBackground).opacity(0.8))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                            .padding(8)
                    }
                    
                    // Show the address/location name if available
                    if !locationName.isEmpty {
                        HStack {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text(locationName)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Hidden coordinates display (for debugging, can remove later)
                    Text("Lat: \(selectedCoordinate.latitude), Lon: \(selectedCoordinate.longitude)")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                // Dog Details Section
                Section(header: Text("DOG DETAILS")) {
                    HStack {
                        Text("Breed")
                            .foregroundColor(.primary)
                        Spacer()
                        HStack {
                            Spacer()
                            Picker(selection: $selectedBreed, label: EmptyView()) {
                                ForEach(DogBreed.allCases, id: \.self) { breed in
                                    Text(breed.rawValue).tag(breed)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .frame(width: 200)
                    }

                    // Age
                    HStack {
                        Text("Age")
                            .foregroundColor(.primary)
                        Spacer()
                        HStack {
                            Spacer()
                            Picker(selection: $age, label: EmptyView()) {
                                ForEach(0..<36) { number in
                                    Text("\(number)").tag("\(number)")
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .frame(width: 200)
                    }
                    
                    
                    // Chipped (mandatory)
                    HStack {
                        Text("Chipped:")
                            .foregroundColor(.primary)
                        Spacer()
                        Picker("Chipped", selection: $chippedStatus) {
                            ForEach(chippedOptions, id: \.self) { option in
                                Text(option.capitalized).tag(option)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200) // Adjust width as needed
                    }
                }
                
                Section(header: Text("STATUS")) {
                    Toggle(isOn: $isLost) {
                        HStack {
                            Image(systemName: isLost ? "exclamationmark.triangle.fill" : "pawprint.fill")
                                .foregroundColor(isLost ? .red : .green)
                            Text(isLost ? "Lost Dog" : "Spotted")
                                .foregroundColor(.primary)
                        }
                    }
                    .tint(isLost ? .red : .green)
                }
                
                // Where sighted Section
                Section(header: Text("WHERE EXACTLY?")) {
                    TextField("e.g., Waterfront Park, near the pier", text: $area)
                        .textInputAutocapitalization(.words)
                        .onChange(of: area) {
                            if area.count > 64 {
                                area = String(area.prefix(64))
                            }
                        }
                        .overlay(
                            Text("\(area.count)/64")
                                .font(.caption)
                                .foregroundColor(area.count > 64 ? .red : .gray)
                                .padding(.trailing, 8)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            , alignment: .bottomTrailing
                        )
                }
                .listRowSeparator(.hidden) // This removes the divider line
                
                // Description Section (optional)
                Section(header: Text("DESCRIPTION (OPTIONAL)")) {
                    TextEditor(text: $description)
                        .frame(height: 100)
                        .onChange(of: description) {
                            if description.count > 128 {
                                description = String(description.prefix(128))
                            }
                        }
                    
                    Text("\(description.count)/128")
                        .font(.caption)
                        .foregroundColor(description.count > 128 ? .red : .gray)
                }
                
                // Submit Section
                Section {
                    Button(action: validateAndSubmit) {
                        Text("Report Dog Sighting 🐕")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("New Sighting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Invalid Input", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationErrorMessage)
            }
        }
    }
    
    // In AddSightingView, update the submit validation:
    private func validateAndSubmit() {
        guard let ageInt = Int(age), ageInt >= 0, ageInt <= 35 else {
            validationErrorMessage = "Please enter a valid age between 0 and 35"
            showingValidationError = true
            return
        }
        
        // Validate area (still needed for text description)
        guard !area.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationErrorMessage = "Please enter where you saw the dog"
            showingValidationError = true
            return
        }
        
        // Submit with the pin coordinates
        onAdd(
            selectedCoordinate.latitude,
            selectedCoordinate.longitude,
            selectedBreed.rawValue,
            ageInt,
            chippedStatus,
            area,
            description.isEmpty ? nil : description,
            currentUserId,
            isLost
        )
        dismiss()
    }
}
