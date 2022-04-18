package Mixology::DB::Plugin;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app) = @_;

    $app->helper(dbh => sub {
        my ($c) = @_;
        return state $dbh = DBI->connect('dbi:SQLite:dbname=mixology.db');
    });

}

1;
