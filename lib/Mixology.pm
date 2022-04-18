package Mixology;

use Mojo::Base 'Mojolicious', -signatures;

sub startup ($self) {
  my $config = $self->plugin('NotYAMLConfig');

  $self->plugin('Mixology::DB::Plugin');

  $self->secrets($config->{secrets});

  my $r = $self->routes;

  $r->get('/')->to('Main#main')->name('main');
  $r->get('/mix')->to('Main#mix')->name('mix');
  $r->get('/unmix')->to('Main#unmix')->name('unmix');
}

1;
