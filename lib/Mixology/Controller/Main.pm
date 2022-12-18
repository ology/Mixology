package Mixology::Controller::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Mojo::SQLite;

sub main ($self) {
  my $ingredients = $self->param('ingredients') || '';
  my $sql = 'SELECT id,name FROM category ORDER BY name';
  my $db = $self->sqlite->db;
  my $categories = $db->query($sql)->arrays;
  $self->render(
    categories  => $categories,
    ingredients => $ingredients,
  );
}

sub mix ($self) {
  my $category = $self->param('category');
  my $ingredients = $self->param('ingredients');
  my %ingredients = split /:/, $ingredients;
  my $sql = 'SELECT name FROM ingredient WHERE category_id = ?';
  my @bind = ($category);
  if ($category && $ingredients{$category}) {
    $sql .= ' AND name != ?';
    push @bind, $ingredients{$category};
  }
  my $db = $self->sqlite->db;
  my $named = $db->query($sql, @bind)->arrays;
  $ingredients{$category} = $named->[ int rand @$named ][0];
  $ingredients = join ':', map { $_ . ':' . $ingredients{$_} } keys %ingredients;
  $self->redirect_to(
    $self->url_for('main')->query(
      ingredients => $ingredients,
    )
  );
}

sub unmix ($self) {
  my $category = $self->param('category');
  my $ingredients = $self->param('ingredients');
  my %ingredients = split /:/, $ingredients;
  delete $ingredients{$category};
  my $fresh = join ':', map { $_ . ':' . $ingredients{$_} } keys %ingredients;
  $self->redirect_to(
    $self->url_for('main')->query(
      ingredients => $fresh,
    )
  );
}

sub shuffle ($self) {
  my $ingredients = $self->param('ingredients');
  my %ingredients = split /:/, $ingredients;
  my $sql = 'SELECT name FROM ingredient WHERE category_id = ? AND name != ?';
  my $db = $self->sqlite->db;
  for my $category (keys %ingredients) {
    my @bind = ($category, $ingredients{$category});
    my $named = $db->query($sql, @bind)->arrays;
    my $ingredient = $named->[ int rand @$named ][0];
    $ingredients{$category} = $ingredient;
  }
  $ingredients = join ':', map { $_ . ':' . $ingredients{$_} } keys %ingredients;
  $self->redirect_to(
    $self->url_for('main')->query(
      ingredients => $ingredients,
    )
  );
}

sub edit ($self) {
  my $category = $self->param('category');
  my $others = $self->param('ingredients');
  my $sql = 'SELECT name FROM category WHERE id = ?';
  my $db = $self->sqlite->db;
  my $name = $db->query($sql, $category)->hash->{name};
  $sql = 'SELECT id,name FROM ingredient WHERE category_id = ? ORDER BY name';
  my $ingredients = $db->query($sql, $category)->hashes;
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
  my $db = $self->sqlite->db;
  if ($new_ingredient) {
    my $sql = 'INSERT INTO ingredient (name, category_id) VALUES (?, ?)';
    $db->query($sql, lc($new_ingredient), $category);
  }
  my $sql = 'SELECT name FROM category WHERE id = ?';
  my $name = $db->query($sql, $category)->hash->{name};
  if ($title && $title ne $name) {
    $sql = 'UPDATE category SET name = ? WHERE id = ?';
    $db->query($sql, lc($title), $category);
  }
  my @ingredients = grep { $_ =~ /^ingredient_/ } $self->req->params->names->@*;
  for my $ingredient (@ingredients) {
    my $name = $self->param($ingredient);
    (my $id = $ingredient) =~ s/^ingredient_(\d+)$/$1/;
    $sql = 'UPDATE ingredient SET name = ? WHERE id = ?';
    $db->query($sql, lc($name), $id);
  }
  $self->redirect_to($self->url_for('edit')->query(
    category => $category,
  ));
}

sub delete_ingredient ($self) {
  my $category = $self->param('category');
  my $ingredient = $self->param('ingredient');
  my $sql = 'DELETE FROM ingredient WHERE id = ?';
  my $db = $self->sqlite->db;
  $db->query($sql, $ingredient);
  $self->redirect_to($self->url_for('edit')->query(
    category => $category,
  ));
}

sub delete_category ($self) {
  my $category = $self->param('category');
  my $sql = 'DELETE FROM ingredient WHERE category_id = ?';
  my $db = $self->sqlite->db;
  $db->query($sql, $category);
  $sql = 'DELETE FROM category WHERE id = ?';
  $db->query($sql, $category);
  $self->redirect_to($self->url_for('main'));
}

sub new_category ($self) {
  my $name = $self->param('name');
  if ($name) {
    my $sql = 'INSERT INTO category (name) VALUES (?)';
    my $db = $self->sqlite->db;
    $db->query($sql, lc($name));
  }
  $self->redirect_to($self->url_for('main'));
}

1;
