public class SettingsWidgetFactory : GLib.Object {
    public Gtk.Widget create_widget_for_key(GLib.Settings settings, SchemaParser.SchemaKey key) {
        if (key.is_enum) {
            return create_enum_widget(settings, key);
        }

        switch (key.value_type.dup_string()) {
            case "b":
                return create_boolean_widget(settings, key);
            case "i":
                return create_integer_widget(settings, key);
            case "d":
                return create_double_widget(settings, key);

            case "s":
                if (key.name.contains("color")) {
                    return create_color_widget(settings, key);
                } else if (key.name.contains("css") || key.name.contains("directory")) {
                    return create_file_widget(settings, key);
                }
                return create_string_widget(settings, key);
            case "as":
                return create_string_array_widget(settings, key);
            case "(ii)":
                return create_int_tuple_widget(settings, key);
            case "u":
                // message("key.name; %s",key.name);
                return new Gtk.Label("Unsupported setting type");
                return create_unsigned_integer_widget(settings, key);
            case "(dd)":
                return create_double_tuple_widget(settings, key);
            default:
                warning("Unsupported type: %s", key.value_type.dup_string());
                return new Gtk.Label("Unsupported setting type");
        }
    }


    private Gtk.Widget create_unsigned_integer_widget(GLib.Settings settings, SchemaParser.SchemaKey key) {
        uint current_value = settings.get_uint(key.name);
        var scale = new Gtk.Scale(Gtk.Orientation.HORIZONTAL, null);

        if (key.range.get_type_string() == "(sv)") {
            string range_type;
            Variant range_value;
            key.range.get("(sv)", out range_type, out range_value);

            if (range_type == "range") {
                uint min_value, max_value;
                range_value.get("(uu)", out min_value, out max_value);
                scale.set_range(min_value, max_value);
            } else {
                // Default range if not specified
                scale.set_range(0, 100);
            }
        }

        scale.set_value(current_value);
        scale.set_draw_value(true);
        scale.set_digits(0);
        settings.bind(key.name, scale.adjustment, "value", SettingsBindFlags.DEFAULT);

        return scale;
    }


    private Gtk.Widget create_integer_widget(GLib.Settings settings, SchemaParser.SchemaKey key) {
        int current_value = settings.get_int(key.name);
        var scale = new Gtk.Scale(Gtk.Orientation.HORIZONTAL, null);

        if (key.range.get_type_string() == "(sv)") {
            string range_type;
            Variant range_value;
            key.range.get("(sv)", out range_type, out range_value);

            if (range_type == "range") {
                int min_value, max_value;
                range_value.get("(ii)", out min_value, out max_value);
                scale.set_range(min_value, max_value);
            } else {
                // Default range if not specified
                scale.set_range(0, 100);
            }
        }

        scale.set_value(current_value);
        scale.set_draw_value(true);
        scale.set_digits(0);
        settings.bind(key.name, scale.adjustment, "value", SettingsBindFlags.DEFAULT);

        return scale;
    }

    private Gtk.Widget create_double_widget(GLib.Settings settings, SchemaParser.SchemaKey key) {
        double current_value = settings.get_double(key.name);
        var scale = new Gtk.Scale(Gtk.Orientation.HORIZONTAL, null);

        if (key.range.get_type_string() == "(sv)") {
            string range_type;
            Variant range_value;
            key.range.get("(sv)", out range_type, out range_value);

            if (range_type == "range") {
                double min_value, max_value;
                range_value.get("(dd)", out min_value, out max_value);
                scale.set_range(min_value, max_value);
            }
        }

        scale.set_value(current_value);
        scale.set_draw_value(true);
        scale.set_digits(2);
        settings.bind(key.name, scale.adjustment, "value", SettingsBindFlags.DEFAULT);
        return scale;
    }

    private Gtk.Widget create_double_tuple_widget(GLib.Settings settings, SchemaParser.SchemaKey key) {
        var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

        Variant tuple = settings.get_value(key.name);
        double min_val, max_val;
        tuple.get("(dd)", out min_val, out max_val);

        double spin_min = 0.0;
        double spin_max = 100.0;
        if (key.range != null && key.range.get_type_string() == "(dd)") {
            Variant range_min_var, range_max_var;
            key.range.get("(dd)", out range_min_var, out range_max_var);
            spin_min = range_min_var.get_double();
            spin_max = range_max_var.get_double();
        }

        var min_spin = new Gtk.SpinButton.with_range(spin_min, spin_max, 0.1);
        var max_spin = new Gtk.SpinButton.with_range(spin_min, spin_max, 0.1);

        min_spin.value = min_val;
        max_spin.value = max_val;

        min_spin.digits = 2;
        max_spin.digits = 2;

        var min_label = new Gtk.Label("Min:");
        var max_label = new Gtk.Label("Max:");

        min_spin.value_changed.connect(() => {
            if (min_spin.value > max_spin.value) {
                max_spin.value = min_spin.value;
            }
            var new_tuple = new Variant("(dd)", min_spin.value, max_spin.value);
            settings.set_value(key.name, new_tuple);
        });

        max_spin.value_changed.connect(() => {
            if (max_spin.value < min_spin.value) {
                min_spin.value = max_spin.value;
            }
            var new_tuple = new Variant("(dd)", min_spin.value, max_spin.value);
            settings.set_value(key.name, new_tuple);
        });

        box.append(min_label);
        box.append(min_spin);
        box.append(max_label);
        box.append(max_spin);

        return box;
    }


