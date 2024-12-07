private class StringArrayWidget : Gtk.Box {
    private GLib.Settings settings;
    private SchemaParser.SchemaKey key;
    private Gtk.ListBox list_box;
    private Gtk.Button add_button;

    public StringArrayWidget(GLib.Settings settings, SchemaParser.SchemaKey key) {
        Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);
        this.settings = settings;
        this.key = key;

        list_box = new Gtk.ListBox() {
            selection_mode = Gtk.SelectionMode.NONE
        };

        add_button = new Gtk.Button.with_label("Add");
        add_button.clicked.connect(() => {
            choose_paths.begin();
        });

        append(list_box);
        append(add_button);
        update_list();
    }

    private void update_list() {
        unowned Gtk.Widget? row = list_box.get_first_child();
        while (row != null) {
            list_box.remove(row);
            row = list_box.get_first_child();
        }

        string[] paths = settings.get_strv(key.name);
        foreach (var path in paths) {
            var row_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

            var icon = new Gtk.Image();
            if (path.has_suffix("/")) {
                icon.icon_name = "folder-symbolic";
            } else {
                icon.icon_name = "image-x-generic-symbolic";
            }

            var label = new Gtk.Label(path) {
                ellipsize = Pango.EllipsizeMode.END,
                hexpand = true,
                xalign = 0
            };

            var remove_button = new Gtk.Button.from_icon_name("list-remove-symbolic");
            remove_button.clicked.connect(() => {
                var current_paths = settings.get_strv(key.name);
                string[] new_paths = {};
                foreach (var p in current_paths) {
                    if (p != path) {
                        new_paths += p;
                    }
                }
                settings.set_strv(key.name, new_paths);
                update_list();
            });

            row_box.append(icon);
            row_box.append(label);
            row_box.append(remove_button);
            list_box.append(row_box);
        }
    }

    private async void choose_paths() {
        try {
            var dialog = new Gtk.FileDialog();
            dialog.set_title("Choose Images");

            var filter = new Gtk.FileFilter();
            filter.add_mime_type("image/jpeg");
            filter.add_mime_type("image/png");
            filter.add_mime_type("image/svg+xml");
            filter.add_mime_type("image/gif");
            filter.add_pattern("*.jpg");
            filter.add_pattern("*.jpeg");
            filter.add_pattern("*.png");
            filter.add_pattern("*.svg");
            filter.add_pattern("*.gif");

            dialog.default_filter = filter;

            var files = yield dialog.open_multiple((Gtk.Window)get_root(), null);
            if (files != null) {
                var dir_counts = new HashTable<string, int>(str_hash, str_equal);

                // Count files per directory
                for (int i = 0; i < files.get_n_items(); i++) {
                    var file = (File)files.get_item(i);
                    var parent = file.get_parent();
                    if (parent != null) {
                        var dir_path = parent.get_path();
                        if (dir_counts.contains(dir_path)) {
                            dir_counts.set(dir_path, dir_counts.get(dir_path) + 1);
                        } else {
                            dir_counts.set(dir_path, 1);
                        }
                    }
                }

                var current_paths = settings.get_strv(key.name);

                // Check directories and add either glob or individual files
                var added_dirs = new HashTable<string, bool>(str_hash, str_equal);

                dir_counts.foreach((dir_path) => {
                    try {
                        var dir = File.new_for_path(dir_path);
                        var total_images = 0;
                        var enumerator = dir.enumerate_children("standard::*", FileQueryInfoFlags.NONE);

                        FileInfo file_info;
                        while ((file_info = enumerator.next_file()) != null) {
                            var content_type = file_info.get_content_type();
                            if (content_type != null && content_type.has_prefix("image/")) {
                                total_images++;
                            }
                        }

                        if (dir_counts.get(dir_path) == total_images) {
                            current_paths += dir_path + "/*";
                            added_dirs.set(dir_path, true);
                        }
                    } catch (Error e) {
                        warning("Error checking directory contents: %s", e.message);
                    }
                });

                // Add individual files for directories that weren't fully selected
                for (int i = 0; i < files.get_n_items(); i++) {
                    var file = (File)files.get_item(i);
                    var parent = file.get_parent();
                    if (parent != null && !added_dirs.contains(parent.get_path())) {
                        current_paths += file.get_path();
                    }
                }

                settings.set_strv(key.name, current_paths);
                update_list();
            }
        } catch (Error e) {
            debug("Error selecting paths: %s", e.message);
        }
    }



}
