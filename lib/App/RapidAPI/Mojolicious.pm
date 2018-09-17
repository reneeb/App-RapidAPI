package App::RapidAPI::Mojolicious;

use v5.20;

use strict;
use warnings;

use experimental 'signatures';
no warnings 'experimental::signatures';

use File::Path qw(make_path);

use App::RapidAPI::Utils qw(
    render_to_rel_file
    class_to_file
    class_to_path
    decamelize
    camelize
);

use parent 'Exporter';

our @EXPORT = qw(generate_mojo_app generate_mojo_app_config);

sub generate_mojo_app ($dir, $app_name, $config, $tables) {

    my $share_dir = $ENV{RAPIDAPI_SHAREDIR} || module_dir( 'App::RapidAPI');
    my %templates = map {

        my $template = File::Spec->catfile(
            $share_dir,
            $_,
        );

        $_ => $template;
    } qw(mojo appclass config controller test static);

    make_path $dir, "$dir/";
    make_path "$dir/$_" for qw(script lib);
    make_path "$dir/lib/$app_name";
    make_path "$dir/lib/$app_name/Controller";

    # Script
    my $name = class_to_file $app_name;
    render_to_rel_file($templates{mojo}, "$dir/script/$name", { app_name => $app_name });
    chmod 0744, "$name/script/$name";

    # Application class
    my $app = class_to_path $app_name;
    render_to_rel_file($templates{appclass}, "$dir/lib/$app", {
        class    => $app_name,
        use_DBIC => $config->{use_dbic},
    });

    # Config file (using the default moniker)
    render_to_rel_file($templates{config}, "$dir/$name/@{[decamelize $app_name]}.conf", {
    });

    my @object_list = @{ $tables || [
        bless { name => 'Example' }, 'App::RapidApp::MockTable'
    ]};

    for my $object ( @object_list ) {

        # Controller
        my $cname = $object->name;
        my $class = camelize $cname;

        my $controller = sprintf "%s::Controller::%s", $app_name, $class;
        my $path       = class_to_path $controller;
        render_to_rel_file($templates{controller}, "$dir/lib/$path", {
            class => $controller,
        });

        # Test
        render_to_rel_file($templates{test}, "$name/t/$cname.t", {
            class => $class,
            name  => $name,
        });
    }

    # Static file
    render_to_rel_file($templates{static}, "$name/public/index.html", {
    });
}

sub generate_mojo_app_config {
}

sub App::RapidAPI::MockTable::name { return shift->{name} }

1;
