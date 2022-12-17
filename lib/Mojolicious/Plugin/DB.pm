package Mojolicious::Plugin::DB;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

use DBI;
use Mojo::SQLite;

sub register {
    my ($self, $app) = @_;

    $app->helper(dbh => sub {
        my ($c) = @_;
        return state $dbh = DBI->connect('dbi:SQLite:dbname=mixology.db');
    });

    $app->helper(sqlite => sub {
        my ($c) = @_;
        return state $sqlite = Mojo::SQLite->new('sqlite:mixology.db');
    });

}

1;