    private Gtk.Widget create_int_tuple_widget(GLib.Settings settings, SchemaParser.SchemaKey key) {
        var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

        Variant tuple = settings.get_value(key.name);
        int min_val, max_val;
        tuple.get("(ii)", out min_val, out max_val);

        int spin_min = 0;
        int spin_max = int.MAX;
        if (key.range != null && key.range.get_type_string() == "(ii)") {
            Variant range_min_var, range_max_var;
            key.range.get("(ii)", out range_min_var, out range_max_var);
            spin_min = range_min_var.get_int32();
            spin_max = range_max_var.get_int32();
        }

        var min_spin = new Gtk.SpinButton.with_range(spin_min, spin_max, 1);
        var max_spin = new Gtk.SpinButton.with_range(spin_min, spin_max, 1);

        min_spin.value = min_val;
        max_spin.value = max_val;

        var min_label = new Gtk.Label("Min:");
        var max_label = new Gtk.Label("Max:");

        min_spin.value_changed.connect(() => {
            if (min_spin.value > max_spin.value) {
                max_spin.value = min_spin.value;
            }
            var new_tuple = new Variant("(ii)", (int)min_spin.value, (int)max_spin.value);
            settings.set_value(key.name, new_tuple);
        });

        max_spin.value_changed.connect(() => {
            if (max_spin.value < min_spin.value) {
                min_spin.value = max_spin.value;
            }
            var new_tuple = new Variant("(ii)", (int)min_spin.value, (int)max_spin.value);
            settings.set_value(key.name, new_tuple);
        });

        box.append(min_label);
        box.append(min_spin);
        box.append(max_label);
        box.append(max_spin);

        return box;
    }

    private Gtk.Switch create_boolean_widget(GLib.Settings settings, SchemaParser.SchemaKey key) {
        var switch_widget = new Gtk.Switch();
        settings.bind(key.name, switch_widget, "active", SettingsBindFlags.DEFAULT);
        return switch_widget;
    }

    private Gtk.Widget create_string_widget(GLib.Settings settings, SchemaParser.SchemaKey key) {
        var entry = new Gtk.Entry();
        settings.bind(key.name, entry, "text", SettingsBindFlags.DEFAULT);
        return entry;
    }

    private Gtk.Widget create_color_widget(GLib.Settings settings, SchemaParser.SchemaKey key) {
        var dialog = new Gtk.ColorDialog();
        dialog.set_title("Choose Color");
        dialog.set_with_alpha(true);
        dialog.set_modal(true);

        var button = new Gtk.ColorDialogButton(dialog);

        // Convert hex color to RGBA and set initial color
        var color_str = settings.get_string(key.name);
        var rgba = Gdk.RGBA();
        rgba.parse(color_str);
        button.set_rgba(rgba);

        // Connect to property changes
        button.notify["rgba"].connect(() => {
            var color = button.get_rgba();
            if (color != null) {
                settings.set_string(key.name, color.to_string());
            }
        });

        return button;
    }

    private Gtk.Widget create_file_widget(GLib.Settings settings, SchemaParser.SchemaKey key) {
        var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var entry = new Gtk.Entry();
        var button = new Gtk.Button.with_label("Browse...");

        settings.bind(key.name, entry, "text", SettingsBindFlags.DEFAULT);

        button.clicked.connect(() => {
            on_file_button_clicked.begin(button, key, settings);
        });

        box.append(entry);
        box.append(button);
        return box;
    }

    private async void on_file_button_clicked(Gtk.Button button, SchemaParser.SchemaKey key, GLib.Settings settings) {
        try {
            var dialog = new Gtk.FileDialog();
            dialog.set_title("Choose File");

            if (key.name.contains("directory")) {
                var folder = yield dialog.select_folder((Gtk.Window)button.get_root(), null);
                if (folder != null) {
                    settings.set_string(key.name, folder.get_path());
                }
            } else {
                var file = yield dialog.open((Gtk.Window)button.get_root(), null);
                if (file != null) {
                    settings.set_string(key.name, file.get_path());
                }
            }
        } catch (Error e) {
            warning("Error selecting file: %s", e.message);
        }
    }

    private Gtk.Widget create_string_array_widget(GLib.Settings settings, SchemaParser.SchemaKey key) {
        return new StringArrayWidget(settings, key);
    }


    private Gtk.Widget create_enum_widget(GLib.Settings settings, SchemaParser.SchemaKey key) {
        string[] strings = {};
        GLib.List<string> nick_list = new GLib.List<string>();

        foreach (var enum_value in key.enum_values) {
            strings += enum_value.value_nick;
            message(enum_value.value_nick);
            nick_list.append(enum_value.value_nick);
        }

        var dropdown = new Gtk.DropDown.from_strings(strings);

        string current = settings.get_string(key.name);

        for (int i = 0; i < strings.length; i++) {
            if (strings[i] == current) {
                dropdown.selected = i;
                break;
            }
        }

        // Connect to changes
        dropdown.notify["selected"].connect(() => {
            uint selected = dropdown.selected;
            if (selected < strings.length) {
                settings.set_string(key.name, strings[selected]);
            }
        });

        return dropdown;
    }

}
