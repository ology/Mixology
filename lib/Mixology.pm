package Mixology;
use Mojo::Base 'Mojolicious', -signatures;

sub startup ($self) {
  my $config = $self->plugin('NotYAMLConfig');

  $self->plugin('DB');

  $self->secrets($config->{secrets});

  my $r = $self->routes;

  $r->get('/')                 ->to('Main#main')             ->name('main');
  $r->get('/mix')              ->to('Main#mix')              ->name('mix');
  $r->get('/unmix')            ->to('Main#unmix')            ->name('unmix');
  $r->get('/shuffle')          ->to('Main#shuffle')          ->name('shuffle');
  $r->get('/edit')             ->to('Main#edit')             ->name('edit');
  $r->post('/edit')            ->to('Main#update')           ->name('update');
  $r->get('/delete_ingredient')->to('Main#delete_ingredient')->name('delete_ingredient');
  $r->get('/delete_category')  ->to('Main#delete_category')  ->name('delete_category');
  $r->post('/new_category')    ->to('Main#new_category')     ->name('new_category');
}

1;
