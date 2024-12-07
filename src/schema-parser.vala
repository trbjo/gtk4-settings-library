public class SchemaParser : GLib.Object {
    public class SchemaKey {
        public bool is_enum { get; set; default = false; }
        public string name { get; set; }
        public string summary { get; set; }
        public string description { get; set; }
        public VariantType value_type { get; set; }
        public Variant? default_value { get; set; }
        public Variant? range { get; set; }
        public string? enum_id { get; set; }
        public GLib.List<EnumValue?> enum_values;
        public List<string> enum_strings;

        public SchemaKey(string name) {
            this.name = name;
            this.enum_values = new GLib.List<EnumValue?>();
            this.enum_strings = new List<string>();
            this.is_enum = false;
        }
    }

    public class SchemaSection {
        public string id { get; set; }
        public string path { get; set; }
        public string display_name { get; set; }  // For UI display
        public GLib.List<SchemaKey> keys;
        public GLib.List<SchemaSection> subsections;

        public SchemaSection(string id, string path) {
            this.id = id;
            this.path = path;
            this.keys = new GLib.List<SchemaKey>();
            this.subsections = new GLib.List<SchemaSection>();

            // Extract display name from the last part of the schema ID
            string[] parts = id.split(".");
            this.display_name = parts[parts.length - 1];
        }
    }

    private SchemaSection main_section;
    private SettingsSchemaSource schema_source;
    public string[] hidden_keys;

    public SchemaParser(string settings_id, string[] hidden_keys = {}) {
        this.hidden_keys = hidden_keys;
        schema_source = SettingsSchemaSource.get_default();
        parse_schema(settings_id);
    }

    private void parse_schema(string schema_id) {
        var schema = schema_source.lookup(schema_id, true);

        // Create a section for the current schema we're parsing
        main_section = new SchemaSection(schema.get_id(), schema.get_path());
        parse_schema_keys(schema, main_section);

        // Parse immediate children as subsections
        var children = schema.list_children();
        foreach (var child in children) {
            var child_schema_id = schema_id + "." + child;
            var child_schema = schema_source.lookup(child_schema_id, true);
            var subsection = new SchemaSection(child_schema.get_id(), child_schema.get_path());

            // Parse the child's keys
            parse_schema_keys(child_schema, subsection);
            main_section.subsections.append(subsection);
        }
    }

    private void parse_schema_keys(SettingsSchema schema, SchemaSection section) {
        var keys = schema.list_keys();
        foreach (var key_name in keys) {
            if (key_name in hidden_keys) {
                continue;
            }

            var key = parse_key(schema, key_name);
            if (key != null) {
                section.keys.append(key);
            }
        }
    }

    private SchemaKey? parse_key(SettingsSchema schema, string key_name) {
        GLib.SettingsSchemaKey key_schema = schema.get_key(key_name);
        var key = new SchemaKey(key_name);

        key.value_type = key_schema.get_value_type();
        key.default_value = key_schema.get_default_value();
        key.summary = key_schema.get_summary();
        key.description = key_schema.get_description();
        key.range = key_schema.get_range();

        var range = key_schema.get_range();

        if (range.get_type_string() == "(sv)") {
            string range_type;
            Variant range_variant;
            range.get("(sv)", out range_type, out range_variant);

            if (range_type == "enum") {
                key.is_enum = true;

                var iter = range_variant.iterator();
                string val;
                int enum_value_counter = 0;
                while (iter.next("s", out val)) {
                    var enum_value = EnumValue();
                    enum_value.value = enum_value_counter++;

                    string upper_name = val.up();
                    key.enum_strings.append(upper_name);
                    key.enum_strings.append(val);

                    enum_value.value_name = key.enum_strings.nth_data(key.enum_strings.length() - 2);
                    enum_value.value_nick = key.enum_strings.nth_data(key.enum_strings.length() - 1);

                    key.enum_values.append((!) enum_value);
                }
            }
        }

        return key;
    }

    public unowned SchemaSection get_schema() {
        return main_section;
    }
}
