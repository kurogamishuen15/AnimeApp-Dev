# Keep queued software-render callbacks alive through VideoOutput teardown.
# media_kit_video 2.0.1 passes an unowned pointer to its GTK idle callback.
# Generate the patched translation unit in the build tree, preserving the
# dependency cache and all other rendering code.
if(TARGET media_kit_video_plugin)
  get_target_property(KONGROO_VIDEO_SOURCE_DIR media_kit_video_plugin SOURCE_DIR)
  set(KONGROO_VIDEO_SOURCE "${KONGROO_VIDEO_SOURCE_DIR}/video_output.cc")
  if(EXISTS "${KONGROO_VIDEO_SOURCE}")
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${KONGROO_VIDEO_SOURCE}")
    file(READ "${KONGROO_VIDEO_SOURCE}" KONGROO_VIDEO_CODE)
    string(REGEX MATCHALL "gdk_threads_add_idle\\(" KONGROO_IDLE_CALLS "${KONGROO_VIDEO_CODE}")
    list(LENGTH KONGROO_IDLE_CALLS KONGROO_IDLE_COUNT)
    string(REGEX MATCHALL "                  data\\)" KONGROO_IDLE_ENDS "${KONGROO_VIDEO_CODE}")
    list(LENGTH KONGROO_IDLE_ENDS KONGROO_IDLE_END_COUNT)
    if(NOT KONGROO_IDLE_COUNT EQUAL 1 OR NOT KONGROO_IDLE_END_COUNT EQUAL 1)
      message(FATAL_ERROR "Review the media_kit_video GTK lifetime patch for this dependency version.")
    endif()
    string(REPLACE "gdk_threads_add_idle("
      "gdk_threads_add_idle_full(\n                  G_PRIORITY_DEFAULT_IDLE,"
      KONGROO_VIDEO_CODE "${KONGROO_VIDEO_CODE}")
    string(REPLACE "                  data);"
      "                  g_object_ref(data),\n                  g_object_unref);"
      KONGROO_VIDEO_CODE "${KONGROO_VIDEO_CODE}")
    set(KONGROO_PATCHED_VIDEO "${CMAKE_CURRENT_BINARY_DIR}/kongroo_video_output.cc")
    set(KONGROO_PREVIOUS_VIDEO_CODE "")
    if(EXISTS "${KONGROO_PATCHED_VIDEO}")
      file(READ "${KONGROO_PATCHED_VIDEO}" KONGROO_PREVIOUS_VIDEO_CODE)
    endif()
    if(NOT KONGROO_PREVIOUS_VIDEO_CODE STREQUAL KONGROO_VIDEO_CODE)
      file(WRITE "${KONGROO_PATCHED_VIDEO}" "${KONGROO_VIDEO_CODE}")
    endif()
    get_target_property(KONGROO_VIDEO_SOURCES media_kit_video_plugin SOURCES)
    list(FILTER KONGROO_VIDEO_SOURCES EXCLUDE REGEX "(^|/)video_output\\.cc$")
    set_property(TARGET media_kit_video_plugin PROPERTY SOURCES "${KONGROO_VIDEO_SOURCES}")
    target_sources(media_kit_video_plugin PRIVATE "${KONGROO_PATCHED_VIDEO}")
    target_include_directories(media_kit_video_plugin PRIVATE "${KONGROO_VIDEO_SOURCE_DIR}")
  endif()
endif()
