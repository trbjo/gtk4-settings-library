public class Breadcrumbs : Gtk.Box {
    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        name = "breadcrumbs";

        Gtk.GestureClick click = new Gtk.GestureClick();
        click.set_button(0);
        click.pressed.connect((n_press, x, y) => {
            unowned Gtk.Widget? picked_widget = this.pick(x, y, Gtk.PickFlags.DEFAULT);
            if (picked_widget != null && picked_widget is Gtk.Label) {
                var css_classes = picked_widget.get_css_classes();
                fragment_clicked(css_classes[0]);
            }
        });
        this.add_controller(click);
    }

    public signal void fragment_clicked(string fragment);

    public void update(string schema_id) {
        iterate_children(get_first_child(), (child) => child.unparent());
        string[] parts = schema_id.split(".");

        var path_builder = new StringBuilder();

        for (int i = 0; i < parts.length - 1; i++) {

            path_builder.append(parts[i]);
            append(create_part(parts[i], path_builder.str));
            append(create_separator());
            path_builder.append(".");
        }
        path_builder.append(parts[parts.length - 1]);
        append(create_part(parts[parts.length - 1], path_builder.str));
    }

    private Gtk.Image create_separator() {
        return new Gtk.Image.from_icon_name("path-separator-symbolic") {
            valign = Gtk.Align.BASELINE_CENTER,
            vexpand = true,
            css_classes = { "fragment" },
            can_target = false
        };
    }
    private Gtk.Label create_part(string fragment, string sub_path) {
        return new Gtk.Label(fragment) {
            can_target = true,
            css_classes = {sub_path}
        };
    }

    public delegate void ChildIterator(Gtk.Widget widget);

    public static void iterate_children(Gtk.Widget? child_widget, ChildIterator func) {
        while (child_widget != null) {
            unowned Gtk.Widget? sibling = child_widget.get_next_sibling();
            func(child_widget);
            child_widget = sibling;
        }
    }
}
