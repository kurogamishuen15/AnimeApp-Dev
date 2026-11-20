# Configuración por plataforma

Directorios presentes: linux. Android/Windows no tienen scaffold en este árbol.
No inventar permisos ni configuraciones ausentes.

## app/linux/CMakeLists.txt

```
# Project-level configuration.
cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "anime_app")
# The unique GTK application identifier for this application. See:
# https://wiki.gnome.org/HowDoI/ChooseApplicationID
set(APPLICATION_ID "app.anime.anime_app")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(SET CMP0063 NEW)

# Load bundled libraries from the lib/ directory relative to the binary.
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Root filesystem for cross-building.
if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endif()

# Define build configuration options.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE
    STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Profile" "Release")
endif()

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_14)
  target_compile_options(${TARGET} PRIVATE -Wall -Werror)
  target_compile_options(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
  target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# System-level dependencies.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# Only the install-generated bundle's copy of the executable will launch
# correctly, since the resources must in the right relative locations. To avoid
# people trying to run the unbundled copy, put it in a subdirectory instead of
# the default top-level location.
set_target_properties(${BINARY_NAME}
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/intermediates_do_not_run"
)


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)
include(media_kit_video_lifetime.cmake)


# === Installation ===
# By default, "installing" just makes a relocatable bundle in the build
# directory.
set(BUILD_BUNDLE_DIR "${PROJECT_BINARY_DIR}/bundle")
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

# Start with a clean build bundle directory every time.
install(CODE "
  file(REMOVE_RECURSE \"${BUILD_BUNDLE_DIR}/\")
  " COMPONENT Runtime)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib")

# Optional H.264 decoder for the local bundle; see local_codec.cmake.
include(local_codec.cmake)

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endforeach(bundled_library)

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/linux/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
if(NOT CMAKE_BUILD_TYPE MATCHES "Debug")
  install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

```

## app/linux/flutter/CMakeLists.txt

```
# This file controls Flutter-level build steps. It should not be edited.
cmake_minimum_required(VERSION 3.10)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided via flutter tool.
include(${EPHEMERAL_DIR}/generated_config.cmake)

# TODO: Move the rest of this into files in ephemeral. See
# https://github.com/flutter/flutter/issues/57146.

# Serves the same purpose as list(TRANSFORM ... PREPEND ...),
# which isn't available in 3.10.
function(list_prepend LIST_NAME PREFIX)
    set(NEW_LIST "")
    foreach(element ${${LIST_NAME}})
        list(APPEND NEW_LIST "${PREFIX}${element}")
    endforeach(element)
    set(${LIST_NAME} "${NEW_LIST}" PARENT_SCOPE)
endfunction()

# === Flutter Library ===
# System-level dependencies.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)
pkg_check_modules(GLIB REQUIRED IMPORTED_TARGET glib-2.0)
pkg_check_modules(GIO REQUIRED IMPORTED_TARGET gio-2.0)

set(FLUTTER_LIBRARY "${EPHEMERAL_DIR}/libflutter_linux_gtk.so")

# Published to parent scope for install step.
set(FLUTTER_LIBRARY ${FLUTTER_LIBRARY} PARENT_SCOPE)
set(FLUTTER_ICU_DATA_FILE "${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)
set(PROJECT_BUILD_DIR "${PROJECT_DIR}/build/" PARENT_SCOPE)
set(AOT_LIBRARY "${PROJECT_DIR}/build/lib/libapp.so" PARENT_SCOPE)

list(APPEND FLUTTER_LIBRARY_HEADERS
  "fl_basic_message_channel.h"
  "fl_binary_codec.h"
  "fl_binary_messenger.h"
  "fl_dart_project.h"
  "fl_engine.h"
  "fl_json_message_codec.h"
  "fl_json_method_codec.h"
  "fl_message_codec.h"
  "fl_method_call.h"
  "fl_method_channel.h"
  "fl_method_codec.h"
  "fl_method_response.h"
  "fl_plugin_registrar.h"
  "fl_plugin_registry.h"
  "fl_standard_message_codec.h"
  "fl_standard_method_codec.h"
  "fl_string_codec.h"
  "fl_value.h"
  "fl_view.h"
  "flutter_linux.h"
)
list_prepend(FLUTTER_LIBRARY_HEADERS "${EPHEMERAL_DIR}/flutter_linux/")
add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE
  "${EPHEMERAL_DIR}"
)
target_link_libraries(flutter INTERFACE "${FLUTTER_LIBRARY}")
target_link_libraries(flutter INTERFACE
  PkgConfig::GTK
  PkgConfig::GLIB
  PkgConfig::GIO
)
add_dependencies(flutter flutter_assemble)

# === Flutter tool backend ===
# _phony_ is a non-existent file to force this command to run every time,
# since currently there's no way to get a full input/output list from the
# flutter tool.
add_custom_command(
  OUTPUT ${FLUTTER_LIBRARY} ${FLUTTER_LIBRARY_HEADERS}
    ${CMAKE_CURRENT_BINARY_DIR}/_phony_
  COMMAND ${CMAKE_COMMAND} -E env
    ${FLUTTER_TOOL_ENVIRONMENT}
    "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.sh"
      ${FLUTTER_TARGET_PLATFORM} ${CMAKE_BUILD_TYPE}
  VERBATIM
)
add_custom_target(flutter_assemble DEPENDS
  "${FLUTTER_LIBRARY}"
  ${FLUTTER_LIBRARY_HEADERS}
)

```

