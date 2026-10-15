project "Cubed-Server"
   kind "ConsoleApp"
   language "C++"
   cppdialect "C++20"
   targetdir "bin/%{cfg.buildcfg}"

   files { "Source/**.h", "Source/**.cpp" }

   includedirs
   {
      "../Cubed-Common/Source",

      "../Walnut/vendor/glm",

      "../Walnut/Walnut/Source",
      "../Walnut/Walnut/Platform/Headless",

      "../Walnut/vendor/spdlog/include",
      "../Walnut/vendor/yaml-cpp/include",

      -- Walnut-Networking
      "../Walnut/Walnut-Modules/Walnut-Networking/Source",
      "../Walnut/Walnut-Modules/Walnut-Networking/vendor/GameNetworkingSockets/include"
   }

   links
   {
       "Cubed-Common-Headless",
       "Walnut-Headless",
       "Walnut-Networking",

       "yaml-cpp",
   }

   -- gmake does not propagate a static library's links.
   links (HeadlessLibraries)

   	defines
	{
		"YAML_CPP_STATIC_DEFINE"
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

   filter "system:linux"
      libdirs { "../Walnut/Walnut-Modules/Walnut-Networking/vendor/GameNetworkingSockets/bin/Linux" }
      links { "GameNetworkingSockets" }

      defines { "WL_HEADLESS" }

   filter "system:macosx"
      defines { "WL_PLATFORM_MACOS" }
      defines { "WL_HEADLESS" }

      -- There is no upstream macOS binary for GameNetworkingSockets; the archive
      -- in MacOS/ is built from source for the host architecture.
      libdirs (MacOSNetworkLibDirs)
      links { "GameNetworkingSockets_s" }
      links (MacOSNetworkLibraries)

      -- No GUI here, so none of the Cocoa/Metal/GLFW frameworks are needed;
      -- GameNetworkingSockets pulls in Security and CoreServices.
      linkoptions (MacOSHeadlessFrameworkLinkOptions)
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
      defines { "WL_DIST" }
      runtime "Release"
      optimize "On"
      symbols "Off"