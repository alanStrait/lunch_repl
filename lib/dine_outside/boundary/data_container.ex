defmodule DineOutside.Boundary.DataContainer do
  @moduledoc """
  DataContainer is a singleton `GenServer` that retains lists of
  `DineOutside.Core.Location` ids associated with location
  type, and food_items, as part of processing an identified CSV
  file to an `:ets` table.
  """
  use GenServer
  alias DineOutside.Core.Location
  alias NimbleCSV.RFC4180

  defstruct csv_file_name: nil,
            locs_by_type: %{},
            locs_by_food_item: %{},
            loaded?: false

  @data_dir Path.join(File.cwd!(), "/priv")
  @ets_table_name :mobile_locations

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  ## CLIENT
  def ets_table_name(), do: @ets_table_name

  def available_food_items() do
    GenServer.call(__MODULE__, :available_food_items)
  end

  def available_types() do
    GenServer.call(__MODULE__, :available_types)
  end

  def load_csv(file_name) do
    GenServer.call(__MODULE__, {:load_csv, file_name})
  end

  def locations_for_food_item(food_item) do
    GenServer.call(__MODULE__, {:for_food_item, food_item})
  end

  def locations_for_type(type) do
    GenServer.call(__MODULE__, {:for_type, type})
  end

  ## SERVER Callbacks
  @impl true
  def init(_args) do
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_call(:available_food_items, _, state) do
    {:reply, Map.keys(state.locs_by_food_item), state}
  end

  @impl true
  def handle_call(:available_types, _, state) do
    {:reply, Map.keys(state.locs_by_type), state}
  end

  @impl true
  def handle_call({:for_type, type}, _, state) do
    {:reply, Map.get(state.locs_by_type, type, []), state}
  end

  def handle_call({:for_food_item, food_item}, _, state) do
    {:reply, Map.get(state.locs_by_food_item, food_item, []), state}
  end

  @impl true
  def handle_call({:load_csv, file_name}, _, state) do
    path = Path.join(@data_dir, file_name)

    {status, state} =
      cond do
        state.loaded? and file_name == state.csv_file_name ->
          {:already_loaded, state}

        not File.exists?(path) ->
          {:file_does_not_exist, state}

        true ->
          load_mobile_locations(path, state)
      end

    {:reply, status, state}
  end

  def load_mobile_locations(path, state) do
    init_mobile_locations()

    with locations = collect_locations(path),
         {:ok, state} <- collect_locs_by_type(locations, state),
         {:ok, state} <- collect_locs_by_food_item(locations, state),
         :ok <- load_ets(locations) do
      {:ok, %{state | loaded?: true, csv_file_name: Path.basename(path)}}
    else
      _ -> {:error, %__MODULE__{}}
    end
  end

  def collect_locations(path) do
    path
    |> File.stream!()
    |> RFC4180.parse_stream()
    |> Stream.map(fn [
                       id,
                       applicant,
                       type,
                       _,
                       description,
                       address,
                       _,
                       _,
                       _,
                       _,
                       status,
                       food_items,
                       _,
                       _,
                       lat,
                       lon,
                       _,
                       _,
                       _,
                       approved | _rest
                     ] ->
      %{
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
      }
    end)
    |> Enum.map(&Location.new(&1))
  end

  defp collect_locs_by_type(locations, state) do
    locs_by_type =
      locations
      |> Enum.reduce(%{}, fn location, acc_map ->
        set = Map.get(acc_map, location.type, MapSet.new())
        Map.put(acc_map, location.type, MapSet.put(set, location.id))
      end)
      |> Enum.map(fn {k, v_set} -> {k, MapSet.to_list(v_set)} end)
      |> Map.new()

    {:ok, %{state | locs_by_type: locs_by_type}}
  end

  defp collect_locs_by_food_item(locations, state) do
    locs_by_food_item =
      locations
      |> Enum.reduce(%{}, fn location, acc_map ->
        words =
          String.split(location.food_items, ":")
          |> Enum.map(&String.trim(&1))

        Map.put(acc_map, location.id, words)
      end)
      |> Enum.reduce(%{}, fn {k, v_list}, acc_map ->
        v_list
        |> Enum.reduce(acc_map, fn word, acc_map_2 ->
          set = Map.get(acc_map_2, word, MapSet.new())
          Map.put(acc_map_2, word, MapSet.put(set, k))
        end)
      end)
      |> Enum.map(fn {k, v_set} -> {k, MapSet.to_list(v_set)} end)
      |> Map.new()

    {:ok, %{state | locs_by_food_item: locs_by_food_item}}
  end

  defp init_mobile_locations() do
    case :ets.whereis(@ets_table_name) do
      :undefined ->
        :ets.new(@ets_table_name, [:named_table, :public, :set, keypos: 1])

      _ ->
        :ets.delete_all_objects(@ets_table_name)
    end
  end

  defp load_ets(locations) do
    Enum.each(locations, &:ets.insert(@ets_table_name, {&1.id, &1}))
  end
end
