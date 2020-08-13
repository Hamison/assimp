--Premake5 version of the CMAKE build system

--Define project version here
PROJECT_VERSION_MAJOR = 5
PROJECT_VERSION_MINOR = 0
PROJECT_VERSION_PATCH = 1

PROJECT_VERSION = tostring(PROJECT_VERSION_MAJOR) .. "." ..
    tostring(PROJECT_VERSION_MINOR) .. "." ..
    tostring(PROJECT_VERSION_PATCH)

--Execite process is used to perform a command line process (as per cmake)
function execute_process(cmd)
    -- Get a temporary file name
    local n = os.tmpname ()

    -- Execute a command and send to file
    os.execute (cmd .. " > " .. n)
    
    -- Concatenate output
    local str = ""
    for line in io.lines (n) do
        str = str .. line
    end

    -- Remove temporary file
    os.remove (n)
    
    return str
end

-- Check if string is empty or not
local function isempty(s)
  return s == nil or s == ''
end

-- Configures a file using the input file and replace with options
function configure_file(filename_in, filename_out, configurables)
 --
 --  Read the file
 --
 local f = io.open(filename_in, "r")
 local content = f:read("*all")
 f:close()
 
 --
 -- Edit the string using the configurables table
 --
 for key,value in pairs(configurables) do 
    content = content:gsub('@' .. key .. '@', value)
    
    if value == nil or value == '' then
        output_str = '/* #undef ' .. key .. ' */'
    else
        output_str = '#define ' .. key .. ' ' .. value
    end
    
    content = content:gsub('#cmakedefine ' .. key .. ' %S+', output_str)
 end
 
 --
 -- Write it out
 --
 local f = io.open(filename_out, "w")
 f:write(content)
 f:close()
 
end

-- Configuration options
configurables = {}
configurables["ASSIMP_VERSION_MAJOR"] = PROJECT_VERSION_MAJOR
configurables["ASSIMP_VERSION_MINOR"] = PROJECT_VERSION_MINOR
configurables["ASSIMP_VERSION_PATCH"] = PROJECT_VERSION_PATCH
configurables["ASSIMP_VERSION"] = PROJECT_VERSION
configurables["ASSIMP_SOVERSION"] = 5
configurables["ASSIMP_PACKAGE_VERSION"] = "0"

configurables["LIBASSIMP_COMPONENT"] = "libassimp" .. PROJECT_VERSION
configurables["LIBASSIMP-DEV_COMPONENT"] = "libassimp" .. PROJECT_VERSION .. "-dev"

configurables["ASSIMP_LIBRARY_SUFFIX"] = ""
configurables["LIBRARY_SUFFIX"] = ""
configurables["CMAKE_DEBUG_POSTFIX"] = "" --should set to "d" if debug
configurables["GIT_BRANCH"] = execute_process('"git rev-parse --abbrev-ref HEAD"')
configurables["GIT_COMMIT_HASH"] = execute_process("git rev-parse --short=8 HEAD")
configurables["ASSIMP_DOUBLE_PRECISION"] = ""

if isempty(configurables["GIT_COMMIT_HASH"]) then
  configurables["GIT_COMMIT_HASH"] = "0"
end

-- Configure file
configure_file("revision.h.in", "revision.h", configurables)
configure_file("include/assimp/config.h.in", "include/assimp/config.h",
    configurables)
configure_file("contrib/zlib/zconf.h.in", "contrib/zlib/zconf.h",
    configurables)

project "assimp"
	kind "StaticLib"
	language "C++"

	targetdir ("bin/" .. outputdir .. "/%{prj.name}")
	objdir ("bin-int/" .. outputdir .. "/%{prj.name}")
	
	defines
  {
    "ASSIMP_BUILD_NO_C4D_IMPORTER",
    "OPENDDL_STATIC_LIBARY"
	}

	filter "system:windows"
		systemversion "latest"
		staticruntime "On"
    cppdialect "C++11"

    buildoptions
    {
      "/bigobj"
    }

    defines
    {
      "_CRT_SECURE_NO_WARNINGS",
      "_CRT_SECURE_NO_DEPRECATE",
      "WIN32_LEAN_AND_MEAN"
    }

    disablewarnings {
      "4244",
      "4305",
      "4996"
    }
    
    includedirs
    {
      ".",
      "code",
      "include",
      "contrib/*",
      "code/AssetLib/*",
      "code/CApi",
      "code/Common",
      "code/Material",
      "code/PostProcessing",
      "contrib/clipper",
      "contrib/irrXML",
      "contrib/Open3DGC",
      "contrib/openddlparser/include",
      "contrib/poly2tri/poly2tri",
      "contrib/poly2tri/poly2tri/common",
      "contrib/poly2tri/poly2tri/sweep",
      "contrib/rapidjson/include",
      "contrib/stb_image",
      "contrib/unzip",
      "contrib/utf8cpp/source",
      "contrib/utf8cpp/source/utf8",
      "contrib/zip/src",
      "contrib/zlib"
    }

    files {
      "include/**.h",
      "include/**.hpp",
      "include/**.cpp",
      "include/**.inl",
      "code/AssetLib/**.h",
      "code/AssetLib/**.c",
      "code/AssetLib/**.hpp",
      "code/AssetLib/**.cpp",
      "code/CApi/*.h",
      "code/CApi/*.hpp",
      "code/CApi/*.cpp",
      "code/Common/**.h",
      "code/Common/**.hpp",
      "code/Common/**.cpp",
      "code/Material/MaterialSystem.h",
      "code/Material/MaterialSystem.cpp",
      "code/PostProcessing/*.h",
      "code/PostProcessing/*.hpp",
      "code/PostProcessing/*.cpp",
      "contrib/**.h",
      "contrib/**.hpp",
      "contrib/**.cpp",
      "contrib/**.c",
      "contrib/**.cc"
    }

    removefiles
    {
      "code/AssetLib/IFC/IFCReaderGen_4.h",
      "code/AssetLib/IFC/IFCReaderGen_4.cpp",
      "contrib/gtest/**",
      "contrib/zip/test/**",
      "contrib/zlib/**"
    }
    
    links
    {
        "zlib"
    }

    filter "configurations:Debug"
        runtime "Debug"
        symbols "on"

    filter "configurations:Release"
        runtime "Release"
        optimize "on"    
    
project "zlib"
    kind "StaticLib"
    language "C"

	targetdir ("bin/" .. outputdir .. "/%{prj.name}")
	objdir ("bin-int/" .. outputdir .. "/%{prj.name}")

	warnings    "off"

	files
	{
		"contrib/zlib/*.h",
		"contrib/zlib/*.c"
	}

	filter "system:windows"
  	systemversion "latest"
		staticruntime "On"
		defines { "_WINDOWS" }

	filter "system:not windows"
		defines { 'HAVE_UNISTD_H' }