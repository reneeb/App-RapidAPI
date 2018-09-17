package App::RapidAPI::Schema;

# ABSTRACT: build the DBIx::Class schema for the API prototype

use v5.20;

use strict;
use warnings;

use experimental 'signatures';
no warnings 'experimental::signatures';

use parent 'Exporter';

use Carp qw(croak);

our @EXPORT = qw(
    create_schema
);

sub create_schema ( $mwb, $name, $dir, $namespace = $name . '::DB', $schema = 'Schema' ) {
    eval {
        require MySQL::Workbench::DBIC;
    } or croak "Can't load MySQL::Workbench::DBIC, you can't create the schema";

    my $foo = MySQL::Workbench::DBIC->new(
        file           => $mwb,
        output_path    => $dir,
        namespace      => $namespace,
        version_add    => 1,
        schema_name    => $schema,
        column_details => 1, # default 1
    );

    $foo->create_schema;

    return 1;
}

1;
