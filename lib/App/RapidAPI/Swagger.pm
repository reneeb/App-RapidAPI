package App::RapidAPI::Swagger;

# ABSTRACT: build the Swagger specification for the API prototype

use v5.20;

use strict;
use warnings;

use experimental 'signatures';
no warnings 'experimental::signatures';

use parent 'Exporter';

use App::RapidAPI;
use App::RapidAPI::Utils;

use Carp qw(croak);
use Data::Dumper;
use File::ShareDir qw(:ALL);
use File::Spec;
use IO::File;

our @EXPORT = qw(
    create_swagger_spec
);

sub create_swagger_spec ( $name, $dir, $mwb, %opts ) {
    eval {
        require MySQL::Workbench::Parser;
    } or croak "Can't load MySQL::Workbench::Parser, you can't create the schema";

    my $parser = MySQL::Workbench::Parser->new(
        file => $mwb,
    );

    my @tables = @{ $parser->tables || [] };

    my @definitions = _make_definitions( @tables );
    my @paths       = _make_paths( @tables );
    my @tags        = _get_tags( @tables );

    my $share_dir = $ENV{RAPIDAPI_SHAREDIR} || module_dir( 'App::RapidAPI');

    my $template = File::Spec->catfile(
        $share_dir,
        'swagger.json.tmpl'
    );

    my $description = '';

    my $spec = App::RapidAPI::Utils::render(
        $template,
        {
            name        => $name,
            description => $description,
            paths       => \@paths,
            definitions => \@definitions,
            tags        => \@tags,
        }
    );

    if ( !$opts{no_file} ) {
        my $cleaned_name = lc( $name =~ s{[^\w]}{_}xmsg );
        my $path         = File::Spec->catfile( $dir, $cleaned_name . '_swagger.json' );
        my $fh           = IO::File->new( $path, 'w' );

        $fh->print( $spec );
        $fh->close;
    }

    return $spec;
}

sub _get_tags ( @objects ) {
    my @tags;
    for my $object ( @objects ) {
        push @tags, $object->name;
    }

    return @tags;
}

sub _make_definitions ( @objects ){
    my @definitions;
    for my $object ( @objects ) {
        my @properties = _get_properties( $object );

        push @definitions, {
            object     => $object->name,
            properties => \@properties,
        };
    }

    return @definitions;
}

sub _get_properties ( $object ) {
    my @properties;

    my %types = (
        VARCHAR => 'string',
        CHAR    => 'string',
        DECIMAL => 'number',
    );

    for my $column ( @{ $object->columns || [] } ) {
        my $datatype = $column->datatype;
        my $type     = $types{$datatype};

        push @properties, {
            name => $column->name,
            type => $type,
        };
    }

    return @properties;
}

sub _get_parameters ( $object ) {
    my %parameters;

    my $pk = $object->primary_key;

    COLUMN:
    for my $column ( @{ $object->columns || [] } ) {
        my $name = $column->name;

        next COLUMN if $column->autoincrement;

        my $is_in_pk = grep{ $_ eq $name }@{ $pk || [] };
        my $in       = $is_in_pk ? 'path' : 'body';

        $parameters{$name} = {
            ( $column->not_null ? (required => 'true') : () ),
            in   => $in,
            name => $name,
        };
    }

    return %parameters;
}

sub _make_paths ( @objects ){
    my @paths;
    for my $object ( @objects ) {
        my $base_name = "/" . lc $object->name;

        my %parameters = _get_parameters( $object );

        push @paths, {
            path_name => $base_name,
            methods   => [
                {
                    method     => 'post',
                    parameters => [
                        grep{ $_->{in} ne 'path' }values %parameters,
                    ],
                }
            ],
        };

        my $primary_key         = $object->primary_key;
        my $primary_key_in_path = join '/', map{ ":$_" }@{ $primary_key || [] };

        my @query_params;
        for my $col_name ( @{ $primary_key || [] } ) {
            push @query_params, {
                name => $col_name, 
            };
        }

        my $path_name = sprintf "%s/%s", $base_name, $primary_key_in_path;
        push @paths, {
            path_name => $path_name,
        };

        for my $method ( qw(get delete patch) ) {
            push @{ $paths[-1]->{methods} }, {
                method     => $method,
                parameters => [
                    ( $method eq 'patch' ? @query_params : () ),
                    values %parameters,
                ],
            };
        }
    }

    return @paths;
}

1;
