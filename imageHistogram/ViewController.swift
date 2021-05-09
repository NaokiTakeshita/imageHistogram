//
//  ViewController.swift
//  imageHistogram
//
//  Created by Naoki Takeshita on 2021/05/09.
//

import Cocoa
import Accelerate.vImage

struct stDebug {
    var start = Date()
    var functionName = ""
    
    init() {
        
    }
    
    mutating func reset(name text:String){
        start = Date()
        functionName = text
    }
    
    func done(){
        let elapsed = Date().timeIntervalSince(start)
        print(" *func: \(functionName), Time: \(round( elapsed * 1000 * 10000) / 10000)ms")
    }
}

class ViewController: NSViewController {

    @IBOutlet weak var histogramView: HistogramView!
    var debug = stDebug()
    
    @IBOutlet weak var imgView: NSImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func loadImageBtn(_ sender: Any) {
        debug.reset(name: "load img")
        
        guard let img = NSImage(named: "PIC - 13204") else {
            print("unable to load image")
            return
        }
    
        imgView.image = img
        debug.done()
        
        debug.reset(name: "make cgImg 1")
        var imageRect = NSRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
        guard let cgImg1 =  img.cgImage(forProposedRect: &imageRect, context: nil, hints: nil) else {
            abort()
        }
        debug.done()
        
  
        debug.reset(name: "calc")
        
        let (r,g,b, a) = histogramCalculation(imageRef: cgImg1)

        debug.done()
        
        debug.reset(name: "make 3ch chart")
        histogramView.layer?.backgroundColor = CGColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1)
        histogramView.colorMapData.append(ColorMapData(dataArray: r, color: NSColor.red))
        histogramView.colorMapData.append(ColorMapData(dataArray: g, color: NSColor.green))
        histogramView.colorMapData.append(ColorMapData(dataArray: b, color: NSColor.blue))
        //histogramView.colorMapData.append(ColorMapData(dataArray: a, color: NSColor.gray))
        histogramView.setNeedsDisplay(histogramView.frame)
        
        debug.done()
    
        
    }
    
    


    func histogramCalculation(imageRef: CGImage) -> (red: [UInt], green: [UInt], blue: [UInt], alpha:[UInt])
    {
       
        let imgProvider: CGDataProvider = imageRef.dataProvider!
        let imgBitmapData: CFData = imgProvider.data!
        
        var imgBuffer = vImage_Buffer(
            data: UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(imgBitmapData)),
            height: vImagePixelCount(imageRef.height),
            width: vImagePixelCount(imageRef.width),
            rowBytes: imageRef.bytesPerRow)
        
        
        // bins: zero = red, green = one, blue = two, alpha = three
        var histogramBinZero = [vImagePixelCount](repeating: 0, count: 256)
        var histogramBinOne = [vImagePixelCount](repeating: 0, count: 256)
        var histogramBinTwo = [vImagePixelCount](repeating: 0, count: 256)
        var histogramBinThree = [vImagePixelCount](repeating: 0, count: 256)

        histogramBinZero.withUnsafeMutableBufferPointer { zeroPtr in
            histogramBinOne.withUnsafeMutableBufferPointer { onePtr in
                histogramBinTwo.withUnsafeMutableBufferPointer { twoPtr in
                    histogramBinThree.withUnsafeMutableBufferPointer { threePtr in
                        
                        var histogramBins = [zeroPtr.baseAddress, onePtr.baseAddress,
                                             twoPtr.baseAddress, threePtr.baseAddress]
                        
                        histogramBins.withUnsafeMutableBufferPointer { histogramBinsPtr in
                            let error =  vImageHistogramCalculation_ARGB8888(&imgBuffer,
                                                                            histogramBinsPtr.baseAddress!,
                                                                            vImage_Flags(kvImageNoFlags))
                            
                            guard error == kvImageNoError else {
                                fatalError("Error calculating histogram: \(error)")
                            }
                        }
                    }
                }
            }
        }
        
        
        return (histogramBinZero, histogramBinOne, histogramBinTwo, histogramBinThree)
    }

}
