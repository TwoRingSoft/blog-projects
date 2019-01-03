import Charts
import FastMath
import Pippin
import UIKit

typealias CsvUrlContentsMap = [String: String]
typealias CsvRow = [String]

let size = 300
let fileManager = FileManager.default

enum CSV: String, CaseIterable {
    case devices = "device_requests.csv"
    case financialIDs = "financial_identifier_requests.csv"
    case accountPreservation = "account_preservation_requests.csv"
    case accountRequests = "account_requests.csv"
    case accountRestrictionDeletion = "account_restriction_deletion_requests.csv"
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

func extractContentsFromCSVs() -> CsvUrlContentsMap {
    return CSV.allCases.reduce(into: [String: String](), { (result, path) in
        let components = path.rawValue.split(separator: ".")
        let url = Bundle.main.url(forResource: String(components.first!), withExtension: String(components.last!))!
        let contents = try! String(contentsOf: url)
        result[path.rawValue] = contents
    })
}

func extractRows(fromCsvContents contents: String) -> [CsvRow] {
    let rowComponents = contents.split(separator: "\r\n").map({ (substring) -> String in
        return String(substring)
    })
    let valueRows = Array(rowComponents[1..<rowComponents.count]) // return all but header row
    let valueRowComponents: [CsvRow] = valueRows.map({ (row) -> [String] in
        let result = Array(row.split(separator: ",")).map({String($0)})
        return result
    })
    return valueRowComponents
}

func saveCharts(forDataSet dataSet: [String: Double], name: String, timePeriod: String, directory: URL, reportFilename: String) {
    let amountOfTopValuesToRetain = 10
    let amountOfTopValuesAvailable = dataSet.count < amountOfTopValuesToRetain ? dataSet.count : amountOfTopValuesToRetain
    
    let topKeysByValue = Array(dataSet.map({ (keyValuePair) -> (String, Double) in
        return (keyValuePair.key, keyValuePair.value) // turn [String: Double] into [(String, Double)]
    }).sorted(by: { (a, b) -> Bool in
        return a.1 > b.1 // sort descending
    }).map({ (keyValueTuple) -> String in
        return keyValueTuple.0 // turn into just String keys
    })[0..<amountOfTopValuesAvailable]) // take the top 10 keys (or entire set if less than 10)
    
    let topValues = dataSet.filter { (keyValuePair) -> Bool in
        return topKeysByValue.contains(keyValuePair.key)
    }
    let topZScores = dataSet.zScores().filter { (keyValuePair) -> Bool in
        return topKeysByValue.contains(keyValuePair.key)
    }
    let zScoreDistribution = dataSet.normalDistribution()
    
    saveChart(for: topValues, name: "\(name)s", timePeriod: timePeriod, directory: directory, reportFilename: reportFilename)
    saveChart(for: topZScores, name: "\(name) Z-Scores", timePeriod: timePeriod, directory: directory, reportFilename: reportFilename)
    saveChart(for: zScoreDistribution, name: "\(name) Z-Score Distribution", timePeriod: timePeriod, directory: directory, reportFilename: reportFilename)
    
//    let topValuesCSV = topValues.reduce(into: [String: String]()) { (result, keyValuePair) in
//        result[keyValuePair.key] = "\(keyValuePair.value)"
//    }
//    write(chartData: topValuesCSV, directory: directory, reportFilename: reportFilename, name: "\(name)s")
}

/// Save a bar chart for a set of data structured where the x and y values are both numbers.
func saveChart(for distribution: TaggedHistogramCount, name: String, timePeriod: String, directory: URL, reportFilename: String) {
    let values = distribution.reduce(into: [String: Double]()) { (result, taggedHistogramValue) in
        let (bucket, value) = taggedHistogramValue
        let (count, _) = value
        result[bucket] = Double(count)
    }
    
    let chart = BarChartView(frame: CGRect(origin: .zero, size: CGSize(size: size)))
    chart.backgroundColor = .white
    let requestValues = values.map({ (keyValuePair) -> BarChartDataEntry in
        let (key, value) = keyValuePair
        return BarChartDataEntry(x: (key as NSString).doubleValue, y: value)
    })
    
    chart.data = BarChartData(dataSet: BarChartDataSet(values: requestValues, label: name))
    chart.drawValueAboveBarEnabled = false
    chart.setNeedsDisplay()
    
    write(chart: chart, directory: directory, reportFilename: reportFilename, name: name)
}

/// Save a bar chart for a set of data structured as country names (x) mapped to numeric values (y).
func saveChart(for values: [String: Double], name: String, timePeriod: String, directory: URL, reportFilename: String) {
    let chart = BarChartView(frame: CGRect(origin: .zero, size: CGSize(width: size, height: 2 * size)))
    chart.backgroundColor = .white
    var keys = [String]()
    let requestValues = values.map({ (keyValuePair) -> BarChartDataEntry in
        let (key, value) = keyValuePair
        keys.append(key)
        return BarChartDataEntry(x: Double(keys.firstIndex(of: key)!), y: value)
    })
    
    class XAxisMemberNameFormatter: IAxisValueFormatter {
        private let keys: [String]
        init(keys: [String]) {
            self.keys = keys
        }
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            return keys[Int(value)]
        }
    }
    
    chart.xAxis.valueFormatter = XAxisMemberNameFormatter(keys: keys)
    chart.xAxis.labelPosition = .bottom
    chart.xAxis.labelRotationAngle = 90
    chart.xAxis.setLabelCount(keys.count, force: true)
    
