# AppleTransparencyReport

Some software to parse the CSVs provided as part of [Apple's privacy transparency reports](https://www.apple.com/legal/transparency/).

It currently runs in a test suite, the sole target in the Xcode project, with some CocoaPods dependencies. Not all of the CSVs are currently processed, just the following:

- device_requests.csv
- financial_identifiers.csv
- account_requests.csv
- account_preservation_requests.csv

and for each country, aggregates:

- number of requests
- average number of items per request
- percentage of requests honored by Apple.

## Time periods

Each request type is broken down in two ways:

1. by country per time period, for each type of aggregation, along with the normalized distributions of the values
1. by country across all time periods, to construct historical series of values.
