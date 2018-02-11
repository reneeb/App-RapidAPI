package App::RapidAPI::Mojolicious;

use v5.20;

use strict;
use warnings;

use experimental 'signatures';
no warnings 'experimental::signatures';

use App::RapidAPI::Utils;

use parent 'Exporter';

our @EXPORT = qw(generate_mojo_app);

sub generate_mojo_app ($dir, $name) {
}

1;
