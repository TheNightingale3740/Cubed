project "Cubed-Client"
   kind "ConsoleApp"
   language "C++"
   cppdialect "C++20"
   targetdir "bin/%{cfg.buildcfg}"

   files { "Source/**.h", "Source/**.cpp" }

   includedirs
   {
      "../Cubed-Common/Source",

      "../Walnut/vendor/imgui",
      "../Walnut/vendor/glfw/include",
      "../Walnut/vendor/glm",
      "../Walnut/vendor/spdlog/include",
      
      "../Walnut/Walnut/Source",
      "../Walnut/Walnut/Platform/GUI",

      "%{IncludeDir.VulkanSDK}",

      -- Walnut-Networking
      "../Walnut/Walnut-Modules/Walnut-Networking/Source",
      "../Walnut/Walnut-Modules/Walnut-Networking/vendor/GameNetworkingSockets/include"
   }

    links
    {
        "Cubed-Common",
        "Walnut",

        -- Walnut::Client/Server live here, and neither premake's gmake nor its
        -- VS action propagates a static library's own links to the projects that
        -- depend on it, so the module has to be named explicitly.
        "Walnut-Networking"
    }

   targetdir ("../bin/" .. outputdir .. "/%{prj.name}")
   objdir ("../bin-int/" .. outputdir .. "/%{prj.name}")

   buildoptions (FmtConstevalWorkaround)

   filter "system:windows"
      staticruntime "off"
      systemversion "latest"
      defines { "WL_PLATFORM_WINDOWS" }
      buildoptions { "/utf-8" }

      -- The module's own dependencies are not inherited either.
      links { "Ws2_32.lib" }

      postbuildcommands 
      {
        '{COPY} "../%{WalnutNetworkingBinDir}/GameNetworkingSockets.dll" "%{cfg.targetdir}"',
        '{COPY} "../%{WalnutNetworkingBinDir}/libcrypto-3-x64.dll" "%{cfg.targetdir}"',
        '{COPY} "../%{WalnutNetworkingBinDir}/libprotobufd.dll" "%{cfg.targetdir}"',
      }

   filter { "system:windows", "configurations:Debug" }
      links { "../%{WalnutNetworkingBinDir}/GameNetworkingSockets.lib" }

   filter { "system:windows", "configurations:Release or configurations:Dist" }
      -- There is no Dist build of the prebuilt binaries, so Dist ships the
      -- Release ones.
      links { "../Walnut/Walnut-Modules/Walnut-Networking/vendor/GameNetworkingSockets/bin/Windows/Release/GameNetworkingSockets.lib" }

   filter "system:macosx"
      defines { "WL_PLATFORM_MACOS" }

      -- gmake does not propagate a static library's links, so everything
      -- Walnut depends on has to be named again here.
      links (CoreLibraries)

      -- ...and the same goes for the optional Walnut-Networking module.
      libdirs (MacOSNetworkLibDirs)
      links { "GameNetworkingSockets_s" }
      links (MacOSNetworkLibraries)

      linkoptions (CoreLinkOptions)
      linkoptions (MacOSFrameworkLinkOptions)
      linkoptions { "-Wl,-rpath," .. VulkanPrefixMac .. "/lib" }
      linkoptions (MacOSNetworkLinkOptions)

   filter "configurations:Debug"
      defines { "WL_DEBUG" }
      runtime "Debug"
      symbols "On"

   filter "configurations:Release"
      defines { "WL_RELEASE" }
      runtime "Release"
      optimize "On"
      symbols "On"

   filter "configurations:Dist"
      kind "WindowedApp"
      defines { "WL_DIST" }
      runtime "Release"
      optimize "On"
      symbols "Off"