## app/linux/flutter/generated_plugin_registrant.cc

```
//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_secure_storage_linux/flutter_secure_storage_linux_plugin.h>
#include <media_kit_libs_linux/media_kit_libs_linux_plugin.h>
#include <media_kit_video/media_kit_video_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) flutter_secure_storage_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterSecureStorageLinuxPlugin");
  flutter_secure_storage_linux_plugin_register_with_registrar(flutter_secure_storage_linux_registrar);
  g_autoptr(FlPluginRegistrar) media_kit_libs_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "MediaKitLibsLinuxPlugin");
  media_kit_libs_linux_plugin_register_with_registrar(media_kit_libs_linux_registrar);
  g_autoptr(FlPluginRegistrar) media_kit_video_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "MediaKitVideoPlugin");
  media_kit_video_plugin_register_with_registrar(media_kit_video_registrar);
}

```

## app/linux/flutter/generated_plugin_registrant.h

```
//
//  Generated file. Do not edit.
//

// clang-format off

#ifndef GENERATED_PLUGIN_REGISTRANT_
#define GENERATED_PLUGIN_REGISTRANT_

#include <flutter_linux/flutter_linux.h>

// Registers Flutter plugins.
void fl_register_plugins(FlPluginRegistry* registry);

#endif  // GENERATED_PLUGIN_REGISTRANT_

```

## app/linux/flutter/generated_plugins.cmake

```
#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
  flutter_secure_storage_linux
  media_kit_libs_linux
  media_kit_video
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
  jni
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/linux plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/linux plugins/${ffi_plugin})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)

```

## app/linux/local_codec.cmake

