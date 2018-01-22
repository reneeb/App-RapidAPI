package App::RapidAPI::Swagger;

# ABSTRACT: build the Swagger specification for the API prototype

use v5.20;

use strict;
use warnings;

use experimental 'signatures';
no warnings 'experimental::signatures';

use parent 'Exporter';

use App::RapidAPI::Utils;

use Carp qw(croak);
use Data::Dumper;
use File::Spec;
use IO::File;

our @EXPORT = qw(
    create_swagger_spec
);

sub create_swagger_spec ( $name, $dir, $mwb ) {
    eval {
        require MySQL::Workbench::Parser;
    } or croak "Can't load MySQL::Workbench::Parser, you can't create the schema";

    my $parser = MySQL::Workbench::Parser->new(
        file => $mwb,
    );

    my @tables = @{ $parser->tables || [] };

    my @definitions = _make_definitions( @tables );
    my @paths       = _make_paths( @tables );

say STDERR Dumper( [ \@paths, \@definitions ] );
exit;

    my $spec = App::RapidAPI::Utils::render(
        'SwaggerSpec.tt',
        {
            name        => $name,
            paths       => \@paths,
            definitions => \@definitions,            
        }
    );

    my $cleaned_name = lc( $name =~ s{[^\w]}{_}xmsg );
    my $path         = File::Spec->catfile( $dir, $cleaned_name . '_swagger.json' );
    my $fh           = IO::File->new( $path, 'w' );

    $fh->print( $spec );
    $fh->close;

    return 1;
}

sub _make_definitions ( @objects ){
    my @definitions;
    for my $object ( @objects ) {
        push @definitions, {
            object_name => $object->name,
        };
    }

    return @definitions;
}

sub _make_paths ( @objects ){
    my @paths;
    for my $object ( @objects ) {
        my $base_name = "/" . lc $object->name;

        push @paths, {
            path_name => $base_name,
            methods   => [
                {
                    method     => 'post',
                    parameters => [
                    ],
                }
            ],
        };

        my $primary_key = $object->

        my $path_name = sprintf "%s/:id", $base_name;
        push @paths, {
            path_name => $path_name,
        };

        for my $method ( qw(get delete patch) ) {
            push @{ $paths[-1]->{methods} }, {
                method     => $method,
                parameters => [
                    {
                        in => 'query',
                    },
                ],
            };
        }
    }

    return @paths;
}

1;
