-- SQLite

CREATE TABLE category (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

CREATE TABLE ingredient (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    category_id INTEGER NOT NULL
);

INSERT INTO category (name) VALUES
  ("spirit"),
  ("sugar"),
  ("liqueur"),
  ("citrus"),
  ("fruit"),
  ("herb"),
  ("spice"),
  ("bitters");

INSERT INTO ingredient (category_id, name) VALUES
  (1,"rum"),
  (1,"tequila"),
  (1,"gin"),
  (1,"vodka"),
  (1,"whiskey"),
  (1,"brandy"),
  (2,"cane sugar cubes"),
  (2,"simple syrup"),
  (2,"agave"),
  (2,"honey"),
  (2,"maple syrup"),
  (2,"jam / preserves"),
  (3,"elderflower"),
  (3,"sweet vermouth"),
  (3,"almond"),
  (3,"triple sec"),
  (3,"crème de cassis"),
  (3,"maraschino"),
  (4,"lemon"),
  (4,"lime"),
  (4,"orange"),
  (4,"grapefruit"),
  (4,"tangerine"),
  (4,"kumquat"),
  (5,"cherry"),
  (5,"berry"),
  (5,"cucumber"),
  (5,"peach"),
  (5,"apricot"),
  (5,"apple"),
  (6,"mint"),
  (6,"rosemary"),
  (6,"cilantro"),
  (6,"thyme"),
  (6,"basil"),
  (6,"sage"),
  (7,"nutmeg"),
  (7,"clove"),
  (7,"ginger"),
  (7,"cinnamon"),
  (7,"chili"),
  (7,"vanilla"),
  (8,"aromatic"),
  (8,"citrus"),
  (8,"peach"),
  (8,"cherry"),
  (8,"chocolate"),
  (8,"wild");
