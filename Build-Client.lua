workspace "Cubed-Client"
   configurations { "Debug", "Release", "Dist" }
   startproject "Cubed-Client"

   -- Workspace-wide build options for MSVC
   filter "system:windows"
      architecture "x64"
      buildoptions { "/EHsc", "/Zc:preprocessor", "/Zc:__cplusplus" }

   filter "system:linux"
      architecture "x64"

   -- Build for whatever Mac this is running on. Walnut's own workspace pins the
   -- host architecture here for the same reason: the GameNetworkingSockets
   -- archive and the Homebrew libraries it pulls in are compiled for the host,
   -- so an x64 workspace fails to link them and would need Rosetta to run.
   filter "system:macosx"
      architecture (os.hostarch():lower())

   defines { "IMGUI_DEFINE_MATH_OPERATORS" }

-- Directories
outputdir = "%{cfg.buildcfg}-%{cfg.system}-%{cfg.architecture}"
WalnutNetworkingBinDir = "Walnut/Walnut-Modules/Walnut-Networking/vendor/GameNetworkingSockets/bin/%{cfg.system}/%{cfg.buildcfg}/"

include "Walnut/Build-Walnut-External.lua"

group "App"
    include "Cubed-Common/Build-Cubed-Common.lua"
    include "Cubed-Client/Build-Cubed-Client.lua"
group ""
