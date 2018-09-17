package App::RapidAPI::Utils;

use v5.20;

use strict;
use warnings;

use experimental 'signatures';
no warnings 'experimental::signatures';

use parent 'Exporter';

use Carp qw(croak);
use IO::File;
use Path::Tiny;
use Template::Tiny;

our @EXPORT_OK = qw(
    class_to_file
    class_to_path
    decamelize
    camelize
    render
    render_to_rel_file
);

sub render ($name, $vars) {
    my $file     = $name . '.tmpl';
    my $content  = do { local (@ARGV, $/) = $file; <> };
    my $template = Template::Tiny->new(
    );

    my $output  = '';
    $template->process( \$content, $vars, \$output );

    return $output;
}

sub render_to_rel_file ($name, $path, $vars) {
    my $content = render( $name, $vars );
    my $fh      = IO::File->new( $path, 'w' ) or return;
    $fh->binmode( ':encoding(utf-8)' );
    $fh->print( $content );
    $fh->close;
}

sub class_to_file ($class) {
    $class =~ s/::|'//g;
    $class =~ s/([A-Z])([A-Z]*)/$1 . lc $2/ge;
    return decamelize($class);
}

sub class_to_path { join '.', join('/', split(/::|'/, shift)), 'pm' }

sub decamelize ($str) {
    return $str if $str !~ /^[A-Z]/;
 
    # snake_case words
    return join '-', map {
        join('_', map {lc} grep {length} split /([A-Z]{1}[^A-Z]*)/)
    } split '::', $str;
}

sub camelize ($str) {
    return $str if $str =~ /^[A-Z]/;
   
    # CamelCase words
    return join '::', map {
        join('', map { ucfirst lc } split '_')
    } split '-', $str;
}

1;