```
# Optional H.264 decoder for the local Linux bundle.
#
# Fedora's libavcodec declares `libopenh264.so.8` as DT_NEEDED and the distro
# ships `noopenh264`: an ABI-compatible stub without an H.264 decoder. Without
# the official Cisco build, libmpv opens the media, reads its duration and then
# fails to decode every H.264 frame.
#
# When the verified binary prepared by
# `tools/player/run_kongroo_linux.sh --download-codec` exists, this module
# copies it into the bundle and gives the runner a transitive DT_RPATH. That
# works because libavcodec is dlopened through libmpv: a non-transitive
# DT_RUNPATH would not be consulted for its dependencies, while DT_RPATH is
# searched across the whole loader chain.
#
# The project never commits or redistributes the binary: only the install step
# copies the user's local artifact, together with its licence text. Removing the
# artifact (or configuring with -DKONGROO_BUNDLE_OPENH264=OFF) restores the
# system codec policy with no other change.

set(KONGROO_PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../..")
set(KONGROO_OPENH264_DIR
  "${KONGROO_PROJECT_ROOT}/.ai-local/native-codecs/openh264-2.6.0")
set(KONGROO_OPENH264_SOURCE "${KONGROO_OPENH264_DIR}/libopenh264.so.8")
set(KONGROO_OPENH264_LICENSE "${KONGROO_OPENH264_DIR}/BINARY_LICENSE.txt")
# SHA-256 verified by the launcher when it downloads the official build.
set(KONGROO_OPENH264_SHA256
  "2f0cde7c6a6abcf5cae76942894ea42897fa677bce4ed6c91a24dd1b041d5f04")

option(KONGROO_BUNDLE_OPENH264
  "Bundle the project-local Cisco OpenH264 decoder when it is available" ON)

if(IS_SYMLINK "${KONGROO_OPENH264_DIR}"
    OR IS_SYMLINK "${KONGROO_OPENH264_SOURCE}"
    OR IS_SYMLINK "${KONGROO_OPENH264_LICENSE}")
  message(FATAL_ERROR
    "Refusing symlinked OpenH264 artifacts or license: ${KONGROO_OPENH264_DIR}")
endif()

# Reconfigure when the optional artifact appears or disappears.
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
  "${KONGROO_OPENH264_SOURCE}"
  "${KONGROO_OPENH264_LICENSE}")

set(KONGROO_OPENH264_BUNDLED FALSE)
if(KONGROO_BUNDLE_OPENH264 AND EXISTS "${KONGROO_OPENH264_SOURCE}")
  file(SHA256 "${KONGROO_OPENH264_SOURCE}" KONGROO_OPENH264_ACTUAL)
  if(NOT KONGROO_OPENH264_ACTUAL STREQUAL KONGROO_OPENH264_SHA256)
    message(FATAL_ERROR
      "OpenH264 checksum mismatch, refusing to bundle ${KONGROO_OPENH264_SOURCE}")
  endif()
  if(NOT EXISTS "${KONGROO_OPENH264_LICENSE}")
    message(FATAL_ERROR
      "OpenH264 binary license missing; refusing to bundle ${KONGROO_OPENH264_SOURCE}")
  endif()
  set(KONGROO_OPENH264_BUNDLED TRUE)
  message(STATUS
    "Kongroo: bundling the local OpenH264 decoder for H.264 playback")
else()
  message(STATUS
    "Kongroo: no local OpenH264 decoder; using the system codec policy")
endif()

if(KONGROO_OPENH264_BUNDLED)
  target_link_options(${BINARY_NAME} PRIVATE "LINKER:--disable-new-dtags")
  install(FILES "${KONGROO_OPENH264_SOURCE}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
  install(FILES "${KONGROO_OPENH264_LICENSE}"
    DESTINATION "${INSTALL_BUNDLE_DATA_DIR}/licenses"
    COMPONENT Runtime)
endif()

```

## app/linux/media_kit_video_lifetime.cmake

```
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

```

## app/linux/runner/CMakeLists.txt

```
cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the application ID.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

```

## app/linux/runner/main.cc

```
#include "my_application.h"

int main(int argc, char** argv) {
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}

```

## app/linux/runner/my_application.cc

