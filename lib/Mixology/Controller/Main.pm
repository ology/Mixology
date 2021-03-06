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
  my @bind = ($category);
  if ($category && $others{$category}) {
    $sql .= ' AND name != ?';
    push @bind, $others{$category};
  }
  my $ingredients = $self->dbh->selectall_arrayref($sql, undef, @bind);
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

sub shuffle ($self) {
  my $others = $self->param('ingredients');
  my %others = split /:/, $others;
  my $sql = 'SELECT name FROM ingredient WHERE category_id = ? AND name != ?';
  for my $category (keys %others) {
    my @bind = ($category, $others{$category});
    my $ingredients = $self->dbh->selectall_arrayref($sql, undef, @bind);
    my $ingredient = $ingredients->[ int rand @$ingredients ][0];
    $others{$category} = $ingredient;
  }
  my $fresh = join ':', map { $_ . ':' . $others{$_} } keys %others;
  $self->redirect_to(
    $self->url_for('main')->query(
      ingredients => $fresh,
    )
  );
}

sub edit ($self) {
  my $category = $self->param('category');
  my $others = $self->param('ingredients');
  my $sql = 'SELECT name FROM category WHERE id = ?';
  my $name = $self->dbh->selectall_arrayref($sql, undef, $category)->[0][0];
  $sql = 'SELECT id,name FROM ingredient WHERE category_id = ? ORDER BY name';
  my $ingredients = $self->dbh->selectall_arrayref($sql, { Slice => {} }, $category);
  $self->render(
    category    => $category,
    name        => $name,
    ingredients => $others,
    children    => $ingredients,
  );
}

sub update ($self) {
  my $category = $self->param('category');
  my $title = $self->param('title');
  my $new_ingredient = $self->param('new_ingredient');
  if ($new_ingredient) {
    my $sql = 'INSERT INTO ingredient (name, category_id) VALUES (?, ?)';
    my $rv = $self->dbh->do($sql, undef, $new_ingredient, $category);
  }
  my $sql = 'SELECT name FROM category WHERE id = ?';
  my $name = $self->dbh->selectall_arrayref($sql, undef, $category)->[0][0];
  if ($title && $title ne $name) {
    $sql = 'UPDATE category SET name = ? WHERE id = ?';
    my $rv = $self->dbh->do($sql, undef, $title, $category);
  }
  my @ingredients = grep { $_ =~ /^ingredient_/ } @{ $self->req->params->names };
  for my $ingredient (@ingredients) {
    my $name = $self->param($ingredient);
    (my $id = $ingredient) =~ s/^ingredient_(\d+)$/$1/;
    $sql = 'UPDATE ingredient SET name = ? WHERE id = ?';
    my $rv = $self->dbh->do($sql, undef, $name, $id);
  }
  $self->redirect_to($self->url_for('edit')->query(
    category => $category,
  ));
}

sub delete_ingredient ($self) {
  my $category = $self->param('category');
  my $ingredient = $self->param('ingredient');
  my $sql = 'DELETE FROM ingredient WHERE id = ?';
  my $rv = $self->dbh->do($sql, undef, $ingredient);
  $self->redirect_to($self->url_for('edit')->query(
    category => $category,
  ));
}

sub delete_category ($self) {
  my $category = $self->param('category');
  my $sql = 'DELETE FROM ingredient WHERE category_id = ?';
  my $rv = $self->dbh->do($sql, undef, $category);
  $sql = 'DELETE FROM category WHERE id = ?';
  $rv = $self->dbh->do($sql, undef, $category);
  $self->redirect_to($self->url_for('main'));
}

sub new_category ($self) {
  my $name = $self->param('name');
  if ($name) {
    my $sql = 'INSERT INTO category (name) VALUES (?)';
    my $rv = $self->dbh->do($sql, undef, $name);
  }
  $self->redirect_to($self->url_for('main'));
}

1;
