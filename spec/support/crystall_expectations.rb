RSpec::Matchers.define :have_one_error do |field, error|

  match do |target|

    if target.invalid?
      field_error = target.errors.get(field)
      return target.errors.size == 1 &&
        field_error.size == 1 &&
        field_error[0] == error
    else
      return false
    end

  end

  description do
    "have one error \"#{field} #{error}\""
  end

end

RSpec::Matchers.define :have_field_with_value do |field, value|

  match do |target|
    target.respond_to?(field) &&
    target.send(field) == value
  end

  description do
    "have field \"#{field}\" with value \"#{value}\""
  end

end