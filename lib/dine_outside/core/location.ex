defmodule DineOutside.Core.Location do
  defstruct ~w[id applicant type description address status food_items lat lon approved]a

  def new(%{
        id: id,
        applicant: applicant,
        type: type,
        description: description,
        address: address,
        status: status,
        food_items: food_items,
        lat: lat,
        lon: lon,
        approved: approved
      }) do
    %__MODULE__{
      id: id,
      applicant: applicant,
      type: type,
      description: description,
      address: address,
      status: status,
      food_items: food_items,
      lat: lat |> ensure_float() |> String.to_float(),
      lon: lon |> ensure_float() |> String.to_float(),
      approved: approved
    }
  end

  def display_string(location) do
    "#{location.status}, #{location.type}, #{location.applicant}, #{location.address}, #{location.description}"
  end

  @doc """
  within_great_circle calculates whether an `anchor_coord` is within
  `meters` of a `Location` using the `Haversine` trigonometric function.
  The `anchor_coord` should include four decimal place precision to be useful
  for walking distance calculations (four decimal places represents an accuracy
  of approximately 11 meters).

  Candidate `anchor_coord` for San Francisco:
  * Mission District: {-122.4204, 37.7601}
  * Union Square:     {-122.4046, 37.7895}
  * Pacific Heights:  {-122.4346, 37.7932}
  * Presidio:         {-122.4662, 37.7985}
  * SFO University    {-122.4797, 37.7235}
  """
  def within_great_circle?({_longitude, _latitude} = anchor_coord, location, meters) do
    Haversine.distance(anchor_coord, {location.lon, location.lat}) <= meters
  end

  def within_great_circle?(_, _, _), do: false

  defp ensure_float("0" = _value), do: "0.0"
  defp ensure_float("" = _value), do: "0.0"
  defp ensure_float(value), do: value
end
