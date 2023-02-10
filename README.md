# lunch_repl
Code example using [peck/engineering-assessment](https://github.com/peck/engineering-assessment) as the prompt

## Tasks
- [x] Analyze mobile data for candidate features
    - [x] Define core data structure, `DineOutside.Core.Location` 
- [x] Implement `DataContainer` as VM singleton, `DineOutside.Boundary.DataContainer`
    - [x] Load data into `:ets` table `mobile_locations`
        - [x] Parse CSV into core data model
        - [x] Load once at startup--initially
            - [x] Allow reload using different CSV file
        - [x] Key is position `1`, `:id`
        - [x] Readable by all
        - [x] Query by `:id` 
- [x] Features, made available through `context` module, `DineOutside`
    - [x] Create `context` module
        - [x] Search by `type`
        - [x] Search by `food_item`
        - [x] Search by `distance`, as the crow flies (Haversine)
- [x] Test at `context` API for highest leverage
    - [x] Implement `DineOutsideTest`, no fixtures necessary (use sparse CSV files)

## Context and Instructions
Pretty much everything that I set out to do with Elixir results in quite a lot of learning. This exercise did not break the mold.

### Domain 
The prompt provides a CSV file that describes food trucks and carts around San Francisco.  It was surprising to find that so few of the vendors had a `status` of `APPROVED` or `ISSUED`.  Most were either `EXPIRED` or `REQUESTED`.  

* As a result the status and approved fields were not used to filter vendors on load, but rather all vendors in the file were included.

Most all trucks and carts had a latitude and longitude associated with them.  They also had a list of `food_items` that they provide.  Since the prompt left open what the features to be implemented should be, these fields plus a general sense of eating outside resulted in the following API in a Context module called `DiningOutside`.

* load_csv/1
* available_types/0
* search_by_type/1
* search_by_type_within_meters/3
* available_food_items/0
* search_by_food_item/1
* search_by_food_item_within_meters/3

### Shape of Implementation
Since the purpose of this repo is to discuss the implementation, the interface is the Elixir REPL, `iex`.  

The overall shape includes a `context` module that represents the API named `DineOutside`, a `core` module called `Location` that serves as the struct for the portion of the CSV that is retained and for functions that are closely associated with the `Location` module properties, and a `GenServer` boundary module in the form of a `DataContainer` that is backed by `:ets` and serves as a VM singleton to manage the CSV data.

### Instructions
This module can be cloned locally with:

```sh
git clone git@github.com:alanStrait/lunch_repl.git
```

The application runs under Elixir 1.14 and can be started with:

```sh
iex -S mix
```

This will start Elixir's REPL where you can exercise the `DineOutside` API with command such as:

```Elixir
DineOutside.load_csv("Mobile_Food_Facility_Permit.csv")

DineOutside.available_types()

DineOutside.search_by_type("Truck")

DineOutside.search_by_type_within_meters("Truck", {-122.4046, 37.7895}, 500)

DineOutside.available_food_items()

DineOutside.search_by_food_item("Vegan Pastries")

# Not found as great circle is not large enough
DineOutside.search_by_food_item_within_meters("Vegan Pastries", {-122.4046, 37.7895}, 5000)
# Vendor found with larger great circle
DineOutside.search_by_food_item_within_meters("Vegan Pastries", {-122.4046, 37.7895}, 15000)
```

### Automated Testing
The strategy for automated testing focuses on the `context` module by way of `DineOutsideTest`.  These tests exercise the core module well and serve as the highest leverage point for a maximizing the value of limited time spent on tests.

No fixtures were defined at this time since sparse CSV files were used for data.

## Notes About Possible Feature and Technical Backlog
* The `DataContainer` can be refactored to: include more or less metadata, move more data into :ets, move away from VM singleton and toward pooled workers for scale-out.  Could go a different direction altogether.
* More domain knowledge could be implemented based on available fields.
* A frontend could be supported.  Along the way I contemplated `escript`, Web frontend, LiveView single-page app, etc.
    * Certainly the `display_string` rendering useful for `REPL` is a convenience and needs to be replaced.
* The `:ets` query could be refactored to use `MatchSpect` with `select/2/3`.
