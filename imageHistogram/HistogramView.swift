//
//  histogramView.swift
//  imageHistogram
//
//  Created by Naoki Takeshita on 2021/05/09.
//

import Cocoa

struct ColorMapData {
    var dataArray:[UInt]!
    var color:NSColor!
}

class HistogramView: NSView {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    var colorMapData:[ColorMapData] = [ColorMapData]()
    
    
    override init(frame: NSRect)
    {
        super.init(frame: frame)
    }
    
    var debug = stDebug()
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        debug.reset(name: "draw")
        
        self.layer?.backgroundColor = self.layer?.backgroundColor
        
        if colorMapData.count == 0 {return}
        
        
        // channel data全体を通しての最大値
        let max = colorMapData.map { map -> UInt in
            map.dataArray.max()!
        }.max()!
        
        
        colorMapData.forEach { map in
            
            let path = NSBezierPath()
            
            map.color.setStroke()
            map.color.withAlphaComponent(0.2).setFill()
            
            path.move(to: CGPoint(x: 0, y: 0))
            
            let dataCount = map.dataArray.count
            
            let interpolateDistance = self.frame.width / CGFloat(dataCount)
            
            
            for i in 0..<dataCount {
                // current:max = yp:height
                let yp = Float( map.dataArray[i] * UInt(self.frame.height) / max )
         
                let p:NSPoint = NSPoint(x: CGFloat(i) * interpolateDistance, y: CGFloat( yp))
                path.line(to:p)
            }
            
            path.line(to: NSPoint(x: 255 * interpolateDistance, y: 0))
            path.line(to: NSPoint(x: 0, y: 0))
            
            
            path.stroke()
            path.fill()
            
        }
        
        debug.done()
        
    }
    
    
    func createLayerForColor(color: NSColor) -> CAShapeLayer{
        let layer = CAShapeLayer()
        layer.strokeColor = color.cgColor
        layer.fillColor = color.withAlphaComponent(0.3).cgColor
        layer.masksToBounds = true
        layer.lineJoin = .round
        
        return layer
    }
}
extension NSBezierPath {
    
    public var cgPath: CGPath {
        let path: CGMutablePath = CGMutablePath()
        var points = [NSPoint](repeating: NSPoint.zero, count: 3)
        for i in (0 ..< self.elementCount) {
            switch self.element(at: i, associatedPoints: &points) {
            case .moveTo:
                path.move(to: CGPoint(x: points[0].x, y: points[0].y))
            case .lineTo:
                path.addLine(to: CGPoint(x: points[0].x, y: points[0].y))
            case .curveTo:
                path.addCurve(to: CGPoint(x: points[2].x, y: points[2].y),
                              control1: CGPoint(x: points[0].x, y: points[0].y),
                              control2: CGPoint(x: points[1].x, y: points[1].y))
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }
        return path
    }
    
}
