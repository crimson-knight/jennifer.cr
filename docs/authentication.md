# Authentication

Authentication can be added simply by including the `Jennifer::Model::Authentication` module and the behavior can be customized using the `with_authentication` macro.

```crystal
# This is required to include the module.
require "jennifer/model/authentication"

class User < Jennifer::Model::Base
  # Include the authentication module for the authentication behavior we want.
  include Jennifer::Model::Authentication

  with_authentication

  # The following macro is included in this module by default, you can customize the attributes used for authentication by adjusting the parameters.
  # `password` is a string name representing the name of the attribute on the object that has a plain text representation of the password to hash. Default: `password`.
  # `password_hash` is a string name of the attribute that will compute the hashed password. Default: `password_digest`
  # `skip_validation` is a boolean value that determines if the validation should be skipped. Default: `false`, the validations will be run by default.
  # The `password_confirmation` attribute is generated as the `password` parameter here with `_confirmation` appended.
  with_authentication(password = "password", password_digest = "password_digest", skip_validation = false)

  mapping(
    id: Primary64,
    email: {type: String, default: ""},
    password_digest: {type: String, default: ""},
    password: Password, # Virtual field that is a type of `String?`, virtual: true, and setter: false. 
    password_confirmation: { type: String?, virtual: true }
  )

end
```

The `Password` class in the `password` field definition is a `Jennifer::Model::Authentication::Password` constant which includes definition for virtual password attribute.

Mapping automatically resolves it to its definition. This can only be used as `password: Password`.

For authentication `Crypto::Bcrypt::Password` is used. This mechanism requires you to have a `password_digest`, `password`, `password_confirmation` attributes defined in your mapping. This attribute can be customized - `with_authentication` macro accepts next arguments:

- `password` must be present on creation.
- `password` length should be less than or equal to 51 characters.
- If a `password_confirmation` attribute is defined, it will be used to validate the password.

If password confirmation validation is not needed, when this attribute has a nil value, the validation will not be triggered.

If you need additional validations, use normal model validations.

## Using Authentication

A simple `authenticate` method is added to the model which can be used to verify a user's password.

```crystal
# Create a new user
user = User.new(name: "david")
user.password = ""
user.password_confirmation = "nomatch"
user.save # => false, failed validationbecause password is required

user.password = "mUc3m00RsqyRe"
user.save # => false, failed validation because confirmation doesn't match
user.password_confirmation = 'mUc3m00RsqyRe'
user.save # => true
```

```crystal
# Assuming a user "David" who already has a password hashed as "mUc3m00RsqyRe"
User.all.where { _name == "david" }.first.try(&.authenticate("notright")) # Returns `nil` because the password is incorrect, even if the record exists.
User.all.where { _name == "david" }.first.try(&.authenticate("mUc3m00RsqyRe")) # => Returns the `User` object that was found and authenticated.
```
