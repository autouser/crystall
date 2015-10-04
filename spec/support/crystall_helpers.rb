module CrystallHelpers

  def json
    @json ||= JSON.parse( response.body )
  end

end
