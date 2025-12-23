//
//  AddPeopleView.swift
//  FairShare
//
//  Add people screen with fast name input
//

import SwiftUI

struct AddPeopleView: View {
    @State var receipt: Receipt
    @State private var newPersonName = ""
    @State private var navigateToAssign = false
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Who's splitting this bill?")
                    .font(.headline)
                    .padding(.top)
                
                // Name input
                HStack {
                    TextField("Enter name", text: $newPersonName)
                        .textFieldStyle(.roundedBorder)
                        .focused($isNameFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            addPerson()
                        }
                    
                    Button(action: addPerson) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .disabled(newPersonName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal)
                
                // People list
                if !receipt.people.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(receipt.people) { person in
                                HStack {
                                    Text(person.name)
                                        .font(.body)
                                    Spacer()
                                    Button(action: {
                                        removePerson(person)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Continue button
                Button(action: {
                    navigateToAssign = true
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(receipt.people.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(receipt.people.isEmpty)
                .padding(.horizontal)
                .padding(.bottom)
                .frame(minHeight: Constants.minimumTapTargetSize)
            }
            .navigationTitle("Add People")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isNameFieldFocused = true
            }
            .navigationDestination(isPresented: $navigateToAssign) {
                AssignItemsView(receipt: receipt)
            }
        }
    }
    
    private func addPerson() {
        let trimmedName = newPersonName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        let person = Person(name: trimmedName)
        receipt.people.append(person)
        newPersonName = ""
        isNameFieldFocused = true
    }
    
    private func removePerson(_ person: Person) {
        receipt.people.removeAll { $0.id == person.id }
    }
}

