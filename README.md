
# 🚨 Exter Dispatch System
**NoPixel 4.0-style Emergency Dispatch UI for QBCore**

## 📦 Features
- Modern UI for **Recent Alerts** and **Active Calls** inspired by NoPixel 4.0.
- Tab navigation: `Overview`, `Units`, and `Officers`.
- Supports emergency jobs: **LSPD (police)** and **LSMD (ambulance)**.
- Can be opened via **command** or **keybind**.

## 🧰 Installation

1. **Download and extract** this resource into your `resources/[your_resources]/exter-dispatch` folder.
2. Add the following line to your `server.cfg`:
   ```
   ensure exter-dispatch
   ```

## ⚙️ Configuration

### `config.lua`
```lua
Config = {}

Config.EmergencyJobs = {
    {
        name = "police",
        displayname = "LSPD",
    },
    {
        name = "ambulance",
        displayname = "LSMD",
    }
}

-- Command to open the dispatch UI
Config.MenuCommand = "openDispatchMenu"

-- Keyboard shortcut to open the menu (used with `RegisterKeyMapping`)
Config.MenuKey = "INSERT"
```

## 🕹️ Command & Keybind

- Use the command:
  ```
  /openDispatchMenu
  ```

- Or press the `INSERT` key if registered using `RegisterKeyMapping`.

## 🧑‍✈️ Who Can Access?
Only players with jobs listed in `Config.EmergencyJobs` (e.g., `police`, `ambulance`) can access the dispatch menu.

## 🧪 Compatibility
- Framework: **QBCore**
- UI Design: **Inspired by NoPixel 4.0**

## 📸 Preview
![noo](https://github.com/user-attachments/assets/12a2b774-a1e0-41f4-aba8-952da676d133)


https://github.com/user-attachments/assets/55c6dd6b-0ee4-4b4c-bfa9-ddb84d7213d5


