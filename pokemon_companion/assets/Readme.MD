# Pokémon SQLite Database Documentation

This document explains the structure, endpoints, and access methods for the SQLite database created by our data pipeline. The database (named `pokemon.db`) is built by fetching Pokémon data from the PokéAPI, merging it with competitive sets data (from a Gen 9 JSON file), and storing it in a relational schema.

---

## 1. Overview

The database is designed to store comprehensive Pokémon data including species information, variants, evolution chains, and competitive sets. In addition, global data on abilities, items, moves, and natures is stored in separate tables.

**Database File:** `pokemon.db`  
**Access Methods:**  
- Use any SQLite client (e.g., DB Browser for SQLite, SQLiteStudio) to open and browse the database.
- Programmatically access the database using the Python `sqlite3` module or any other SQLite library.

---

## 2. Database Schema

### 2.1 Pokémon and Related Tables

#### **Table: Pokemon**
- **Description:** Stores core information about each Pokémon species.
- **Columns:**
  - `id` (INTEGER, Primary Key, AUTOINCREMENT)
  - `dex_number` (INTEGER) – The National Pokédex number.
  - `name` (TEXT) – The Pokémon’s name (lowercase).

#### **Table: Variant**
- **Description:** Contains data for each variant (form) of a Pokémon.
- **Columns:**
  - `id` (INTEGER, Primary Key, AUTOINCREMENT)
  - `pokemon_id` (INTEGER, Foreign Key → Pokemon.id)
  - `name` (TEXT) – Variant name.
  - `image_url` (TEXT) – URL to official artwork.
  - `hp` (INTEGER) – Base HP.
  - `attack` (INTEGER) – Base Attack.
  - `defense` (INTEGER) – Base Defense.
  - `special_attack` (INTEGER) – Base Special Attack.
  - `special_defense` (INTEGER) – Base Special Defense.
  - `speed` (INTEGER) – Base Speed.

#### **Table: VariantType**
- **Description:** Stores the type(s) associated with each variant.
- **Columns:**
  - `id` (INTEGER, Primary Key, AUTOINCREMENT)
  - `variant_id` (INTEGER, Foreign Key → Variant.id)
  - `type_name` (TEXT) – Name of the type (e.g., "grass", "fire").

#### **Table: VariantAbility**
- **Description:** Contains abilities for each variant.
- **Columns:**
  - `id` (INTEGER, Primary Key, AUTOINCREMENT)
  - `variant_id` (INTEGER, Foreign Key → Variant.id)
  - `ability_name` (TEXT)
  - `ability_description` (TEXT)

#### **Table: Evolution**
- **Description:** Records the evolution chain for each Pokémon species.
- **Columns:**
  - `id` (INTEGER, Primary Key, AUTOINCREMENT)
  - `pokemon_id` (INTEGER, Foreign Key → Pokemon.id)
  - `stage` (INTEGER) – Evolution stage order (0 for base form, 1 for next evolution, etc.).
  - `species_name` (TEXT) – Name of the species at this stage.
  - `evolution_details` (TEXT) – JSON string describing evolution conditions (e.g., level requirements).

#### **Table: CompetitiveSet**
- **Description:** Stores competitive (Gen 9) sets for each variant, if available.
- **Columns:**
  - `id` (INTEGER, Primary Key, AUTOINCREMENT)
  - `variant_id` (INTEGER, Foreign Key → Variant.id)
  - `tier` (TEXT) – Competitive tier (e.g., "pu", "nu", "ou").
  - `set_name` (TEXT) – Name of the specific set/archetype (e.g., "Defensive Spinner").
  - `moves` (TEXT) – JSON string (list) of moves.
  - `ability` (TEXT) – JSON string (or simple string) representing the ability.
  - `item` (TEXT) – JSON string (list) of recommended held items.
  - `nature` (TEXT) – JSON string (or simple string) representing the recommended nature.
  - `ivs` (TEXT) – JSON string (object) containing Individual Values.
  - `evs` (TEXT) – JSON string (object or list) containing Effort Values.
  - `teratypes` (TEXT) – JSON string (list) of suggested Tera Types.

---

## 3. Accessing the Data (Endpoints / Sample Queries)

### 3.1 Retrieving Pokémon Species
```sql
SELECT id, dex_number, name FROM Pokemon;
```

### 3.2 Listing Variants for a Given Pokémon
```sql
SELECT V.id, V.name, V.hp, V.attack, V.defense
FROM Variant V
JOIN Pokemon P ON V.pokemon_id = P.id
WHERE P.name = 'bulbasaur';
```

### 3.3 Retrieving Types for a Specific Variant
```sql
SELECT type_name FROM VariantType
WHERE variant_id = 1;
```

### 3.4 Joining Variant Abilities
```sql
SELECT V.name, A.ability_name, A.ability_description
FROM Variant V
JOIN VariantAbility A ON V.id = A.variant_id
WHERE V.name = 'bulbasaur';
```

### 3.5 Accessing Evolution Chain Data
```sql
SELECT stage, species_name, evolution_details
FROM Evolution
WHERE pokemon_id = 1
ORDER BY stage;
```

### 3.6 Retrieving Competitive Sets
```sql
SELECT tier, set_name, moves, ability, item, nature, ivs, evs, teratypes
FROM CompetitiveSet
WHERE variant_id = 1;
```

### 3.7 Querying Global Data
```sql
SELECT name, description, method FROM GlobalMove;
```

---

## 4. How to Use and Access the Database

- **Opening the Database:**  
  Use any SQLite client or command-line tool:
  ```bash
  sqlite3 pokemon.db
  ```

- **Programmatic Access:**  
  In Python:
  ```python
  import sqlite3
  conn = sqlite3.connect('pokemon.db')
  cursor = conn.cursor()
  cursor.execute("SELECT * FROM Pokemon;")
  rows = cursor.fetchall()
  for row in rows:
      print(row)
  conn.close()
  ```

- **Foreign Key Relationships:**  
  Queries can join tables using foreign key relationships (e.g., `pokemon_id` → `variant_id`).

- **JSON Columns:**  
  Some columns (like `moves` in `CompetitiveSet`) store data as JSON strings. Your application should parse these fields after retrieving them.

---

## 5. Summary

The `pokemon.db` SQLite database is structured to provide a relational view of comprehensive Pokémon data. The schema includes tables for species, variants, evolution chains, competitive sets, and global data on abilities, items, moves, and natures. Relationships between tables are maintained via foreign keys, and complex data is stored as JSON text.

This documentation should serve as a guide for developers to understand the data layout, write queries, and integrate the database into applications.

Happy querying!

