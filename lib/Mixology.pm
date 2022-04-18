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
  $r->get('/shuffle')->to('Main#shuffle')->name('shuffle');
  $r->get('/edit')->to('Main#edit')->name('edit');
  $r->post('/edit')->to('Main#update')->name('update');
}

1;
