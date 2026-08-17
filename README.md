# OfficialPlugin

official plugin pack for Uniquenium

## Components in Official Plugin

- [x] Typing Follower
- [x] Twikoo Comments
- [x] Todo List
- [ ] System Sound Visualizer
- [ ] Line Chart By Time

## Build Prerequisites

### Visual Studio Path Configuration

vcpkg requires the `VCPKG_VISUAL_STUDIO_PATH` environment variable to locate your Visual Studio installation. If your VS is installed in a non-default location (e.g. not on `C:\`), you **must** set this variable:

**Option 1 - System Environment Variable (Recommended):**
```powershell
# Replace with your actual VS Community installation path
[System.Environment]::SetEnvironmentVariable("VCPKG_VISUAL_STUDIO_PATH", "C:\Program Files\Microsoft Visual Studio\2022\Community", "User")
```

**Option 2 - Temporary (current session only):**
```powershell
$env:VCPKG_VISUAL_STUDIO_PATH = "C:\Program Files\Microsoft Visual Studio\2022\Community"
```

After setting, reconfigure the project in Qt Creator.

### MongoDB C++ Driver

This plugin uses the MongoDB C++ Driver (`mongo-cxx-driver`) via vcpkg. Ensure vcpkg is properly installed and the manifest in `vcpkg.json` references the correct dependencies. The driver will be automatically fetched and installed during CMake configuration if not already present.