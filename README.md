# Martian RTS

A 3D Real-Time Strategy game built with **Godot 4.3+** (Forward+ Renderer). Defend your command center on the harsh surface of Mars, gather resources, manage energy distribution, and survive increasingly difficult waves of alien attacks.

## 🚀 Features

- **Dynamic Economy:** Gather crystals using automated gatherer drones. Upgrade your base to unlock powerful, exponential resource conversion bonuses (+50% yield per base level).
- **Energy Management:** Distribute energy carefully between gathering, base defense, and unit production. If energy is cut off, drones will automatically power down and return to base.
- **Wave-Based Survival:** Defend against infinite, procedurally scaling waves of alien mobs (e.g., Catalysts). Enemy strength and numbers increase with each wave.
- **Drone Swarm Logistics:** Complex drone AI with autonomous state machines. Drones handle resource harvesting, pathfinding, and returning to base to unload, featuring anti-stuck physics logic.
- **Base Repair System:** Use accumulated credits to trigger a global heal for all your buildings and units during the calm moments between waves.
- **Responsive UI:** Fully dynamic interface that scales cleanly across any resolution, featuring a production queue, interactive minimap components, and context-sensitive alerts.

## 🕹️ Controls

- **Left Click**: Select buildings, interact with UI, and distribute energy.
- **Mouse Movement**: Navigate the UI and pan the camera.
- **Cheat Code**: Feeling overwhelmed? Type `NNNHHH` on your keyboard at any time to instantly receive +10,000 credits!

## 🛠️ Technology Stack

- **Engine:** Godot 4 (S3TC, BPTC texture compression)
- **Physics:** Jolt Physics 3D
- **Language:** GDScript

## 📦 How to Build / Export

1. Open the project in the **Godot 4** editor.
2. Go to **Project -> Export**.
3. Select **Windows Desktop**.
4. Make sure **Embed PCK** is checked in the *Binary Format* section.
5. Uncheck *Export With Debug* for maximum performance.
6. Click **Export Project** and save the `.exe` file.

## 🤝 Contributing

This project is a complete playable slice of an RTS. Feel free to fork the repository, experiment with the Drone AI state machines (`drone_base.gd`, `drone_gatherer.gd`), or add new alien types to the `WaveManager`.

## 📄 License

This project is open-source and available for educational purposes and further development.
