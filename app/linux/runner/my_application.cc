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
