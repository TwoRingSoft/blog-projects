//
//  Definitions.swift
//  AppleTransparencyReport-iOS
//
//  Created by Andrew McKnight on 1/5/19.
//  Copyright © 2019 Two Ring Software. All rights reserved.
//

import FastMath
import Pippin
import UIKit

typealias CsvUrlContentsMap = [CSVFile: String]

/// A mapping of unique keys to values.
typealias DataSet = [String: Double]

/// A mapping of unique keys to `DataSet`s, to collect data sets by time period, location, etc.
typealias DataSetMap = [String: DataSet]

typealias AllData = (requests: DataSet, ratios: DataSet, honoredPercentages: DataSet)

/// An ordered list of tuples with the `String` descriptions of the keys and values of a `DataSet`.
typealias CSVOutput = [(String, String)]

let size = 300
let fileManager = FileManager.default

enum CSVFile: String, CaseIterable {
    case devices = "device_requests.csv"
    case financialIDs = "financial_identifier_requests.csv"
    case accountPreservation = "account_preservation_requests.csv"
    case accountRequests = "account_requests.csv"
}

enum Column: Int {
    case timePeriod = 0
    case country = 3
    case requestCount = 4
    case totalItemCount = 5
    
    enum HonoredRequests: Int {
        case devicesAndFinancialIDs = 7
        
        enum Accounts: Int {
            case preservation = 6
            case restriction = 7
            case deletion = 8
            case info = 9
        }
    }
}

enum CSVOutputType: String, CaseIterable {
    case requestCounts
    case itemsPerRequest
    case percentRequestsHonored
}

enum CSVOutputFile: String {
    case requests = "Requests"
    case itemRatios = "Items Per Request"
    case honoredRequestPercentages = "Honored Request Percentage"
}

extension Bundle {
    /// Extract the entire contents of each CSV as one String and return each mapped to the filename in a Dictionary.
    func extractContentsFromCSVs() -> CsvUrlContentsMap {
        return CSVFile.allCases.reduce(into: [CSVFile: String](), { (result, path) in
            let components = path.rawValue.split(separator: ".")
            let csvURL = url(forResource: String(components.first!), withExtension: String(components.last!))!
            let contents = try! String(contentsOf: csvURL)
            result[path] = contents
        })
    }
}

extension String {
    /// For a string containing the contents of an Apple CSV, split it into a map of time period `String` descriptions to rows of `CSV` data.
    var csvByTimePeriod: [String: CSV] {
        return csv.reduce(into: [String: CSV](), { (result, row) in
            let timePeriod = row[Column.timePeriod.rawValue]
            if nil == result[timePeriod] {
                result[timePeriod] = [row]
            } else {
                result[timePeriod]!.append(row)
            }
        })
    }
}

/// Given the contents of a given CSV file, extract the data sets of interest, each as a map of country names to the target value.
func extractDataSets(rows: CSV, csv: CSVFile) -> AllData {
    var requestsReceived = DataSet()
    var requestItemRatios = DataSet()
    var honoredRequestRatios = DataSet()
    
    rows.forEach({ (rowColumns) in
        let country = rowColumns[Column.country.rawValue]
        let requestAmount = rowColumns[Column.requestCount.rawValue].doubleValue
        let itemsRequested = rowColumns[Column.totalItemCount.rawValue].doubleValue
        requestsReceived[country] = requestAmount
        let itemRatio = itemsRequested / requestAmount
        requestItemRatios[country] = itemRatio
        let honoredRatio = honoredRequestRatio(csv: csv, rowColumns: rowColumns, requestAmount: requestAmount)
        honoredRequestRatios[country] = honoredRatio
    })
    
    return (requestsReceived, requestItemRatios, honoredRequestRatios)
}

/// - Parameter requestAmount: since account preservation reports only provide the amount of requests honored while the others provide the percentage, we must calculate its percentage, which requires knowing how many requests were submitted.
/// - Returns: the value of the percentage of honored requests, either pulled from the correct column or computed from various other columns, depending on which CSV is being read as it is in different columns between the set of them.
func honoredRequestRatio(csv: CSVFile, rowColumns: CSVRow, requestAmount: Double) -> Double {
    let honoredRequestRatio: Double
    switch csv {
    case .devices, .financialIDs:
        honoredRequestRatio = rowColumns[Column.HonoredRequests.devicesAndFinancialIDs.rawValue].doubleValue
    case .accountRequests:
        honoredRequestRatio = rowColumns[Column.HonoredRequests.Accounts.info.rawValue].doubleValue
    case .accountPreservation:
        let value = rowColumns[Column.HonoredRequests.Accounts.preservation.rawValue].doubleValue
        honoredRequestRatio = value / requestAmount
    }
    return honoredRequestRatio
}

/// Given an array of keys and a data set as a map of keys to values, return an array of tuples `(a, b)` where `a` is each key and `b` the associated value
func topSortedCSV(topSortedKeys: [String], dataSet: DataSet) -> CSVOutput {
    return topSortedKeys.reduce(into: CSVOutput(), { (result, next) in
        result.append((next, String(describing: dataSet[next]!)))
    })
}

/// Write the chart data to a CSV file.
func write(chartData: CSVOutput, directory: URL, name: String, headerString: String) {
    let csvURL = directory.appendingPathComponent(name)
    let csvString = headerString + "\n" + chartData.map({ (keyValuePair) -> String in
        return "\(keyValuePair.0), \(keyValuePair.1)"
    }).joined(separator: "\n")
    fileManager.createFile(atPath: csvURL.path, contents: csvString.data(using: .utf8), attributes: nil)
}

/// Write a map of time series data into a new directory of files for each time series, where the key to which it's mapped is the filename.
func write(timeSeries: DataSetMap, csv: CSVFile, directory: URL, name: String, sortedCountries: [String]) {
    // build a csv that maps time period to a list of values, one for each country sorted by name, default to 0 to fill in empty data for countries that aren't found in a particular csv or time period
    let chartData = timeSeries.reduce(into: [(String, String)](), { (result, timePeriodRequests) in
        result.append((timePeriodRequests.key, sortedCountries.map({ (country) -> String in
            if let value = timePeriodRequests.value[country] {
                return String(describing: value)
            } else {
                return "0"
            }
        }).joined(separator: ",")))
    }).sorted { (a, b) -> Bool in
        return a.0.compare(b.0) == .orderedAscending
    }
    let headers = "Time Period,\(sortedCountries.joined(separator: ","))"
    write(chartData: chartData, directory: directory, name: name, headerString: headers)
}

/// For a `Dictionary` with values of `Dictionary` type, given a key to access a `Dictionary` and a key and value to insert into the inner `Dictionary`, perform the check to see if the inner dictionary exists yet; if so, sets the value to the key inside it, otherwise creates a new `Dictionary` instance with the key and value.
func createOrInsertIntoNestedCollection(key: String, dictionary: inout DataSetMap, innerKey: String, innerValue: Double) {
    if nil == dictionary[key] {
        dictionary[key] = [innerKey: innerValue]
    } else {
        dictionary[key]![innerKey] = innerValue
    }
}
