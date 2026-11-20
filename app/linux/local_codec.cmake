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
