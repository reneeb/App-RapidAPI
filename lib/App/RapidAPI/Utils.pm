package App::RapidAPI::Utils;

use v5.20;

use strict;
use warnings;

use experimental 'signatures';
no warnings 'experimental::signatures';

use Carp qw(croak);
use Template::Tiny;

sub render ($name, $vars) {
    my $file     = $name;
    my $content  = do { local (@ARGV, $/) = $file; <> };
    my $template = Template::Tiny->new(
    );

    my $output  = '';
    $template->process( \$content, $vars, \$output );

    return $output;
}

1;
