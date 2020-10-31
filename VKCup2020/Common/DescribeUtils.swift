//
//  DescribeUtils.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 22.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import Foundation

struct DescribeUtils {
    let dateFormatter = DateFormatter()
    
    func describe(unix: Int) -> String {
        let date = Date(timeIntervalSince1970: Double(unix))
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "сегодня"
        }
        
        if calendar.isDateInYesterday(date) {
            return "вчера"
        }
        
        guard let year = calendar.dateComponents([.year], from: date).year,
            let actualYear = calendar.dateComponents([.year], from: Date()).year,
            actualYear > year
        else {
            dateFormatter.dateFormat = "d MMM"
            return dateFormatter.string(from: date)
        }
        
        dateFormatter.dateFormat = "d MMM YYYY"
        return dateFormatter.string(from: date)
    }
    
    func describe(size: Int) -> String {
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .binary)
    }
    
    func describe(ext: String) -> String {
        return ext.uppercased()
    }
}
