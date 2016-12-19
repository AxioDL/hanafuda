# Hanafuda toolchain
set(CMAKE_SYSTEM_NAME Hanafuda)

# Set toolchain programs
set(CMAKE_C_COMPILER hanafuda)
set(CMAKE_CXX_COMPILER hanafuda++)
set(CMAKE_C_LINK_EXECUTABLE ${CMAKE_C_COMPILER})
set(CMAKE_CXX_LINK_EXECUTABLE ${CMAKE_CXX_COMPILER})

# Set triple for CMake's identification
set(triple powerpc-unknown-hanafuda-eabi)
set(CMAKE_C_COMPILER_TARGET ${triple})
set(CMAKE_CXX_COMPILER_TARGET ${triple})

# Skip test compile (hanafuda has a somewhat unorthodox compiler workflow)
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_FORCED TRUE)

# Compile a C file into an object file
set(CMAKE_C_COMPILE_OBJECT "<CMAKE_C_COMPILER> -c <INCLUDES> <FLAGS> -o <OBJECT> <SOURCE>")
set(CMAKE_CXX_COMPILE_OBJECT "<CMAKE_CXX_COMPILER> -c <INCLUDES> <FLAGS> -o <OBJECT> <SOURCE>")

# Link object files to an executable
set(CMAKE_C_LINK_EXECUTABLE "<CMAKE_C_COMPILER> <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> <LINK_LIBRARIES> -o <TARGET> <OBJECTS>")
set(CMAKE_CXX_LINK_EXECUTABLE "<CMAKE_CXX_COMPILER> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <LINK_LIBRARIES> -o <TARGET> <OBJECTS>")

# Thing that doesn't work
set(CMAKE_C_OUTPUT_EXTENSION ".o")
set(CMAKE_CXX_OUTPUT_EXTENSION ".o")

# Macro to get the required link arguments in place
macro(add_hanafuda_executable name base_dol list_file)
  add_executable(${name} ${ARGN})
  set_target_properties(${name} PROPERTIES LINK_FLAGS
	"--hanafuda-base-dol=${CMAKE_SOURCE_DIR}/${base_dol} \
	--hanafuda-dol-symbol-list=${CMAKE_SOURCE_DIR}/${list_file}"
	SUFFIX ".dol")
endmacro()
