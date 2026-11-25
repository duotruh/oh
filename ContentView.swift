import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store
    @State private var showAdd = false

    private var tasks: [RoutineTask] {
        store.state.tasks.sorted { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
    }
    private var doneCount: Int { tasks.filter { store.isDone($0) }.count }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        stat("🔥", "\(store.state.streak)", "Chuỗi")
                        Divider()
                        stat("🏆", "\(store.state.bestStreak)", "Kỷ lục")
                        Divider()
                        stat("⭐️", "\(store.state.points)", "Điểm")
                    }
                    if !tasks.isEmpty {
                        ProgressView(value: Double(doneCount), total: Double(tasks.count))
                        Text("Hôm nay: \(doneCount)/\(tasks.count) việc. Xong hết trước 24h để giữ chuỗi.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                Section("Chuỗi công việc hôm nay") {
                    if tasks.isEmpty {
                        Text("Bấm + để thêm việc đầu tiên").foregroundStyle(.secondary)
                    }
                    ForEach(tasks) { t in
                        Button { store.toggle(t) } label: {
                            HStack {
                                Image(systemName: store.isDone(t) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(store.isDone(t) ? .green : .secondary)
                                    .font(.title3)
                                VStack(alignment: .leading) {
                                    Text(t.title)
                                        .strikethrough(store.isDone(t))
                                        .foregroundStyle(.primary)
                                    Text(String(format: "%02d:%02d", t.hour, t.minute) + (t.remind ? " 🔔" : ""))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete { idx in store.delete(ids: idx.map { tasks[$0].id }) }
                }

                if !store.state.log.isEmpty {
                    Section("Nhật ký thưởng / phạt") {
                        ForEach(store.state.log.prefix(15), id: \.self) { Text($0).font(.footnote) }
                    }
                }
            }
            .navigationTitle("Streak Routine")
            .toolbar {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
            .sheet(isPresented: $showAdd) { AddTaskView().environmentObject(store) }
        }
    }

    private func stat(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack {
            Text(icon + " " + value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity)
    }
}

struct AddTaskView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var time = Date()
    @State private var remind = true

    var body: some View {
        NavigationStack {
            Form {
                TextField("Tên công việc", text: $title)
                DatePicker("Giờ", selection: $time, displayedComponents: .hourAndMinute)
                Toggle("Nhắc báo thức hằng ngày", isOn: $remind)
            }
            .navigationTitle("Thêm việc")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Huỷ") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        let c = Calendar.current.dateComponents([.hour, .minute], from: time)
                        store.add(title: title.trimmingCharacters(in: .whitespaces),
                                  hour: c.hour ?? 8, minute: c.minute ?? 0, remind: remind)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
