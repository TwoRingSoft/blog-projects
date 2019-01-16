//
//  AppleTransparencyReport.swift
//  AppleTransparencyReport
//
//  Created by Andrew McKnight on 1/9/19.
//  Copyright © 2019 Two Ring Software. All rights reserved.
//

import Pippin
import XCTest

class AppleTransparencyReport: XCTestCase {
    
    private let fileManager = FileManager.default
    private let baseURL = URL(fileURLWithPath: "/Users/andrew/Documents/AppleTransparencyReport")
    
    func testReport() {
        if fileManager.fileExists(atPath: baseURL.path) {
            try! fileManager.removeItem(at: baseURL)
        }
        try! fileManager.createDirectory(at: baseURL, withIntermediateDirectories: false, attributes: nil)
        
        Bundle(for: AppleTransparencyReport.self).extractContentsFromCSVs().forEach { (reportNameAndContents) in
            let (csv, contents) = reportNameAndContents
            
            // for each time period, output data sets mapping countries to various stats, and build mappings of time periods to those data sets for later timeseries analysis
            var countries = Set<String>()
            var requestCountsOverTime = DataSetMap()
            var itemCountsOverTime = DataSetMap()
            var itemRatiosOverTime = DataSetMap()
            var honoredRequestCountsOverTime = DataSetMap()
            var honoredPercentagesOverTime = DataSetMap()
            contents.csvByTimePeriod.forEach({ (keyValuePair) in
                let (timePeriod, rows) = keyValuePair
                
                // aggregate necessary data points
                let data = extractDataSets(rows: rows, csv: csv)
                requestCountsOverTime[timePeriod] = data.requests
                itemCountsOverTime[timePeriod] = data.items
                itemRatiosOverTime[timePeriod] = data.ratios
                honoredRequestCountsOverTime[timePeriod] = data.honoredRequests
                honoredPercentagesOverTime[timePeriod] = data.honoredPercentages
                data.requests.keys.forEach { countries.insert($0) }
                
                // write reports for each time period
                let timePeriodDirectory = baseURL
                    .appendingPathComponent("Time Periods")
                    .appendingPathComponent(timePeriod)
                    .appendingPathComponent(csv.rawValue.replacingOccurrences(of: ".csv", with: ""))
                try! fileManager.createDirectory(at: timePeriodDirectory, withIntermediateDirectories: true, attributes: nil)
                
                let topCountriesByRequestCount = data.requests.keysSortedByValue(maxCount: 10, ascending: false)
                
                // requests
                let topRequests = topSortedCSV(topSortedKeys: topCountriesByRequestCount, dataSet: data.requests)
                write(chartData: topRequests, directory: timePeriodDirectory, csvFile: .topRequests, headerString: "Country,\(CSVOutputFile.topRequests.rawValue)")
                
                // item counts
                let topItemCounts = topSortedCSV(topSortedKeys: data.items.keysSortedByValue(maxCount: 10, ascending: false), dataSet: data.items)
                write(chartData: topItemCounts, directory: timePeriodDirectory, csvFile: .topItemCounts, headerString: "Country,\(CSVOutputFile.topItemCounts.rawValue)")
                
                let topItemCountsByRequests = topSortedCSV(topSortedKeys: topCountriesByRequestCount, dataSet: data.items)
                write(chartData: topItemCountsByRequests, directory: timePeriodDirectory, csvFile: .topItemCountsByRequests, headerString: "Country,\(CSVOutputFile.topItemCountsByRequests.rawValue)")
                
                // items per request
                let topRatios = topSortedCSV(topSortedKeys: data.ratios.keysSortedByValue(maxCount: 10, ascending: false), dataSet: data.ratios)
                write(chartData: topRatios, directory: timePeriodDirectory, csvFile: .topItemRatios, headerString: "Country,\(CSVOutputFile.topItemRatios.rawValue)")
                
                let topRatiosByRequests = topSortedCSV(topSortedKeys: topCountriesByRequestCount, dataSet: data.ratios)
                write(chartData: topRatiosByRequests, directory: timePeriodDirectory, csvFile: .topRatiosByRequests, headerString: "Country,\(CSVOutputFile.topRatiosByRequests.rawValue)")
                
                // honored request counts
                let topHonoredRequestCounts = topSortedCSV(topSortedKeys: data.honoredRequests.keysSortedByValue(maxCount: 10, ascending: false), dataSet: data.honoredRequests)
                write(chartData: topHonoredRequestCounts, directory: timePeriodDirectory, csvFile: .topHonoredRequestCounts, headerString: "Country,\(CSVOutputFile.topHonoredRequestCounts.rawValue)")
                
                let topHonoredRequestCountsByRequests = topSortedCSV(topSortedKeys: topCountriesByRequestCount, dataSet: data.honoredRequests)
                write(chartData: topHonoredRequestCountsByRequests, directory: timePeriodDirectory, csvFile: .topHonoredRequestCountsByRequests, headerString: "Country,\(CSVOutputFile.topHonoredRequestCountsByRequests.rawValue)")
                
                // honored request percentages
                let topHonoredPercentages = topSortedCSV(topSortedKeys: data.honoredPercentages.keysSortedByValue(maxCount: 10, ascending: false), dataSet: data.honoredPercentages)
                write(chartData: topHonoredPercentages, directory: timePeriodDirectory, csvFile: .topHonoredRequestPercentages, headerString: "Country,\(CSVOutputFile.topHonoredRequestPercentages.rawValue)")
                
                let topHonoredPercentagesByRequests = topSortedCSV(topSortedKeys: topCountriesByRequestCount, dataSet: data.honoredPercentages)
                write(chartData: topHonoredPercentagesByRequests, directory: timePeriodDirectory, csvFile: .topHonoredRequestPercentagesByRequests, headerString: "Country,\(CSVOutputFile.topHonoredRequestPercentagesByRequests.rawValue)")
                
                // distributions
                [
                    CSVOutputFile.requestDistribution: data.requests.values.normalDistribution(),
                    CSVOutputFile.itemsDistribution: data.items.values.normalDistribution(),
                    CSVOutputFile.ratioDistribution: data.ratios.values.normalDistribution(),
                    CSVOutputFile.honoredRequestDistribution: data.honoredRequests.values.normalDistribution(),
                    CSVOutputFile.honoredPercentageDistribution: data.honoredPercentages.values.normalDistribution(),
                ].forEach({ (distribution) in
                    write(chartData: distribution.value.sortedByKey().map {($0.0, "\($0.1)")}, directory: timePeriodDirectory, csvFile: distribution.key, headerString: "Standard Deviation,# of Countries")
                })
            })
            
            // write timeseries reports
            let sortedCountries = countries.sorted()
            let timeSeriesName = reportNameAndContents.key.rawValue.replacingOccurrences(of: ".csv", with: "")
            let directory = baseURL.appendingPathComponent("Time Series").appendingPathComponent(timeSeriesName)
            try! fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            write(timeSeries: requestCountsOverTime, csv: csv, directory: directory, csvFile: .requestSeries, sortedCountries: sortedCountries)
            write(timeSeries: itemCountsOverTime, csv: csv, directory: directory, csvFile: .itemSeries, sortedCountries: sortedCountries)
            write(timeSeries: itemRatiosOverTime, csv: csv, directory: directory, csvFile: .ratioSeries, sortedCountries: sortedCountries)
            write(timeSeries: honoredRequestCountsOverTime, csv: csv, directory: directory, csvFile: .honoredRequestSeries, sortedCountries: sortedCountries)
            write(timeSeries: honoredPercentagesOverTime, csv: csv, directory: directory, csvFile: .honoredPercentageSeries, sortedCountries: sortedCountries)
        }
    }
}
