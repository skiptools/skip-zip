cmake_minimum_required(VERSION 3.1)
project(cproject, LANGUAGES C)
file(GLOB SOURCES src/*.c)

find_package(ZLIB REQUIRED)

add_library(minizip SHARED ${SOURCES})
add_compile_definitions(ZLIB_COMPAT HAVE_ZLIB MZ_ZIP_NO_CRYPTO)
include_directories(minizip PUBLIC include)
target_link_libraries(minizip PRIVATE ZLIB::ZLIB)
