package Mixology::Controller::Main;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use DBI;

sub main ($self) {
  my $ingredients = $self->param('ingredients') || '';
  my $sql = 'SELECT id,name FROM category ORDER BY name';
  my $categories = $self->dbh->selectall_arrayref($sql);
  $self->render(
    categories  => $categories,
    ingredients => $ingredients,
  );
}

sub mix ($self) {
  my $category = $self->param('category');
  my $others = $self->param('ingredients');
  my %others = split /:/, $others;
  my $sql = 'SELECT name FROM ingredient WHERE category_id = ?';
  my $ingredients = $self->dbh->selectall_arrayref($sql, undef, $category);
  my $ingredient = $ingredients->[ int rand @$ingredients ][0];
  $others{$category} = $ingredient;
  my $fresh = join ':', map { $_ . ':' . $others{$_} } keys %others;
  $self->redirect_to(
    $self->url_for('main')->query(
      ingredients => $fresh,
    )
  );
}

sub unmix ($self) {
  my $category = $self->param('category');
  my $others = $self->param('ingredients');
  my %others = split /:/, $others;
  delete $others{$category};
  my $fresh = join ':', map { $_ . ':' . $others{$_} } keys %others;
  $self->redirect_to(
    $self->url_for('main')->query(
      ingredients => $fresh,
    )
  );
}

1;
