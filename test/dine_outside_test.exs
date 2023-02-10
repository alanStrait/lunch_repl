defmodule DineOutsideTest do
  use ExUnit.Case, async: false

  describe "load_csv/1" do
    test "will correctly load csv file" do
      assert :ok = DineOutside.load_csv("mobile_food_test_1.csv")

      assert food_item_list = DineOutside.available_food_items()

      info = :ets.info(DineOutside.Boundary.DataContainer.ets_table_name())
      assert Keyword.fetch!(info, :size) == 9
      refute Enum.empty?(food_item_list)
      assert eventually_match(food_item_list, "Vegan Hot Dogs")

      assert type_list = DineOutside.available_types()
      refute Enum.empty?(type_list)
      assert eventually_match(type_list, "Truck")
      assert eventually_match(type_list, "Push Cart")
    end

    test "will not load file already loaded" do
      assert :ok = DineOutside.load_csv("mobile_food_test_2.csv")
      assert :already_loaded = DineOutside.load_csv("mobile_food_test_2.csv")

      info = :ets.info(DineOutside.Boundary.DataContainer.ets_table_name())

      assert Keyword.fetch!(info, :size) == 7
    end

    test "load empty file" do
      assert :ok = DineOutside.load_csv("mobile_food_test_empty.csv")

      info = :ets.info(DineOutside.Boundary.DataContainer.ets_table_name())
      assert Keyword.fetch!(info, :size) == 0
    end
  end

  describe "search_by_.../n" do
    setup context do
      DineOutside.load_csv("mobile_food_test_1.csv")

      context
    end

    test "search_by_type/1" do
      assert location_strings = DineOutside.search_by_type("Truck")
      assert not Enum.empty?(location_strings)
      refute eventually_match(location_strings, "Datam SF LLC")
      assert eventually_match(location_strings, "Casita Vegana")
    end

    test "search_by_type_within_meters/3" do
      assert location_strings =
               DineOutside.search_by_type_within_meters("Truck", {-122.4046, 37.7895}, 500)

      refute eventually_match(location_strings, "ELLIS ST")
      assert eventually_match(location_strings, "BUSH ST")

      assert location_strings =
               DineOutside.search_by_type_within_meters("Truck", {-122.4046, 37.7895}, 1000)

      assert eventually_match(location_strings, "ELLIS ST")
      assert eventually_match(location_strings, "BUSH ST")
    end

    test "search_by_food_item/1" do
      assert location_strings = DineOutside.search_by_food_item("Vegan Pastries")
      assert eventually_match(location_strings, "Casita Vegana")
    end

    test "search_by_food_item_within_meters/3" do
      assert location_strings =
               DineOutside.search_by_food_item_within_meters(
                 "Vegan Pastries",
                 {-122.4046, 37.7895},
                 5_000
               )

      assert Enum.empty?(location_strings)

      assert location_strings =
               DineOutside.search_by_food_item_within_meters(
                 "Vegan Pastries",
                 {-122.4046, 37.7895},
                 15_000
               )

      refute Enum.empty?(location_strings)
      assert eventually_match(location_strings, "Casita Vegana")
    end
  end

  def eventually_match(item_list, answer) do
    items =
      item_list
      |> Enum.filter(fn item -> item =~ answer end)

    not Enum.empty?(items)
  end
end
