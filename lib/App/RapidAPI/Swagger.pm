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
use JSON;

our @EXPORT = qw(
    create_swagger_spec
);

sub create_swagger_spec ( $name, $dir, $mwb, %opts ) {
    eval {
        require MySQL::Workbench::Parser;
    } or croak "Can't load MySQL::Workbench::Parser, you can't create the swagger spec";

    my $parser = MySQL::Workbench::Parser->new(
        file => $mwb,
    );

    my @tables = @{ $parser->tables || [] };

    my @definitions = _make_definitions( \@tables );
    my @paths       = _make_paths( \@tables, %opts );
    my @tags        = _get_tags( \@tables );

    my $share_dir = $ENV{RAPIDAPI_SHAREDIR} || module_dir( 'App::RapidAPI');

    my $template = File::Spec->catfile(
        $share_dir,
        'swagger.json'
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
        my $cleaned_name = lc( $name =~ s{[^\w]}{_}xmsgr );
        my $path         = File::Spec->catfile( $dir, $cleaned_name . '_swagger.json' );
        my $fh           = IO::File->new( $path, 'w' );

        $fh->print( $spec );
        $fh->close;

        return $path;
    }

    return $spec;
}

sub _get_tags ( $tables ) {
    my @objects = @{ $tables };

    my @tags;
    for my $object ( @objects ) {
        push @tags, { name => $object->name };
    }

    @tags && do { $tags[-1]->{last} = 1 };

    return @tags;
}

sub _make_definitions ( $tables ){
    my @objects = @{ $tables };

    my @definitions;
    for my $object ( @objects ) {
        my @properties = _get_properties( $object );

        push @definitions, {
            object     => $object->name,
            properties => \@properties,
        };
    }

    push @definitions, {
        object     => 'BadRequest',
        properties => [
            {
                name => 'error_msg',
                type => 'string',
                last => 1,
            },
        ],
    };

    @definitions && do { $definitions[-1]->{last} = 1 };

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

    @properties && do { $properties[-1]->{last} = 1 };

    return @properties;
}

sub _get_parameters ( $object ) {
    my %parameters;

    my $pk = $object->primary_key;

    COLUMN:
    for my $column ( @{ $object->columns || [] } ) {
        my $name = $column->name;

        next COLUMN if $column->autoincrement;
        next COLUMN if !$name;

        my $is_in_pk = grep{ $_ eq $name }@{ $pk || [] };
        my $in       = $is_in_pk ? 'path' : 'body';

        my $comment  = $column->comment;
        my $data     = eval { JSON->new->utf8(1)->decode( $comment || '{}' ) };

        $parameters{$name} = {
            required    => ( $column->not_null ? 'true' : 'false' ),
            in          => $in,
            name        => $name,
            description => $data->{description},
        };
    }

    return %parameters;
}

sub _make_paths ( $tables, %opts ){
    my @objects = @{ $tables };

    my @paths;

    my $bad_request = {
        code   => 400,
        schema => 'BadRequest',
        last   => 1,
    };

    for my $object ( @objects ) {
        my $base_name = "/" . lc $object->name;

        my @tags = ({
            name => $object->name,
            last => 1,
        });

        my %parameters    = _get_parameters( $object );
        my @parameterlist = sort { $a->{name} cmp $b->{name} }values %parameters;
        my @post_params   = grep{ $_->{in} ne 'path' }@parameterlist;

        @post_params   && do { $post_params[-1]->{last} = 1 };
        @parameterlist && do { $parameterlist[-1]->{last} = 1 };

        push @paths, {
            name    => $base_name,
            methods => [
                {
                    tags        => \@tags,
                    id          => $object->name . '_create',
                    description => 'Create new ' . $object->name,
                    type        => 'post',
                    parameters  => [
                        @post_params,
                    ],
                    responses => [
                        {
                            code   => 201,
                            schema => $object->name,
                        },
                        $bad_request,
                    ],
                    ( $opts{mojo} ? (
                              'x-mojo-to'   => $object->name . '#post',
                              'x-mojo-name' => $object->name . '_create'
                        ) : ()
                    ),
                },
                {
                    tags        => \@tags,
                    id          => $object->name . '_list',
                    description => 'Get list of ' . $object->name,
                    type        => 'get',
                    parameters  => [
                    ],
                    responses => [
                        {
                            code  => 200,
                            type  => 'array',
                            items => $object->name,
                        },
                        $bad_request,
                    ],
                    ( $opts{mojo} ? (
                              'x-mojo-to'   => $object->name . '#list',
                              'x-mojo-name' => $object->name . '_list'
                        ) : ()
                    ),
                },
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
            name => $path_name,
        };

        my %info = (
            get => {
                description => 'Get one entity of ' . $object->name,
                responses   => [
                    {
                        code        => 200,
                        schema      => $object->name,
                    },
                    $bad_request,
                ],
            },
            delete => {
                description => 'Delete ' . $object->name,
                responses   => [
                    {
                        code        => 204,
                    },
                    $bad_request,
                ],
            },
            patch  => {
                description => 'Update instance of ' . $object->name,
                responses   => [
                    {
                        code        => 200,
                        schema      => $object->name,
                    },
                    $bad_request,
                ],
            },
        );

        for my $method ( qw(get delete patch) ) {
            my $id          = sprintf "%s_%s", $object->name, $method;
            my $description = delete $info{$method}->{description};

            push @{ $paths[-1]->{methods} }, {
                type        => $method,
                tags        => \@tags,
                id          => $id,
                description => $description,
                parameters  => [
                    ( $method eq 'patch' ? @query_params : () ),
                ],
                responses => $info{$method}->{responses},
            };
        }

        @paths && do { $paths[-1]->{methods}->[-1]->{last} = 1 };
    }

    @paths && do { $paths[-1]->{last} = 1 };

    return @paths;
}

1;
