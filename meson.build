project('settings', 'vala', 'c')
project_name = 'io.github.trbjo.vala-libraries.settings'

proj_deps = {
    'gtk4': dependency('gtk4-wayland', version: '>= 4.0.0'),
    'gio': dependency('gio-2.0'),
    'glib': dependency('glib-2.0'),
}

deps_list = []
foreach dep_name, dep : proj_deps
    deps_list += dep
endforeach

sources = files(
    'src/schema-parser.vala',
    'src/utils.vala',
    'src/settings-widget-factory.vala',
    'src/settings-window.vala',
    'src/breadcrumbs.vala',
    'src/string-array-widget.vala',
)

gnome = import('gnome')
gresources_settings = gnome.compile_resources(
    'gresources-settings',
    join_paths('data', project_name + '.gresource.xml'),
    c_name: 'bob_settings',
    source_dir: 'data',
)

settings_lib = static_library('settings',
    sources + gresources_settings,
    dependencies: deps_list,
    install: true,
)

settings_dep = declare_dependency(
    link_with: settings_lib,
    dependencies: deps_list,
    include_directories: include_directories('.'),
    sources: gresources_settings
)
