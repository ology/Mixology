package Mojolicious::Plugin::DB;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Mojo::SQLite;

sub register {
    my ($self, $app) = @_;

    $app->helper(sqlite => sub {
        my ($c) = @_;
        return state $sqlite = Mojo::SQLite->new('sqlite:mixology.db');
    });

}

1;