    chart.autoScaleMinMaxEnabled = false
    chart.data = BarChartData(dataSet: BarChartDataSet(values: requestValues, label: name))
    chart.drawValueAboveBarEnabled = false
    chart.setNeedsDisplay()
    
    write(chart: chart, directory: directory, reportFilename: reportFilename, name: name)
}

/// Write the chart image to a PNG file.
func write(chart: BarChartView, directory: URL, reportFilename: String, name: String) {
    let chartData = chart.snapshot()!.pngData()
    let imageURL = directory.appendingPathComponent(
        reportFilename.replacingOccurrences(of: ".csv", with: "")
            .appending("-\(name.lowercased().replacingOccurrences(of: " ", with: "-"))")
            .appending(".png")
    )
    print("Saving \(imageURL)")
    fileManager.createFile(atPath: imageURL.path, contents: chartData, attributes: nil)
}

/// Write the chart data to a CSV file.
func write(chartData: [String: String], directory: URL, reportFilename: String, name: String) {
    let csvURL = directory.appendingPathComponent(
        reportFilename.replacingOccurrences(of: ".csv", with: "")
            .appending("-\(name.lowercased().replacingOccurrences(of: " ", with: "-"))")
            .appending(".csv")
    )
    print("Saving \(csvURL)")
    let csvString = chartData.map({ (keyValuePair) -> String in
        return "\(keyValuePair.key), \(keyValuePair.value)"
    }).joined(separator: "\n")
    fileManager.createFile(atPath: csvURL.path, contents: csvString.data(using: .utf8), attributes: nil)
}

func printHeadings(contents: String) {
    print(contents.split(separator: "\r\n").first!.split(separator: ",").map({ String($0) }))
}

func honoredRequestRatio(report: String, rowColumns: CsvRow, requestAmount: Double) -> Double {
    let honoredRequestRatio: Double
    if report == CSV.devices.rawValue || report == CSV.financialIDs.rawValue {
        honoredRequestRatio = (rowColumns[Column.HonoredRequests.devicesAndFinancialIDs.rawValue] as NSString).doubleValue
    } else if report == CSV.accountPreservation.rawValue {
        let value = (rowColumns[Column.HonoredRequests.Accounts.preservation.rawValue] as NSString).doubleValue
        honoredRequestRatio = value / requestAmount
    } else if report == CSV.accountRequests.rawValue {
        honoredRequestRatio = (rowColumns[Column.HonoredRequests.Accounts.info.rawValue] as NSString).doubleValue
    } else {
        precondition(report == CSV.accountRestrictionDeletion.rawValue)
        let preservation = (rowColumns[Column.HonoredRequests.Accounts.preservation.rawValue] as NSString).doubleValue
        let deletion = (rowColumns[Column.HonoredRequests.Accounts.deletion.rawValue] as NSString).doubleValue
        honoredRequestRatio = preservation + deletion
    }
    return honoredRequestRatio
}

//
// Start
//

let imageBaseURL = URL(fileURLWithPath: "/Users/andrew/Documents/Shared Playground Data/AppleTransparencyReport")
if !fileManager.fileExists(atPath: imageBaseURL.path) {
    try! fileManager.createDirectory(at: imageBaseURL, withIntermediateDirectories: false, attributes: nil)
}

extractContentsFromCSVs().forEach { (reportNameAndContents) in
    let (reportFilename, contents) = reportNameAndContents
    
    print("Processing \(reportFilename)")
    
//    printHeadings(contents: contents)
    
    let valueRowsAndColumns = extractRows(fromCsvContents: contents)
    
    let valueSetsByDate = valueRowsAndColumns.reduce(into: [String: [CsvRow]](), { (result, row) in
        let timePeriod = row[Column.timePeriod.rawValue]
        if nil == result[timePeriod] {
            result[timePeriod] = [row]
        } else {
            result[timePeriod]!.append(row)
        }
    })
    
    valueSetsByDate.forEach({ (keyValuePair) in
        let (timePeriod, rows) = keyValuePair
        
        let timePeriodDirectory = imageBaseURL.appendingPathComponent(timePeriod, isDirectory: true)
        if !fileManager.fileExists(atPath: timePeriodDirectory.path) {
            try! fileManager.createDirectory(at: timePeriodDirectory, withIntermediateDirectories: false, attributes: nil)
        }
        
        var requestsReceived = [String: Double]()
        var requestItemRatios = [String: Double]()
        var honoredRequestRatios = [String: Double]()
        
        rows.forEach({ (rowColumns) in
            let country = rowColumns[Column.country.rawValue]
            let requestAmount = (rowColumns[Column.requestCount.rawValue] as NSString).doubleValue
            let itemsPerRequest = (rowColumns[Column.totalItemCount.rawValue] as NSString).doubleValue
            requestsReceived[country] = requestAmount
            requestItemRatios[country] = requestAmount / itemsPerRequest
            honoredRequestRatios[country] = honoredRequestRatio(report: reportFilename, rowColumns: rowColumns, requestAmount: requestAmount)
        })
        
        saveCharts(forDataSet: requestsReceived, name: "Request", timePeriod: timePeriod, directory: timePeriodDirectory, reportFilename: reportFilename)
        saveCharts(forDataSet: requestItemRatios, name: "Request Item Ratio", timePeriod: timePeriod, directory: timePeriodDirectory, reportFilename: reportFilename)
        saveCharts(forDataSet: honoredRequestRatios, name: "Honored Request Percentage", timePeriod: timePeriod, directory: timePeriodDirectory, reportFilename: reportFilename)
    })
}
