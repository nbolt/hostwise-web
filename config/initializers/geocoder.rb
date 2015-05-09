Geocoder.configure(
  :lookup => :smarty_streets,
  :api_key => [ENV['STREETS_AUTH_ID'], ENV['STREETS_AUTH_TOKEN']]
)