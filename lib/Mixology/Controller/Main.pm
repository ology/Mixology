package Mixology::Controller::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Mojo::SQLite;
use List::SomeUtils qw(natatime);

sub main ($self) {
  my $ingredients = $self->param('ingredients') || ''; # currently mixed ingredients
  my %ingredients = _transform($ingredients);

  my $db = $self->sqlite->db;
  # select all sorted categories as a LOL
  my $sql = 'SELECT id,name FROM category ORDER BY name';
  my $categories = $db->query($sql)->arrays;
  $self->render(
    categories  => $categories,
    ingredients => $ingredients,
    items       => \%ingredients,
  );
}

sub mix ($self) {
  my $category = $self->param('category'); # chosen category (id)
  my $ingredients = $self->param('ingredients'); # currently mixed ingredients
  # transform the given ingredients into a id => name hash
  my %ingredients = split /:/, $ingredients;
  my $db = $self->sqlite->db;
  # select all ingredients for the given category...
  my $sql = 'SELECT name FROM ingredient WHERE category_id = ?';
  my @bind = ($category);
  # ...that is not one of the given ingredients
  if ($category && $ingredients{$category}) {
    $sql .= ' AND name != ?';
    push @bind, $ingredients{$category};
  }
  my $named = $db->query($sql, @bind)->arrays;
  # choose a random ingredient to mix for the given category
  $ingredients{$category} = $named->[ int rand @$named ][0];
  # remap all the mixed ingredients into colon-separated form
  $ingredients = join ':', map { $_ . ':' . $ingredients{$_} } keys %ingredients;
  $self->redirect_to(
    $self->url_for('main')->query(
      ingredients => $ingredients,
    )
  );
}

sub unmix ($self) {
  my $category = $self->param('category'); # chosen category (id)
  my $ingredients = $self->param('ingredients'); # currently mixed ingredients
  # transform the given ingredients into a id => name hash
  my %ingredients = split /:/, $ingredients;
  # remove the mixed ingredient
  delete $ingredients{$category};
  # remap all the mixed ingredients into colon-separated form
  my $ingredient = join ':', map { $_ . ':' . $ingredients{$_} } keys %ingredients;
  $self->redirect_to(
    $self->url_for('main')->query(
      ingredients => $ingredient,
    )
  );
}

sub shuffle ($self) {
  my $ingredients = $self->param('ingredients'); # currently mixed ingredients
  # transform the given ingredients into a id => name hash
  my %ingredients = split /:/, $ingredients;
  my $db = $self->sqlite->db;
  # select an ingredient for each mixed category that isn't already chosen for that category
  my $sql = 'SELECT name FROM ingredient WHERE category_id = ? AND name != ?';
  for my $category (keys %ingredients) {
    my @bind = ($category, $ingredients{$category});
    my $named = $db->query($sql, @bind)->arrays;
    # choose a random ingredient to mix for the given category
    $ingredients{$category} = $named->[ int rand @$named ][0];
  }
  # remap all the mixed ingredients into colon-separated form
  $ingredients = join ':', map { $_ . ':' . $ingredients{$_} } keys %ingredients;
  $self->redirect_to(
    $self->url_for('main')->query(
      ingredients => $ingredients,
    )
  );
}

sub edit ($self) {
  my $category = $self->param('category'); # chosen category (id)
  my $ingredients = $self->param('ingredients'); # currently mixed ingredients
  my $db = $self->sqlite->db;
  # select the name for the given category id
  my $sql = 'SELECT name FROM category WHERE id = ?';
  my $name = $db->query($sql, $category)->hash->{name};
  # select all sorted ingredients of the given category, as a hashref
  $sql = 'SELECT id,name FROM ingredient WHERE category_id = ? ORDER BY name';
  my $children = $db->query($sql, $category)->hashes;
  $self->render(
    category    => $category,
    name        => $name,
    ingredients => $ingredients, # passthrough for back-button functionality
    children    => $children,
  );
}

sub update ($self) {
  my $category = $self->param('category'); # chosen category (id)
  my $title = $self->param('title'); # category name
  my $new_ingredient = $self->param('new_ingredient');
  my $db = $self->sqlite->db;
  # insert a new ingredient into the db
  if ($new_ingredient) {
    my $sql = 'INSERT INTO ingredient (name, category_id) VALUES (?, ?)';
    $db->query($sql, lc($new_ingredient), $category);
  }
  # select the name for the given category id
  my $sql = 'SELECT name FROM category WHERE id = ?';
  my $name = $db->query($sql, $category)->hash->{name};
  # update the category name if different
  if ($title && $title ne $name) {
    $sql = 'UPDATE category SET name = ? WHERE id = ?';
    $db->query($sql, lc($title), $category);
  }
  # gather all the ingredients
  my @ingredients = grep { $_ =~ /^ingredient_/ } $self->req->params->names->@*;
  for my $ingredient (@ingredients) {
    my $name = $self->param($ingredient);
    (my $id = $ingredient) =~ s/^ingredient_(\d+)$/$1/;
    # update the ingredient name
    $sql = 'UPDATE ingredient SET name = ? WHERE id = ?';
    $db->query($sql, lc($name), $id);
  }
  $self->redirect_to($self->url_for('edit')->query(
    category => $category,
  ));
}

sub delete_ingredient ($self) {
  my $category = $self->param('category'); # chosen category (id)
  my $ingredient = $self->param('ingredient'); # chosen ingredient (id)
  my $db = $self->sqlite->db;
  # delete the ingredient
  my $sql = 'DELETE FROM ingredient WHERE id = ?';
  $db->query($sql, $ingredient);
  $self->redirect_to($self->url_for('edit')->query(
    category => $category,
  ));
}

sub delete_category ($self) {
  my $category = $self->param('category'); # chosen category (id)
  my $db = $self->sqlite->db;
  # delete each ingredient of the category
  my $sql = 'DELETE FROM ingredient WHERE category_id = ?';
  $db->query($sql, $category);
  # delete the category
  $sql = 'DELETE FROM category WHERE id = ?';
  $db->query($sql, $category);
  $self->redirect_to($self->url_for('main'));
}

sub new_category ($self) {
  my $name = $self->param('name'); # category name
  if ($name) {
    my $db = $self->sqlite->db;
    # insert the new category
    my $sql = 'INSERT INTO category (name) VALUES (?)';
    $db->query($sql, lc($name));
  }
  $self->redirect_to($self->url_for('main'));
}

# transform the given ingredients into a data structure
sub _transform {
  my ($string) = @_;
  my @chunks = split /,/, $string;
  my %cats = map { split /\|/, $_ } @chunks;
  my %data;
  for my $cat (keys %cats) {
    my @items = split /:/, $cats{$cat};
    my $it = natatime 2, @items;
    while (my @vals = $it->()) {
      push $data{$cat}->@*, { id => $vals[0], name => $vals[1] };
    }
  }
  return %data;
}

1;
