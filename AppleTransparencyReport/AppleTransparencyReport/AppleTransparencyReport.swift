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
    
    private let countriesToExtract = 10
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
            var latestTopCountryLists = [ReportDataType: [String]]()
            var latestBottomCountryLists = [ReportDataType: [String]]()
            let csvContentsByTimePeriod = contents.csvByTimePeriod
            let lastTimePeriod = csvContentsByTimePeriod.keys.sorted().last!
            csvContentsByTimePeriod.forEach({ (keyValuePair) in
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
                    .appendingPathComponent(csv.fileName.replacingOccurrences(of: ".csv", with: ""))
                try! fileManager.createDirectory(at: timePeriodDirectory, withIntermediateDirectories: true, attributes: nil)
                
                // process top/bottom N countries by various values
                [true, false].forEach { ascending in
                    let countriesByRequestCount = data.requests.keysSortedByValue(maxCount: countriesToExtract, ascending: ascending)
                    let countriesByItemsRequested = data.items.keysSortedByValue(maxCount: countriesToExtract, ascending: ascending)
                    let countriesByItemsPerRequest = data.ratios.keysSortedByValue(maxCount: countriesToExtract, ascending: ascending)
                    let countriesByHonoredRequests = data.honoredRequests.keysSortedByValue(maxCount: countriesToExtract, ascending: ascending)
                    let countriesByHonoredRequestPercentage = data.honoredPercentages.keysSortedByValue(maxCount: countriesToExtract, ascending: ascending)
                    
                    let sortingLists: [ReportDataType: [String]] = [
                        .requestCount: countriesByRequestCount,
                        .itemCount: countriesByItemsRequested,
                        .itemRatio: countriesByItemsPerRequest,
                        .honoredRequestCount: countriesByHonoredRequests,
                        .honoredRequestPercentage: countriesByHonoredRequestPercentage,
                    ]
                    if timePeriod == lastTimePeriod {
                        if ascending {
                            latestBottomCountryLists = sortingLists
                        } else {
                            latestTopCountryLists = sortingLists
                        }
                    }
                    
                    let dataSets: [ReportDataType: DataSet] = [
                        .requestCount: data.requests,
                        .itemCount: data.items,
                        .itemRatio: data.ratios,
                        .honoredRequestCount: data.honoredRequests,
                        .honoredRequestPercentage: data.honoredPercentages,
                    ]
                    dataSets.forEach { (nextDataSet) in
                        sortingLists.forEach({ (nextTopCountryList) in
                            let csvOutput = topSortedCSV(topSortedKeys: nextTopCountryList.value, dataSet: nextDataSet.value)
                            write(chartData: csvOutput, directory: timePeriodDirectory, name: (ascending ? "Bottom" : "Top") + " \(countriesToExtract) " + nextDataSet.key.rawValue, headerString: "Country,\(csv.name)", sortedBy: nextTopCountryList.key)
                        })
                    }
                }
                
                // distributions
                let distributionDirectory = timePeriodDirectory.appendingPathComponent("_distributions")
                try! fileManager.createDirectory(at: distributionDirectory, withIntermediateDirectories: true, attributes: nil)
                [
                    ReportDataType.requestCount.rawValue: data.requests.values.normalDistribution(),
                    ReportDataType.itemCount.rawValue: data.items.values.normalDistribution(),
                    ReportDataType.itemRatio.rawValue: data.ratios.values.normalDistribution(),
                    ReportDataType.honoredRequestCount.rawValue: data.honoredRequests.values.normalDistribution(),
                    ReportDataType.honoredRequestPercentage.rawValue: data.honoredPercentages.values.normalDistribution(),
                ].forEach({ (distribution) in
                    let data = distribution.value.reduce(into: [Int: Int](), { (result, next) in
                        result[next.key.integerValue] = next.value
                    }).sortedByKey().map { keyValuePair -> (String, String) in
                        let (bucket, count) = keyValuePair
                        return (String(describing: bucket), "\(count)")
                    }
                    write(chartData: data, directory: distributionDirectory, name: distribution.key, headerString: "Standard Deviation,# of Countries")
                })
            })
            
            // timeseries reports
            let timeSeriesName = reportNameAndContents.key.fileName.replacingOccurrences(of: ".csv", with: "")
            let directory = baseURL.appendingPathComponent("Time Series").appendingPathComponent(timeSeriesName)
            try! fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            [
                "Top": latestTopCountryLists,
                "Bottom": latestBottomCountryLists,
            ].forEach { rankedTimeSeries in
                rankedTimeSeries.value.forEach { keyValuePair in
                    let (ReportDataType, countries) = keyValuePair
                    let rankString =  "(\(rankedTimeSeries.key) \(countriesToExtract))"
                    write(timeSeries: requestCountsOverTime, csv: csv, directory: directory, name: "Requests Over Time \(rankString))", countries: countries, sortedBy: ReportDataType)
                    write(timeSeries: itemCountsOverTime, csv: csv, directory: directory, name: "Requested Items Over Time \(rankString)", countries: countries, sortedBy: ReportDataType)
                    write(timeSeries: itemRatiosOverTime, csv: csv, directory: directory, name: "Items Per Request Over Time \(rankString)", countries: countries, sortedBy: ReportDataType)
                    write(timeSeries: honoredRequestCountsOverTime, csv: csv, directory: directory, name: "Honored Requests Over Time \(rankString)", countries: countries, sortedBy: ReportDataType)
                    write(timeSeries: honoredPercentagesOverTime, csv: csv, directory: directory, name: "Honored Request Percentages Over Time \(rankString)", countries: countries, sortedBy: ReportDataType)
                }
            }
        }
    }
}
