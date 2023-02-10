defmodule DineOutside do
  @moduledoc """
  Documentation for `DineOutside`.
  """
  alias DineOutside.Boundary.DataContainer
  alias DineOutside.Core.Location

  @doc """
  load_csv/1 takes the name of a CSV file that can be found in the
  `priv` directory.  A different CSV file can be loaded subsequenty
  but the data replaces any prior loaded data.
  """
  def load_csv(csv_file_name) do
    DataContainer.load_csv(csv_file_name)
  end

  @doc """
  search_by_type/1 returns display strings of `Location` data that
  describes vendors of the identified type.  For candidate
  types, use `available_types/0`.
  """
  def search_by_type(type) do
    DataContainer.locations_for_type(type)
    |> locations_for()
    |> Enum.map(&Location.display_string(&1))
  end

  @doc """
  search_by_type_within_meters/3 returns vendor `Location` data of that
  type that is found to be within `meters` of the provided `anchor_coord`.
  `anchor_coord` is a tuple formmated as `{longitude, latitude}`.
  """
  def search_by_type_within_meters(type, anchor_coord, meters) do
    DataContainer.locations_for_type(type)
    |> locations_for()
    |> Enum.filter(&Location.within_great_circle?(anchor_coord, &1, meters))
    |> Enum.map(&Location.display_string(&1))
  end

  @doc """
  search_by_food_item/1 returns display strings of vendor `Location` data
  that serves the identified `food_item`s.  For candidate `food_items`,
  use `available_food_items/0`.
  """
  def search_by_food_item(food_item) do
    DataContainer.locations_for_food_item(food_item)
    |> locations_for()
    |> Enum.map(&Location.display_string(&1))
  end

  @doc """
  search_by_food_item_within_meters/3 returns vendor `Location` data for vendors
  that serve that `food_item` within `meters` of the provided `anchor_coord`.
  `anchor_coord` is a tuple formmated as `{longitude, latitude}`.
  """
  def search_by_food_item_within_meters(food_item, anchor_coord, meters) do
    DataContainer.locations_for_food_item(food_item)
    |> locations_for()
    |> Enum.filter(&Location.within_great_circle?(anchor_coord, &1, meters))
    |> Enum.map(&Location.display_string(&1))
  end

  @doc """
  available_types/0 returns all vendor types loaded.
  """
  def available_types() do
    DataContainer.available_types()
  end

  @doc """
  available_food_items/0 returns all vendor food items identified in a colon
  delimited string in the vendor data.
  """
  def available_food_items() do
    DataContainer.available_food_items()
  end

  defp locations_for(ids) do
    ids
    |> Enum.map(&:ets.lookup(DataContainer.ets_table_name(), &1))
    |> Enum.map(fn [{_k, v} | _] -> v end)
  end
end
