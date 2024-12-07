public class SettingsWindow : Gtk.Window {
    private SettingsWidgetFactory widget_factory;
    private static Gtk.CssProvider css_provider;
    public string title { get; construct; }

    private Gtk.Box content_box;
    private Breadcrumbs breadcrumbs;

    static construct {
        css_provider = new Gtk.CssProvider();
    }

    public SettingsWindow(Gtk.Application app, string settings_id, string title) {
        Object(title: "%s Settings".printf(title));
        setup_content(settings_id);
    }

    private class MainBox : Gtk.Widget {
        protected override void size_allocate(int width, int height, int baseline) {
            int bar_height = 300;
            iterate_children(get_first_child(), (child_widget) => {
                if (child_widget is Breadcrumbs) {
                    child_widget.measure(Gtk.Orientation.VERTICAL, width, null, out bar_height, null, null);
                    child_widget.allocate(width, bar_height, baseline, null);
                } else if (child_widget is Gtk.ScrolledWindow) {
                    child_widget.allocate(width, height - bar_height, baseline, new Gsk.Transform().translate({0, bar_height}));
                }
            });
        }
    }

    public delegate void ChildIterator(Gtk.Widget widget);

    public static void iterate_children(Gtk.Widget? child_widget, ChildIterator func) {
        while (child_widget != null) {
            unowned Gtk.Widget? sibling = child_widget.get_next_sibling();
            func(child_widget);
            child_widget = sibling;
        }
    }



    construct {
        widget_factory = new SettingsWidgetFactory();

        title = title;
        set_size_request(650, 700);
        decorated = true;

        name = "settings";
        resizable = false;

        var main_box = new MainBox() {
            css_classes = {"main-box"},
        };
        child = main_box;
        var scrolled = new Gtk.ScrolledWindow() {
            vexpand = true,
            valign = Gtk.Align.FILL
        };

        breadcrumbs = new Breadcrumbs();
        breadcrumbs.set_parent(main_box);
        breadcrumbs.fragment_clicked.connect(setup_content);
        scrolled.set_parent(main_box);

        content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
            css_classes = {"content-box"},
            halign = Gtk.Align.CENTER
        };
        scrolled.set_child(content_box);

        Gtk.GestureClick click = new Gtk.GestureClick();
        click.set_button(0);
        click.pressed.connect((n_press, x, y) => {
            unowned Gtk.Widget? picked_widget = content_box.pick(x, y, Gtk.PickFlags.DEFAULT);
            message("picked_widget: %s", picked_widget.get_name());
            if (picked_widget != null && picked_widget.has_css_class("section")) {
                foreach (var cls in picked_widget.get_css_classes()) {
                    if (cls != "section") {
                        setup_content(cls);
                        return;
                    }
                }
            }
        });
        content_box.add_controller(click);


        var headerbar = new Gtk.HeaderBar();
        headerbar.set_title_widget(new Gtk.Label(title));
        set_titlebar(headerbar);

        setup_css();
    }

    private void setup_content(string schema_id) {
        message("setup_content: %s", schema_id);
        iterate_children(content_box.get_first_child(), (child) => child.unparent());
        var schema_parser = new SchemaParser(schema_id);
        var schema_settings = new GLib.Settings(schema_id);

        var section = schema_parser.get_schema();
        setup_sub_content(section, schema_settings);
        breadcrumbs.update(schema_id);
    }

    private void multiple_setup(SchemaParser.SchemaSection subsection, GLib.Settings section_settings) {
        var subsection_frame = new Gtk.Frame(null) {
            overflow = Gtk.Overflow.VISIBLE,
        };

        var subsection_label = new Gtk.Label(title_case(subsection.display_name)) {
            can_target = false,
            halign = Gtk.Align.START,
            css_classes = {"heading"}
        };
        subsection_frame.label_widget = subsection_label;

        var subsection_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
            css_classes = {"section", subsection.id},
            overflow = Gtk.Overflow.VISIBLE,
        };

        if (subsection.keys.length() > 0) {
            add_keys_to_box(subsection_box, subsection, section_settings.get_child(subsection.display_name));
        }

        subsection_frame.child = subsection_box;
        content_box.append(subsection_frame);
    }

    private void simple_setup(SchemaParser.SchemaSection subsection, GLib.Settings section_settings) {
        var subsection_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
            css_classes = {"section", subsection.id},
            overflow = Gtk.Overflow.VISIBLE,
        };

        var subsection_label = new Gtk.Label(title_case(subsection.display_name)) {
            can_target = false,
            halign = Gtk.Align.START,
            css_classes = {"heading"}
        };
        subsection_box.append(subsection_label);

        if (subsection.keys.length() > 0) {
            add_keys_to_box(subsection_box, subsection, section_settings.get_child(subsection.display_name));
        }

        content_box.append(subsection_box);
    }

    private void setup_sub_content(SchemaParser.SchemaSection section, GLib.Settings section_settings) {
        bool has_children = section.subsections.length() > 0;

        foreach (var subsection in section.subsections) {
            if (subsection.keys.length() <= 1) {
                simple_setup(subsection, section_settings);
            } else {
                multiple_setup(subsection, section_settings);
            }

            // if (section_settings.get_child(subsection.display_name).list_children().length > 0) {

        }
    }

    private static string title_case(string input) {
        return (input.substring(0, 1).up() + input.substring(1).down()).replace("-", " ");
    }

    private void setup_css() {
        css_provider.load_from_resource("io/github/trbjo/bob/settings/settings.css");

        SettingsUtils.add_style_context(
            Gdk.Display.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    private void add_keys_to_box(Gtk.Box box, SchemaParser.SchemaSection section, GLib.Settings settings) {
        foreach (var key in section.keys) {
            var entry_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
                css_classes = {"entry-box"},
                overflow = Gtk.Overflow.HIDDEN,
                homogeneous = false,
            };
            var text_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
                css_classes = {"text-box"},
                overflow = Gtk.Overflow.HIDDEN,
                valign = Gtk.Align.CENTER,
                homogeneous = false,
            };
            entry_box.append(text_box);


            var label = new Gtk.Label(key.summary) {
                can_target = false,
                halign = Gtk.Align.START,
                hexpand = true
            };
            text_box.append(label);

            var widget = widget_factory.create_widget_for_key(settings, key);
            widget.halign = Gtk.Align.END;
            widget.valign = Gtk.Align.CENTER;
            entry_box.append(widget);

            if (key.description != null && key.description != "") {
                var description = new Gtk.Label(key.description) {
                    can_target = false,
                    css_classes = {"description"},
                    wrap = true,
                    wrap_mode = Pango.WrapMode.WORD_CHAR,
                    justify = Gtk.Justification.LEFT,
                    halign = Gtk.Align.FILL,
                    hexpand = false,
                    xalign = 0.0f,
                };
                text_box.append(description);
            }

            box.append(entry_box);
        }
    }
}
