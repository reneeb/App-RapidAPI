package App::RapidAPI;

# ABSTRACT: build a simple prototype for an API

use strict;
use warnings;

use experimental 'signatures';
no warnings 'experimental::signatures';

use File::Spec;
use File::Path qw(make_path);

use App::RapidAPI::Schema;
use App::RapidAPI::DB;
use App::RapidAPI::Swagger;
use App::RapidAPI::Mojolicious;

our $VERSION = 0.01;

sub build_app ($model_file, $name, $target_dir) {
    my $lib_dir = File::Spec->catdir(
        $target_dir,
        'lib',
    );

    make_path $lib_dir;

    create_schema(
        $model_file,
        $name,
        $lib_dir,
    );

    create_db (
        $name,
        $target_dir,
        $model_file,
    );

    my $spec_dir = File::Spec->catdir(
        $target_dir,
        'conf',
    );

    make_path $spec_dir;

    my $swagger_spec = create_swagger_spec (
        $name,
        $spec_dir,
        $model_file,
        mojo => 1,
    );

    my $tables;
    eval {
        require MySQL::Workbench::Parser;
        my $parser = MySQL::Workbench::Parser->new(
            file => $model_file,
        );

        $tables = $parser->tables || [];
    };

    my $config = generate_mojo_app_config( $swagger_spec );
    $config->{use_dbic} = 1;

    generate_mojo_app(
        $target_dir,
        $name,
        $config,
        $tables,
    );
}

1;

