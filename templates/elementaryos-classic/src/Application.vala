public class MyApp : Gtk.Application {
    public MyApp () {
        Object (
            application_id: "com.github.${USERNAME}.${PROGRAM_NAME}",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var main_window = new Gtk.ApplicationWindow (this) {
            default_height = 300,
            default_width = 300,
            title = "Hello World"
        };

        var gtk_settings = Gtk.Settings.get_default ();
        var granite_settings = Granite.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = (
            granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
        );

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = (
                granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
            );
        });

        main_window.show_all ();
    }

    public static int main (string[] args) {
        return new MyApp ().run (args);
    }
}
