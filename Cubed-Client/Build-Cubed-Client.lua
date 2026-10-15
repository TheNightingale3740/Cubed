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
        "Walnut"
    }

   targetdir ("../bin/" .. outputdir .. "/%{prj.name}")
   objdir ("../bin-int/" .. outputdir .. "/%{prj.name}")

   buildoptions (FmtConstevalWorkaround)

   filter "system:windows"
      staticruntime "off"
      systemversion "latest"
      defines { "WL_PLATFORM_WINDOWS" }
      buildoptions { "/utf-8" }

      postbuildcommands 
      {
        '{COPY} "../%{WalnutNetworkingBinDir}/GameNetworkingSockets.dll" "%{cfg.targetdir}"',
        '{COPY} "../%{WalnutNetworkingBinDir}/libcrypto-3-x64.dll" "%{cfg.targetdir}"',
        '{COPY} "../%{WalnutNetworkingBinDir}/libprotobufd.dll" "%{cfg.targetdir}"',
      }

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