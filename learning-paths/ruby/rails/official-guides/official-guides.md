# Getting Started with Rails - Everything you need to know to install Rails and create your first application

- Rails Key Points
  - **Web Application Framework**: Written in Ruby, designed to simplify development.
  - **Efficiency**: Enables writing less code while achieving more.
  - **Opinionated Software**: Encourages a specific way of development, improving productivity but may frustrate those with external habits.
- Core Principles
  - **DRY (Don't Repeat Yourself)**: Avoids redundancy for better maintainability.
  - **Convention Over Configuration**: Uses sensible defaults to reduce setup effort.

# Create a New Rails app

## Directory Structure in a Rails App:

- **app/** – Main app code: models, views, controllers, helpers, mailers, jobs, assets.
- **bin/** – Scripts for running and managing the app.
- **config/** – Application configuration (routes, database, etc.).
- **config.ru** – Rack configuration for launching the app.
- **db/** – Database schema and migrations.
- **Dockerfile / .dockerignore** – Docker-related configuration.
- **Gemfile / Gemfile.lock** – Gem dependencies managed by Bundler.
- **lib/** – Custom modules and libraries.
- **log/** – Application logs.
- **public/** – Static files exposed by the server.
- **Rakefile** – Defines command-line tasks; custom tasks go in lib/tasks/.
- **README.md** – App documentation and setup instructions.
- **script/** – General purpose and one-off scripts.
- **storage/** – Active Storage files and SQLite databases.
- **test/** – Tests, fixtures, and test utilities.
- **tmp/** – Temporary files.
- **vendor/** – Third-party code and vendored gems.
- **.git/**, **.gitignore**, **.gitattributes**, **.github/** – Git and GitHub config.
- **.kamal/** – Kamal deployment and secrets.
- **.rubocop.yml** – RuboCop linting rules.
- **.ruby-version** – Specifies default Ruby version.

## MVC Basics (Model-View-Controller):

- **Model** – Manages application data (e.g., database tables).
- **View** – Renders output like HTML, JSON, etc.
- **Controller** – Handles user input and application logic.

![Rails_MVC_Architecture_Dark](https://github.com/user-attachments/assets/f4f00b65-91a4-4b20-97c2-51fc366ee374)

## Sample Rails project creation

- Creating a new Rails App called `store`:

```bash
$ rails new store
```

- Start up a web server called Puma that will serve static files and your Rails application:

```bash
$ bin/rails server
```

- Example of adding a database table to the Rails application to add products to the simple e-commerce store:

```bash
bin/rails generate model Product name:string
```

- Run the migration:

```bash
$ bin/rails db:migrate
```

- If you make a mistake, you can run the following to undo the last migration: `bin/rails db:rollback `.

> [!NOTE] Final source code
>
> Refer to the sample project's [source code](learning-paths/ruby/rails/official-guides/store) for the full implementations.

# Rails Console

The console is a helpful, interactive tool for testing our code in our Rails application.

```bash
$ bin/rails console
```

# Active Record Model Basics

## Creating Records
- `Product.new(name: "T-Shirt")`: Instantiates a new product (not yet saved).
- `product.save`: Saves the product to the database.
- `Product.create(name: "Pants")`: Creates and saves in one step.
- `id`, `created_at`, and `updated_at` are auto-populated after saving.

## Querying Records
- `Product.all`: Retrieves all product records from the database.
- Returns an `ActiveRecord::Relation`, which behaves like an array of model instances.

## Filtering & Ordering
- `Product.where(name: "Pants")`: Filters products by name.
- `Product.order(name: :asc)`: Sorts products by name (ascending).

## Finding Records
- `Product.find(1)`: Finds a product by ID.
- Returns a single `Product` instance, not a relation.

## Updating Records
- `product.update(name: "Shoes")`: Updates attributes and saves in one step.
- Or update manually:

```ruby
product.name = "T-Shirt"
product.save
```
## Deleting Records
`product.destroy`: Deletes the product from the database.

## Validations
Add validation in model:
```ruby
validates :name, presence: true
```

- Reloading Console: Run `reload!` in the console after modifying model code.
- Validation prevent saving invalid records. `product.errors.full_messages` gives readable error messages like "Name can't be blank".

## Rails Model Magic
- `app/models/product.rb` can be empty—Rails uses the database schema to auto-generate model attributes.
- `Product.column_names` returns detected columns: `["id", "name", "created_at", "updated_at"]`.

# Routes

![Rails_Routes_Dark](https://github.com/user-attachments/assets/490281eb-3b16-4ec1-be59-e8b4aada21f4)

A route maps an HTTP method and URL path to a controller/action, defined in `config/routes.rb`.

Example:
```ruby
get "/products", to: "products#index"
```
- Routes `GET /products` to `ProductsController#index`.

## ⚙️ Parameters in Routes

Use `:id` or `:title` to capture parts of the URL.
```ruby
get "/products/:id", to: "products#show"
get "/blog/:title", to: "blog#show"
```

## 🔧 CRUD Route Mapping

- **Index**: `GET /products`
- **New**: `GET /products/new`
- **Create**: `POST /products`
- **Show**: `GET /products/:id`
- **Edit**: `GET /products/:id/edit`
- **Update (PUT/PATCH)**: `PUT/PATCH /products/:id`
- **Destroy**: `DELETE /products/:id`

## ⏩ Resource Routes Shortcut

```ruby
resources :products
```
Generates all CRUD routes automatically.

## 🔍 Viewing All Routes

Use the command:
```bash
bin/rails routes
```
Displays all available routes and their corresponding controller/actions.
