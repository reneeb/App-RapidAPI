package 
    t::App::RapidAPI::TestUtils;

use v5.20;

use strict;
use warnings;

use parent qw(Exporter);

use File::Basename;
use File::Spec;

our @EXPORT = qw(
    slurp_file
    local_path
);

sub slurp_file {
    my ($path) = @_;

    local ( @ARGV, $/ ) = $path;
    my $content = <>;

    return $content;
}

sub local_path {
    my ($partial_path) = @_;

    my ($package, $file) = caller(0);

    return File::Spec->rel2abs(
        File::Spec->catfile(
            dirname( $file ),
            $partial_path,
        )
    );
}

1;
