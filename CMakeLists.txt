cmake_minimum_required(VERSION 3.16)

set(PLUGIN_NAME uniqueniumOfficialplugin)
set(PLUGIN_VERSION_MAJOR 1)
set(PLUGIN_VERSION_MINOR 0)
set(PLUGIN_VERSION "${PLUGIN_VERSION_MAJOR}.${PLUGIN_VERSION_MINOR}")
set(TARGET ${PLUGIN_NAME}${PLUGIN_VERSION_MAJOR})

set(QML_IMPORT_PATH ${CMAKE_BINARY_DIR}/temp CACHE STRING "" FORCE)

project(${PLUGIN_NAME} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 6.0 REQUIRED COMPONENTS 
    Core Qml Quick DBus Widgets QuickControls2 Core5Compat LabsPlatform Concurrent LinguistTools)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    find_package(XCB REQUIRED)
endif()

qt_standard_project_setup()

set(sources_files "")
set(qml_files "")
set(resource_files "")
set(include_dirs "")

add_compile_definitions(PLUGIN_NAME="${PLUGIN_NAME}")

set(TS_FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/translations/BackendAll_zh_CN.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/translations/BackendAll_en_US.ts
)



#遍历所有Cpp文件
file(GLOB CPP_FILES *.cpp */*.cpp)
foreach (filepath ${CPP_FILES})
    string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/" "" filename ${filepath})
    list(APPEND sources_files ${filename})
    list(APPEND include_dirs ${filepath})
endforeach (filepath)

#遍历所有h文件
file(GLOB H_FILES *.h */*.h)
foreach (filepath ${H_FILES})
    string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/" "" filename ${filepath})
    list(APPEND include_dirs ${filepath})
    list(APPEND sources_files ${filename})
endforeach (filepath)


#遍历所有qml文件（排除build/dist/translations目录）
file(GLOB_RECURSE QML_PATHS *.qml */*.qml qmldir */*.qmldir)
set(qml_filtered "")
set(resource_filtered "")
foreach (filepath ${QML_PATHS})
    string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/" "" filename ${filepath})
    string(FIND "${filename}" "build/" _build_pos)
    string(FIND "${filename}" "dist/" _dist_pos)
    string(FIND "${filename}" "translations/" _trans_pos)
    if (_build_pos EQUAL -1 AND _dist_pos EQUAL -1 AND _trans_pos EQUAL -1)
        if (${filename} MATCHES "qmldir")
            list(APPEND resource_filtered ${filename})
        else ()
            list(APPEND qml_filtered ${filename})
        endif ()
    endif ()
endforeach (filepath)
set(qml_files ${qml_filtered})
set(resource_files ${resource_filtered})

#遍历所有资源文件
set(RES_SUFFIX "")
set(RES_PATHS "")
list(APPEND RES_SUFFIX *.png *.jpg *.svg *.ico *.ttf *.webp *.js *.qm *.qsb)
list(APPEND RES_PATHS media)
set(resource_filtered "")
foreach (respath ${RES_PATHS})
    foreach (filesuffix ${RES_SUFFIX})
        file(GLOB_RECURSE RES_FOUND ${respath}/${filesuffix})
        foreach (filepath ${RES_FOUND})
            string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/" "" filename ${filepath})
            string(FIND "${filename}" "build/" _res_build_pos)
            string(FIND "${filename}" "dist/" _res_dist_pos)
            if (_res_build_pos EQUAL -1 AND _res_dist_pos EQUAL -1)
                list(APPEND resource_filtered ${filename})
            endif ()
        endforeach()
    endforeach ()
endforeach (respath)
set(resource_files ${resource_filtered})
qt_add_library(${PLUGIN_NAME} SHARED)

target_include_directories(${PLUGIN_NAME}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${include_dirs}
)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    find_package(XCB REQUIRED COMPONENTS XCB XKB)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(XCB_KEYSYMS REQUIRED xcb-keysyms)
    target_include_directories(${PLUGIN_NAME} PRIVATE
        ${XCB_INCLUDE_DIRS}
        ${XCB_KEYSYMS_INCLUDE_DIRS}
    )
    target_link_libraries(${PLUGIN_NAME} PRIVATE
        XCB::XCB
        ${XCB_KEYSYMS_LIBRARIES}
    )
endif()

target_link_libraries(${PLUGIN_NAME}
    PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::DBus
    Qt6::Widgets
    PRIVATE
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::GuiPrivate
    Qt6::Core5Compat
    Qt6::LabsPlatform
    Qt6::Concurrent
    # QHotkey::QHotkey
)

qt_add_translations(${PLUGIN_NAME}
    TS_FILES ${TS_FILES}
    SOURCES ${sources_files} ${qml_files}
    RESOURCE_PREFIX "/uniquenium/officialplugin/i18n"
)


# 将QM文件添加到资源文件
# 为每个QM文件设置QT_RESOURCE_ALIAS属性，使用相对路径以便资源系统正确访问
foreach(qm_file ${QM_FILES})
    # 获取文件名（不含路径）
    get_filename_component(qm_filename ${qm_file} NAME)
    # 设置资源别名，使QM文件在资源系统中可通过相对路径访问
    set_source_files_properties(${qm_file} PROPERTIES
        QT_RESOURCE_ALIAS "translations/${qm_filename}"
    )
    list(APPEND ${qm_file})
endforeach()

# 在CMake配置阶段自动运行lupdate，确保TS文件被填充
# 这样在Qt Creator中配置项目时，翻译字符串会自动提取
get_target_property(_lupdate_exe Qt6::lupdate LOCATION)
if(_lupdate_exe)
    # 将相对路径转换为绝对路径
    set(_all_sources "")
    foreach(_file ${sources_files} ${qml_files})
        list(APPEND _all_sources "${CMAKE_CURRENT_SOURCE_DIR}/${_file}")
    endforeach()
    
    # 运行lupdate提取翻译字符串
    execute_process(
        COMMAND ${_lupdate_exe} ${_all_sources} -ts ${TS_FILES}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        RESULT_VARIABLE _lupdate_result
        OUTPUT_VARIABLE _lupdate_output
        ERROR_VARIABLE _lupdate_error
    )
    
    if(_lupdate_result EQUAL 0)
        message(STATUS "lupdate completed successfully.")
    else()
        message(WARNING "lupdate failed with exit code ${_lupdate_result}.\nError: ${_lupdate_error}")
    endif()
else()
    message(WARNING "Qt6::lupdate not found, translation files will not be updated.")
endif()





qt6_add_qml_module(${PLUGIN_NAME}
    URI org.uniquenium.${PLUGIN_NAME}
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/temp/bin"
    VERSION ${PLUGIN_VERSION}
    QML_FILES ${qml_files}
    RESOURCE_PREFIX "/uniquenium/officialplugin" 
    SOURCES ${sources_files}
    RESOURCES plugin-info.json ${resource_files}
    NO_PLUGIN
)

set_target_properties(${PLUGIN_NAME} PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/temp/bin/"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/temp/bin/"
    PREFIX ""
)