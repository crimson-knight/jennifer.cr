# Migration

## DSL

Generator will create template file for you with next name  pattern "timestamp_your_underscored_migration_name.cr". Empty file looks like this:

```crystal
class YourCamelCasedMigrationName < Jennifer::Migration::Base
  # This is the method that will be executed when the migration is run.
  def up
  end

  # This is the method that will be executed when the migration is reverted.
  def down
  end
end
```

Regular example for creating table:

```crystal
class YourCamelCasedMigrationName < Jennifer::Migration::Base
  def up
    create_table(:addresses) do |t|
      # Creates field contact_id with Int type, allows null values and creates foreign key
      t.reference :contact

      # Creates a polymorphic relation
      t.reference :attachable, { :polymorphic => true }

      # Creates string field with CHAR(20) db type
      t.string :street, {:size => 20, :sql_type => "char"}

      # Sets false as default value
      t.bool :main, {:default => false}
    end
  end

  def down
    drop_table(:addresses)
  end
end
```

There are next methods which presents corresponding types:

| Method | PostgreSQL | MySql | Crystal type |
| --- | --- | --- | --- |
| `#integer` | `int` | `int` | `Int32` |
| `#short` | `SMALLINT` | `SMALLINT` | `Int16` |
| `#bigint` | `BIGINT` | `BIGINT` | `Int64` |
| `#tinyint` | - | `TINYINT` | `Int8` |
| `#float` | `real` | `float` | `Float32` |
| `#double` | `double precision` | `double` | `Float64` |
| `#numeric` | `NUMERIC` | - | `PG::Numeric` |
| `#decimal` | `DECIMAL` | `DECIMAL` | `PG::Numeric` (pg); `Float64` (mysql) |
| `#string` | `varchar(254)` | `varchar(254)` | `String` |
| `#char` | `char` | - | `String` |
| `#text` | `TEXT` | `TEXT` | `String` |
| `#bool` | `boolean` | `bool` | `Bool` |
| `#timestamp` | `timestamp` | `datetime` | `Time` |
| `#date_time` | `timestamp` | `datetime` | `Time` |
| `#date` | `date` | `date` | `Time` |
| `#blob` | `blob` | `blob` | `Bytes` |
| `#json` | `json` | `json` | `JSON::Any` |
| `#enum` | - | `ENUM` | `String` |

In Postgres enum type is defined using custom user datatype which also is mapped to the `String`.

PostgreSQL specific datatypes:

| Method | Datatype | Type |
| --- | --- | --- |
| `#oid` | `OID` | `UInt32` |
| `#jsonb` | `JSONB` | `JSON::Any` |
| `#xml` | `XML` | `String` |
| `#blchar` | `BLCHAR` | `String` |
| `#uuid` | `UUID` | `UUID` |
| `#timestampz` | `TIMESTAMPZ` | `Time` |
| `#point` | `POINT` | `PG::Geo::Point` |
| `#lseg` | `lseg` | `PG::Geo::LineSegment` |
| `#path` | `PATH` | `PG::Geo::Path` |
| `#box` | `BOX` | `PG::Geo::Box` |
| `#polygon` | `POLYGON` | `PG::Geo::Polygon` |
| `#line` | `LINE` | `PG::Geo::Line` |
| `#circle` | `CIRCLE` | `PG::Geo::Circle` |

Also if you use postgres array types are available as well: `Array(Int32)`, `Array(Char)`, `Array(Float32)`,  `Array(Float64)`, `Array(Int16)`, `Array(Int32)`, `Array(Int64)`, `Array(String)`, `Array(Time)`, `Array(UUID)`. Currently only plain (1 dimensional) arrays are supported. Also take into account that to be able to use `Array(String)` you need to use `text :my_column, {:array => true}` in your migration.

All those methods accepts additional options:

- `:sql_type` - gets exact (except size) field type;
- `:null` - present nullable if field (by default is `false` for all types and field);
- `:primary` - marks field as primary key field (could be several ones but this provides some bugs with query generation for such model - for now try to avoid this).
- `:default` - default value for field
- `:auto_increment` - marks field to use auto increment (works only with `Int32 | Int64` fields).
- `:array` - mark field to be array type (postgres only)

Also there is `#field` method which allows to directly define SQL type.

```crystal
class YourCamelCasedMigrationName < Jennifer::Migration::Base
  def up
    # Creates a PostgreSQL enum type
    create_enum :gender_enum, %w(unspecified female male)

    create_table :users do |t|
      t.field :gender, :gender_enum
    end
  end

  def down
    drop_table :users
    drop_enum :gender_enum
  end
end
```

To define reference to other table you can use `#reference`:


To drop table just write:

```crystal
drop_table(:addresses)
```

To create materialized view (postgres only):
```crystal
create_materialized_view("female_contacts", Contact.all.where { _gender == "female" })
```

And to drop it:

```crystal
drop_materialized_view("female_contacts")
```

To alter existing table use next methods:

 - `#change_column` - to change column definition;
 - `#add_column` - adds new column;
 - `#drop_column` - drops existing column;
 - `#add_index` - adds new index;
 - `#drop_index` - drops existing index;
 - `#add_foreign_key` - adds foreign key constraint;
 - `drop_foreign_key` - drops foreign key constraint;
 - `#rename_table` - renames table.

 For more details about this and other methods see [`Jennifer::Migration::TableBuilder::CreateTable`](https://imdrasil.github.io/jennifer.cr/latest/Jennifer/Migration/TableBuilder/ChangeTable.html)

Also next support methods are available:

- `#table_exists?`
- `#index_exists?`
- `#column_exists?`
- `#foreign_key_exists?`
- `#enum_exists?` (for postgres ENUM only)
- `#material_view_exists?`

Here is a quick example:

```crystal
def up
  change_table(:contacts) do |t|
    t.change_column(:age, :short, {:default => 0})
    t.add_column(:description, :text)
    t.add_index(:description, type: :uniq, order: :asc)
  end

  change_table(:addresses) do |t|
    t.add_column(:details, :json)
  end
end

def down
  change_table(:contacts) do |t|
    t.change_column(:age, :integer, {:default => 0})
    t.drop_column(:description)
  end

  change_table(:addresses) do |t|
    t.drop_column(:details)
  end
end
```

Also plain SQL could be executed as well:

```crystal
exec("ALTER TABLE addresses CHANGE street st VARCHAR(20)")
```

All changes are executed one by one so you also could add data changes here (in `#up` and/or `#down`).

#### Enum

Now enums are supported as well but each adapter has itsown implementation. For mysql is enough just write down all values:

```crystal
create_table(:contacts) do |t|
  t.enum(:gender, ["male", "female"]) # Creates the enum type and the field
end
```

Postgres provides much more flexible and complex behavior. Using it you need to create enum first:

```crystal
create_enum(:gender_enum, ["male", "female"])

create_table(:contacts) do |t|
  t.string :name, {:size => 30}
  t.integer :age
  t.field :gender, :gender_enum
  t.timestamps
end

change_enum(:gender_enum, {:add_values => ["unknown"]})
change_enum(:gender_enum, {:rename_values => ["unknown", "other"]})
change_enum(:gender_enum, {:remove_values => ["other"]})
```
