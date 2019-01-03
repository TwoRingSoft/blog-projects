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
    private let baseURL = URL(fileURLWithPath: "/Users/andrew/Documents/Shared Playground Data/AppleTransparencyReport")
    
    func testReport() {
        if fileManager.fileExists(atPath: baseURL.path) {
            try! fileManager.removeItem(at: baseURL)
        }
        try! fileManager.createDirectory(at: baseURL, withIntermediateDirectories: false, attributes: nil)
        
        Bundle(for: AppleTransparencyReport.self).extractContentsFromCSVs().forEach { (reportNameAndContents) in
            let (csv, contents) = reportNameAndContents
            
            // for each time period, output data sets mapping countries to various stats, and build mappings of time periods to those data sets for later timeseries analysis
            var countries = Set<String>()
            var requestsOverTime = DataSetMap()
            var ratiosOverTime = DataSetMap()
            var honoredPercentagesOverTime = DataSetMap()
            contents.csvByTimePeriod.forEach({ (keyValuePair) in
                let (timePeriod, rows) = keyValuePair
                
                let timePeriodDirectory = baseURL.appendingPathComponent(timePeriod).appendingPathComponent(csv.rawValue.replacingOccurrences(of: ".csv", with: ""))
                try! fileManager.createDirectory(at: timePeriodDirectory, withIntermediateDirectories: true, attributes: nil)
                
                let data = extractDataSets(rows: rows, csv: csv)
                requestsOverTime[timePeriod] = data.requests
                ratiosOverTime[timePeriod] = data.ratios
                honoredPercentagesOverTime[timePeriod] = data.honoredPercentages
                let topKeysByRequestValue = data.requests.keysSortedByValue(maxCount: 10, ascending: false)
                data.requests.keys.forEach { countries.insert($0) }
                
                let topRequests = topSortedCSV(topSortedKeys: topKeysByRequestValue, dataSet: data.requests)
                write(chartData: topRequests, directory: timePeriodDirectory, name: CSVOutputFile.requests.rawValue, headerString: "Country,\(CSVOutputFile.requests.rawValue)")
                
                let topRatiosByRequests = topSortedCSV(topSortedKeys: topKeysByRequestValue, dataSet: data.ratios)
                write(chartData: topRatiosByRequests, directory: timePeriodDirectory, name: CSVOutputFile.itemRatios.rawValue, headerString: "Country,\(CSVOutputFile.itemRatios.rawValue)")
                
                let topHonoredPercentagesByRequests = topSortedCSV(topSortedKeys: topKeysByRequestValue, dataSet: data.honoredPercentages)
                write(chartData: topHonoredPercentagesByRequests, directory: timePeriodDirectory, name: CSVOutputFile.honoredRequestPercentages.rawValue, headerString: "Country,\(CSVOutputFile.honoredRequestPercentages.rawValue)")
                
                let distributions = [
                    CSVOutputFile.requests.rawValue: data.requests.values.normalDistribution(),
                    CSVOutputFile.itemRatios.rawValue: data.ratios.values.normalDistribution(),
                    CSVOutputFile.honoredRequestPercentages.rawValue: data.honoredPercentages.values.normalDistribution(),
                    ]
                
                distributions.forEach({ (distribution) in
                    write(chartData: distribution.value.sortedByKey().map {($0.0, "\($0.1)")}, directory: timePeriodDirectory, name: "\(distribution.key) Z-Score Distribution", headerString: "Standard Deviation,# of Countries")
                })
            })
            
            let sortedCountries = countries.sorted()
            let timeSeriesName = reportNameAndContents.key.rawValue.replacingOccurrences(of: ".csv", with: "")
            let directory = baseURL.appendingPathComponent("Time Series").appendingPathComponent(timeSeriesName)
            try! fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            write(timeSeries: requestsOverTime, csv: csv, directory: directory, name: CSVOutputFile.requests.rawValue, sortedCountries: sortedCountries)
            write(timeSeries: ratiosOverTime, csv: csv, directory: directory, name: CSVOutputFile.itemRatios.rawValue, sortedCountries: sortedCountries)
            write(timeSeries: honoredPercentagesOverTime, csv: csv, directory: directory, name: CSVOutputFile.honoredRequestPercentages.rawValue, sortedCountries: sortedCountries)
        }
    }
}
