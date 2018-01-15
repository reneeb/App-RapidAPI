package App::RapidAPI;

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
        $lib_dir,
    );

    my $spec_dir = File::Spec->catdir(
        $target_dir,
        'conf',
    );

    make_path $spec_dir;

    generate_swagger_spec (
        $name,
        $spec_dir,
        $model_file,
    );

    generate_mojo_app(
        $target_dir,
        $name,
    );
}

1;

