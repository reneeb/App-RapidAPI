package App::RapidAPI::DB;

use v5.20;

use strict;
use warnings;

use experimental 'signatures';
no warnings 'experimental::signatures';

use parent 'Exporter';

use Carp qw(croak);

our @EXPORT = qw(
    create_db
);

sub create_db ($name, $mwb) {
    eval {
        require MySQL::Workbench::SQLiteSimple;
        require DBI;
    } or do {
        my $modules = join ', ', qw(
            MySQL::Workbench::SQLiteSimple
            DBI
        );
        croak "Need $modules";
    };

    my $cleaned_name = lc ( $name =~ s{[^\w]}{_}xmsg );
    my $db  = File::Spec->catfile( $dir, $cleaned_name . '.db' );
    my $dbh = DBI->connect( "DBI:SQLite:$db" );

    my $sqlite = MySQL::Workbench::SQLiteSimple->new(
        file => $mwb,
    );

    my @sqls = $sqlite->create_sql( no_files => 1 );

    $dbh->do( $_ ) for @sqls;
}

1;
