workspace "Cubed-Server"
   configurations { "Debug", "Release", "Dist" }
   startproject "Cubed-Server"

   -- Workspace-wide defines
   defines
   {
        "WL_HEADLESS"
   }

   -- Workspace-wide build options for MSVC
   filter "system:windows"
      architecture "x64"
      buildoptions { "/EHsc", "/Zc:preprocessor", "/Zc:__cplusplus" }

   filter "system:linux"
      architecture "x64"

   -- See the note in Build-Client.lua: the host architecture is what the
   -- prebuilt native dependencies are compiled for.
   filter "system:macosx"
      architecture (os.hostarch():lower())

-- Directories
outputdir = "%{cfg.buildcfg}-%{cfg.system}-%{cfg.architecture}"
WalnutNetworkingBinDir = "Walnut/Walnut-Modules/Walnut-Networking/vendor/GameNetworkingSockets/bin/%{cfg.system}/%{cfg.buildcfg}/"

include "Walnut/Build-Walnut-Headless-External.lua"

group "App"
    include "Cubed-Common/Build-Cubed-Common-Headless.lua"
    include "Cubed-Server/Build-Cubed-Server-Headless.lua"
group ""
