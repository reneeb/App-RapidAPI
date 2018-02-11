#!/usr/bin/env perl

use v5.20;

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Basename;
use lib dirname(__FILE__) . '/../../';

use t::App::RapidAPI::TestUtils;

{
    # a simple variable
    use_ok 'App::RapidAPI';
}

done_testing();
