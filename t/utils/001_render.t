#!/usr/bin/env perl

use v5.20;

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Basename;
use lib dirname(__FILE__) . '/../../';

use App::RapidAPI::Utils;

use t::App::RapidAPI::TestUtils;

{
    # a simple variable
    my $path   = local_path( 'docs/001_render_simple.tmpl' );
    my $output = App::RapidAPI::Utils::render( $path, { hallo => 'World!' } );
    my $check  = slurp_file( local_path( 'docs/001_render_simple.out' ) );
    is_string $output, $check
}

{
    # render loops
    my $path   = local_path( 'docs/001_render_loop.tmpl' );
    my $output = App::RapidAPI::Utils::render( $path, { definitions => [qw/this is a test/] } );
    my $check  = slurp_file( local_path( 'docs/001_render_loop.out' ) );
    is_string $output, $check
}

done_testing();