```
#include "my_application.h"

#include <cstring>

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  GtkWindow* player_window;
  FlMethodChannel* player_window_channel;
  FlMethodChannel* player_fullscreen_channel;
  gboolean player_close_guard_enabled;
  gboolean player_close_request_pending;
  gboolean player_close_channel_request_pending;
  guint player_close_generation;
  guint player_close_timeout_source;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

struct PlayerCloseRequest {
  MyApplication* application;
  guint generation;
};

static constexpr char kPlayerApplicationWeakRefKey[] =
    "kongroo-f2-2-player-application-weak-ref";

static PlayerCloseRequest* player_close_request_new(MyApplication* self,
                                                    guint generation) {
  auto* request = g_new0(PlayerCloseRequest, 1);
  request->application = MY_APPLICATION(g_object_ref(self));
  request->generation = generation;
  return request;
}

static void player_close_request_free(gpointer data) {
  auto* request = static_cast<PlayerCloseRequest*>(data);
  g_object_unref(request->application);
  g_free(request);
}

static void player_application_weak_ref_free(gpointer data) {
  auto* application_weak_ref = static_cast<GWeakRef*>(data);
  g_weak_ref_clear(application_weak_ref);
  g_free(application_weak_ref);
}

static gboolean player_close_timeout_cb(gpointer user_data) {
  auto* request = static_cast<PlayerCloseRequest*>(user_data);
  MyApplication* self = request->application;
  if (request->generation == self->player_close_generation &&
      self->player_close_request_pending) {
    self->player_close_timeout_source = 0;
    self->player_close_request_pending = FALSE;
    // Invalidate any later MethodChannel response. This watchdog cannot cancel
    // an unresolved invocation; keep its channel-pending guard set so another
    // GTK gesture cannot start concurrent cleanup. A later close gesture can
    // retry only after the outstanding callback returns.
    // This timeout never cancels Dart cleanup or a native player operation.
    // GLib dispatches this on the GTK main loop, so it is a best-effort
    // watchdog while that loop remains responsive.
    self->player_close_generation++;
    g_warning("F2.2 close response timed out; window remains open");
  }
  return G_SOURCE_REMOVE;
}

static void player_close_response_cb(GObject* source_object,
                                     GAsyncResult* result,
                                     gpointer user_data) {
  const guint generation = GPOINTER_TO_UINT(user_data);
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) response =
      fl_method_channel_invoke_method_finish(
          FL_METHOD_CHANNEL(source_object), result, &error);

  auto* application_weak_ref = static_cast<GWeakRef*>(g_object_get_data(
      source_object, kPlayerApplicationWeakRefKey));
  if (application_weak_ref == nullptr) return;
  auto* self = MY_APPLICATION(g_weak_ref_get(application_weak_ref));
  if (self == nullptr) return;

  const gboolean is_current_request =
      generation == self->player_close_generation;
  self->player_close_channel_request_pending = FALSE;
  if (is_current_request) {
    self->player_close_request_pending = FALSE;
    if (self->player_close_timeout_source != 0) {
      const guint timeout_source = self->player_close_timeout_source;
      self->player_close_timeout_source = 0;
      g_source_remove(timeout_source);
    }
  }

  gboolean allow_close = FALSE;
  if (response != nullptr && FL_IS_METHOD_SUCCESS_RESPONSE(response)) {
    FlValue* value = fl_method_success_response_get_result(
        FL_METHOD_SUCCESS_RESPONSE(response));
    allow_close = value != nullptr &&
                  fl_value_get_type(value) == FL_VALUE_TYPE_BOOL &&
                  fl_value_get_bool(value);
  }

  if (is_current_request && allow_close && self->player_window != nullptr) {
    g_message("KONGROO_F2_2_GTK_CLOSE_ACCEPTED_AFTER_CLEANUP");
    self->player_close_guard_enabled = FALSE;
    gtk_widget_destroy(GTK_WIDGET(self->player_window));
    self->player_window = nullptr;
  } else if (is_current_request && error != nullptr) {
    g_warning("F2.2 close handshake failed: %s", error->message);
  }
  g_object_unref(self);
}

static gboolean player_window_delete_event_cb(GtkWidget* widget,
                                               GdkEvent* event,
                                               gpointer user_data) {
  (void)widget;
  (void)event;
  MyApplication* self = MY_APPLICATION(user_data);
  if (!self->player_close_guard_enabled) return FALSE;
  if (self->player_close_request_pending ||
      self->player_window_channel == nullptr ||
      self->player_close_channel_request_pending) {
    return TRUE;
  }

  self->player_close_request_pending = TRUE;
  self->player_close_channel_request_pending = TRUE;
  const guint generation = ++self->player_close_generation;
  // Dart normally replies within its 15 s cleanup watchdog. This runner-side
  // watchdog updates the request state if GTK remains responsive, but cannot
  // cancel the MethodChannel call or safely retry it while its callback is
  // outstanding. The window remains guarded until that callback returns.
  self->player_close_timeout_source = g_timeout_add_seconds_full(
      G_PRIORITY_DEFAULT, 20, player_close_timeout_cb,
      player_close_request_new(self, generation), player_close_request_free);
  fl_method_channel_invoke_method(
      self->player_window_channel, "requestClose", nullptr, nullptr,
      player_close_response_cb, GUINT_TO_POINTER(generation));
  return TRUE;
}

static gboolean player_window_is_fullscreen(MyApplication* self) {
  if (self->player_window == nullptr) return FALSE;
  GdkWindow* window = gtk_widget_get_window(GTK_WIDGET(self->player_window));
  if (window == nullptr) return FALSE;
  return (gdk_window_get_state(window) & GDK_WINDOW_STATE_FULLSCREEN) != 0;
}

static gboolean player_window_state_event_cb(GtkWidget* widget,
                                              GdkEventWindowState* event,
                                              gpointer user_data) {
  (void)widget;
  MyApplication* self = MY_APPLICATION(user_data);
  if ((event->changed_mask & GDK_WINDOW_STATE_FULLSCREEN) == 0 ||
      self->player_fullscreen_channel == nullptr) {
    return FALSE;
  }

  const gboolean fullscreen =
      (event->new_window_state & GDK_WINDOW_STATE_FULLSCREEN) != 0;
  g_autoptr(FlValue) value = fl_value_new_bool(fullscreen);
  fl_method_channel_invoke_method(self->player_fullscreen_channel,
                                 "fullscreenChanged", value, nullptr, nullptr,
                                 nullptr);
  g_message("KONGROO_F2_3_FULLSCREEN_STATE observed=%s",
            fullscreen ? "true" : "false");
  return FALSE;
}

static FlMethodResponse* player_window_handle_method_call(
    MyApplication* self,
    FlMethodCall* method_call) {
  const gchar* method = fl_method_call_get_name(method_call);
  if (g_strcmp0(method, "getFullscreenState") == 0) {
    return FL_METHOD_RESPONSE(
        fl_method_success_response_new(
            fl_value_new_bool(player_window_is_fullscreen(self))));
  }
  if (g_strcmp0(method, "setFullscreen") != 0) {
    return FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  FlValue* arguments = fl_method_call_get_args(method_call);
  if (arguments == nullptr || fl_value_get_type(arguments) != FL_VALUE_TYPE_BOOL) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "invalid_arguments", "setFullscreen expects a bool", nullptr));
  }
  if (self->player_window == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "window_unavailable", "The GTK player window is unavailable", nullptr));
  }

  const gboolean requested = fl_value_get_bool(arguments);
  if (requested) {
    gtk_window_fullscreen(GTK_WINDOW(self->player_window));
  } else {
    gtk_window_unfullscreen(GTK_WINDOW(self->player_window));
  }
  // Do not return the immediate GDK state: the compositor may not have
  // processed the transition yet. Only window-state-event confirms it.
  return FL_METHOD_RESPONSE(fl_method_success_response_new(
      fl_value_new_null()));
}

static void player_window_method_call_cb(FlMethodChannel* channel,
                                         FlMethodCall* method_call,
                                         gpointer user_data) {
  (void)channel;
  MyApplication* self = MY_APPLICATION(user_data);
  g_autoptr(FlMethodResponse) response =
      player_window_handle_method_call(self, method_call);
  fl_method_call_respond(method_call, response, nullptr);
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  self->player_window = window;
  self->player_close_guard_enabled =
      g_strcmp0(g_getenv("KONGROO_F2_2_SPIKE"), "1") == 0;
  g_signal_connect(window, "delete-event",
                   G_CALLBACK(player_window_delete_event_cb), self);
  g_signal_connect(window, "window-state-event",
                   G_CALLBACK(player_window_state_event_cb), self);

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Kongroo");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Kongroo");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->player_window_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "kongroo/f2.2/window", FL_METHOD_CODEC(codec));
  self->player_fullscreen_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "kongroo/f2.3/window", FL_METHOD_CODEC(codec));
  auto* application_weak_ref = g_new0(GWeakRef, 1);
  g_weak_ref_init(application_weak_ref, G_OBJECT(self));
  g_object_set_data_full(G_OBJECT(self->player_window_channel),
                         kPlayerApplicationWeakRefKey, application_weak_ref,
                         player_application_weak_ref_free);
  fl_method_channel_set_method_call_handler(
      self->player_fullscreen_channel, player_window_method_call_cb, self,
      nullptr);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->player_window_channel);
  g_clear_object(&self->player_fullscreen_channel);
  self->player_window = nullptr;
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}

```

## app/linux/runner/my_application.h

```
#ifndef FLUTTER_MY_APPLICATION_H_
#define FLUTTER_MY_APPLICATION_H_

#include <gtk/gtk.h>

G_DECLARE_FINAL_TYPE(MyApplication,
                     my_application,
                     MY,
                     APPLICATION,
                     GtkApplication)

/**
 * my_application_new:
 *
 * Creates a new Flutter-based application.
 *
 * Returns: a new #MyApplication.
 */
MyApplication* my_application_new();

#endif  // FLUTTER_MY_APPLICATION_H_

```
