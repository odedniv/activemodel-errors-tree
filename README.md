# ActiveModel::Errors::Tree

Did you too search Google for a way to encode your Rails errors in your API?
Well you probably encountered an awful response like this:

```ruby
render json: { errors: @record.errors.messages }, status: :unprocessable_entity
```

**This is not a good mechanism.**

Why? Let's say you have a model with associations. The way ActiveRecord encodes
`errors.messages` is this:

```ruby
{ :field => ["can't be blank"], :"association.field" => ["must be less than 5"] }
```

Let's say you developed a great client side implementation to figure out
`"association.field"` is actually an error on the association model. What
happens when it's a one-to-many association?

```ruby
{ :field => ["can't be blank"], :"associations.field" => ["must be less than 5"] }
```

What?! How are you supposed to know which instance of `associations` received
the error? How do you mark the correct textbox in red?

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activemodel-errors-tree'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activemodel-errors-tree

## Usage

By calling `@record.errors.tree` you get a much prettier picture, that is easier
to decode on the client side.

Following the examples above:

### One-to-one

```ruby
@record.errors.tree.messages
# This is actually a ActiveSupport::HashWithIndifferentAccess
=> { field: ["can't be blank"], association: { field: ["must be less than 5"] } }
```

### One-to-many

```ruby
@record.errors.tree.messages
# Assuming the error is on the second association out of three.
=> { field: ["can't be blank"], associations: [{}, { field: ["must be less than 5"] }, {}] }
```

Now your client can iterate over the association's errors along with rendering
the associations, and render out each association's errors.

### errors.details (the recommended way)

If you use Rails 5 or include the `active_model-errors_details` gem, you can use
`@record.errors.tree.details` instead of `messages`. This is more API friendly
since it let's your client decide on the actual messages.

```ruby
@record.errors.tree.details
# Assuming the error is on the second association out of three.
=> { field: [{ error: :blank }], associations: [{}, { field: [{ error: :less_than, count: 5 }] }, {}] }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/odedniv/activemodel-errors-tree. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

