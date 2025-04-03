# Getting Started with Rails

- Rails Key Points
  - **Web Application Framework**: Written in Ruby, designed to simplify development.
  - **Efficiency**: Enables writing less code while achieving more.
  - **Opinionated Software**: Encourages a specific way of development, improving productivity but may frustrate those with external habits.
- Core Principles
  - **DRY (Don't Repeat Yourself)**: Avoids redundancy for better maintainability.
  - **Convention Over Configuration**: Uses sensible defaults to reduce setup effort.

# Active Record Basics

## Overview
- Part of the **Model** in MVC, handling data representation and business logic.
- Allows Ruby objects to persist data in a database.

## Active Record vs. Active Model
- **Active Record**: Works with database-backed models.
- **Active Model**: Used for non-database-backed Ruby objects.

## Active Record Pattern
- Defined as an **object that wraps a database row**, encapsulating access and logic.
- Provides a direct mapping between Ruby objects and database records.

## Object Relational Mapping (ORM)
- Connects objects in Ruby to relational database tables.
- Simplifies database interactions by avoiding raw SQL.

## Active Record as an ORM Framework
- Enables:
  - Defining models and their attributes.
  - Managing **associations** between models.
  - Supporting **inheritance hierarchies**.
  - Validating data before saving.
  - Performing database operations in an object-oriented way.

## Naming Conventions
- **Model-to-Table Mapping**:
  - Model class names are **singular and in UpperCamelCase** (e.g., `BookClub`).
  - Corresponding database table names are **plural and in snake_case** (e.g., `book_clubs`).
- **Examples**:
  - `Article` → `articles`
  - `LineItem` → `line_items`
  - `Person` → `people` (handles irregular pluralization).
- Uses **[Active Support pluralization](https://api.rubyonrails.org/v8.0.2/classes/ActiveSupport/Inflector.html#method-i-pluralize)** for handling singular/plural transformations.

## Schema Conventions

**Primary & Foreign Keys**
- **Primary Key**:
  - Default is an `id` column (bigint for PostgreSQL/MySQL, integer for SQLite).
- **Foreign Key Naming**:
  - Follows the pattern: `singularized_table_name_id` (e.g., `order_id`, `line_item_id`).

**Special Column Names**
- **Timestamps**:
  - `created_at` → Auto-set when record is created.
  - `updated_at` → Auto-set when record is updated.
- **Locking & Inheritance**:
  - `lock_version` → Enables optimistic locking.
  - `type` → Used for **Single Table Inheritance (STI)** (avoid using this name unless needed).
- **Polymorphic & Caching Columns**:
  - `(association_name)_type` → Stores type for **polymorphic associations**.
  - `(table_name)_count` → Caches count of associated records (e.g., `comments_count`).

💡 **Avoid reserved keywords like `type` unless using STI. Use descriptive column names instead.**

## Active Record & Models

- ApplicationRecord is the base class for all Active Record models in a Rails app.
- It inherits from `ActiveRecord::Base`, turning a Ruby class into an Active Record model.
- To create a new model, subclass `ApplicationRecord`.

```ruby
class Book < ApplicationRecord
end
```

## Creating Database Tables

Database tables are usually created using `Active Record Migrations` instead of raw SQL.

```bash
$ bin/rails generate migration CreateBooks title:string author:string
```

Migration file example

```ruby
class CreateBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.string :title
      t.string :author
      t.timestamps
    end
  end
end
```

## Working with Active Record Models

- A new `Book` instance can represent a row in the books table.
- Attributes like `id`, `title`, `author`, `created_at`, and `updated_at` are accessible on the model instance.

```ruby
book = Book.new
book.title = "The Hobbit"
book.title
# => "The Hobbit"
```

## Namespaced Models

- Models can be organized into namespaces by placing them under subfolders in app/models.
- Example: `Book::Order` and `Book::Review` under `app/models/book`.
- To create a namespaced model, run:

```bash
$ bin/rails generate model Book::Order
```

- If the `Book` module exists, the generate command will create files for the namespaced model without overwriting the `Book` model.
- The `table_name_prefix` can be set in the Book module to define the table name for the namespaced model:

```ruby
module Book
  def self.table_name_prefix
    "book_"
  end
end
```

- Resulting table name for `Book::Order` will be `book_orders`.

## Customizing Naming Conventions

You can override the default table name by using `self.table_name` in your model. Example:

```ruby
class Book < ApplicationRecord
  self.table_name = "my_books"
end
```

When using custom table names, specify the correct fixtures in tests using `set_fixture_class`. Example:

```ruby
class BookTest < ActiveSupport::TestCase
  set_fixture_class my_books: Book
  fixtures :my_books
end
```

## Custom Primary Keys

You can also override the primary key by using `self.primary_key`. Example:

```ruby
class Book < ApplicationRecord
  self.primary_key = "book_id"
end
```

Active Record doesn't recommend using a non-primary key column named id. If you try to define a column named id that's not the primary key, Rails will raise an error during migrations. To avoid this, use `{ id: false }` when creating the table.

## CRUD Operations in Active Record

Active Record provides methods to perform CRUD (Create, Read, Update, Delete) operations on database records. These methods abstract the database interactions, making it easier to work with data in a Ruby application.

- **Create**: Creates and saves an object to the database in one step. Example:
```ruby
book = Book.create(title: "The Lord of the Rings", author: "J.R.R. Tolkien")
```

- **New**: Creates an unsaved object. Save the object later using save. Example:
```ruby
book = Book.new(title: "The Hobbit", author: "J.R.R. Tolkien")
book.save
```

- **Read**:
  - **all**: Retrieves all records from the table. Example: ```books = Book.all```
  - **first, last, take**: Retrieve the first, last, or one random record. Example: ```first_book = Book.first```
  - **find_by**: Find a record by a specific attribute. Example: ```book = Book.find_by(title: "Metaprogramming Ruby 2")```
  - **where**: Retrieve records that match a condition. Example: ```books = Book.where(author: "Douglas Adams")```

- **Update**: Modify an attribute of an object and save the changes. Example:
```ruby
book = Book.find_by(title: "The Lord of the Rings")
book.update(title: "The Lord of the Rings: The Fellowship of the Ring")
```

- Use update_all to update multiple records in bulk without callbacks or validations. Example: ```Book.update_all(status: "already own")```

- **Delete**:
  - **destroy**: Removes a specific record from the database. Example:
    ```ruby
    book = Book.find_by(title: "The Lord of the Rings")
    book.destroy
    ```
  - **destroy_all**: Deletes all records in the table. Example: ```Book.destroy_all```
