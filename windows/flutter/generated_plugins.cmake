#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
  audioplayers_windows
  awesome_notifications
  battery_plus
  camera_windows
  connectivity_plus
  dart_vlc
  emoji_picker_flutter
  file_saver
  file_selector_windows
  flutter_secure_storage_windows
  flutter_tts
  flutter_webrtc
  fullscreen_window
  geolocator_windows
  just_audio_windows
  local_auth_windows
  maps_launcher
  network_info_plus
  openpgp
  pdfx
  permission_handler_windows
  record_windows
  screen_retriever
  share_plus
  sqlite3_flutter_libs
  url_launcher_windows
  video_player_win
  webview_win_floating
  window_manager
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/windows plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/windows plugins/${ffi_plugin})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)
