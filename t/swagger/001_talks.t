#!/usr/bin/env perl

use v5.20;

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;
use lib dirname(__FILE__) . '/../../';

use t::App::RapidAPI::TestUtils; 

use App::RapidAPI::Swagger;

local $ENV{RAPIDAPI_SHAREDIR} = File::Spec->catdir(
    dirname( __FILE__ ),
    qw(.. ..),
    'share'
);

{
    # check sagger for test table
    my $path   = local_path( 'docs/talks.mwb' );
    my $out    = local_path( 'out' );

    mkdir $out;

    my $output = create_swagger_spec( 'TalksTest', $out, $path, { no_file => 1 } );
    my $check  = slurp_file( local_path( 'docs/001_talks.spec' ) );
    is_string $output, $check

}

done_testing();
