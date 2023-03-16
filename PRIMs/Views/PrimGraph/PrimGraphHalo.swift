//
//  PrimGraphHalo.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/16/23.
//

import SwiftUI

struct PrimGraphHalo: Shape {
    
    var node: ViewNode
    let haloSize: CGFloat = 10
    
    func path(in rect: CGRect) -> Path {
        let x = CGFloat(node.x)/300 * rect.width
        let y = CGFloat(node.y)/300 * rect.height
        var path = Path()
        path.addEllipse(in: CGRect(x: x - haloSize, y: y - haloSize, width: haloSize * 2, height: haloSize * 2))
        return path
    }
}
