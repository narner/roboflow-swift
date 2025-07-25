//
//  ObjectDetectionTests.swift
//  
//
//  Created by Maxwell Stone on 12/19/24.
//

import XCTest
import Roboflow
import CoreVideo
import CoreGraphics
import ImageIO
import Foundation
#if canImport(UIKit)
import UIKit
#endif

final class ObjectDetectionTests: XCTestCase {
    var model: RFModel?

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - Object Detection Model Tests

    func testLoadModel() async {
        let rf = RoboflowMobile(apiKey: API_KEY)
        let (model, error, _, _) = await rf.load(model: "playing-cards-ow27d", modelVersion: 2)
        self.model = model
        XCTAssertNil(error)
        XCTAssertNotNil(model)
    }

    // test running inference
    func testRunInference() async {
        guard let model = await TestUtils.loadObjectDetectionModel() else {
            XCTFail("Failed to load object detection model")
            return
        }

        guard let buffer = TestUtils.loadImageAsPixelBuffer(from: "Tests/assets/hard-hat.jpeg") else {
            XCTFail("Failed to load hard-hat test image")
            return
        }
        
        let (results, inferenceError) = await model.detect(pixelBuffer: buffer)
        XCTAssertNil(inferenceError)
        // Note: predictions might be nil if no objects are detected in the test image, which is expected
        XCTAssertNotNil(results)
        XCTAssert(results?.count ?? 0 > 0)
    }
    
    func testObjectDetectionInference() async {
        guard let model = await TestUtils.loadObjectDetectionModel() else {
            XCTFail("Failed to load object detection model")
            return
        }

        guard let buffer = TestUtils.loadImageAsPixelBuffer(from: "Tests/assets/hard-hat.jpeg") else {
            XCTFail("Failed to load hard-hat test image")
            return
        }
        
        let (predictions, inferenceError) = await model.detect(pixelBuffer: buffer)
        XCTAssertNil(inferenceError, "Object detection inference failed: \(inferenceError?.localizedDescription ?? "unknown error")")
        XCTAssertNotNil(predictions, "Predictions should not be nil")
        
        if let predictions = predictions {
            XCTAssertGreaterThan(predictions.count, 0, "Should have at least one prediction")
            
            // Cast to RFObjectDetectionPrediction to test specific properties
            for prediction in predictions {
                guard let objPrediction = prediction as? RFObjectDetectionPrediction else {
                    XCTFail("Prediction should be of type RFObjectDetectionPrediction")
                    continue
                }
                
                XCTAssertFalse(objPrediction.className.isEmpty, "Class name should not be empty")
                XCTAssertGreaterThanOrEqual(objPrediction.confidence, 0.0, "Confidence should be >= 0")
                XCTAssertLessThanOrEqual(objPrediction.confidence, 1.0, "Confidence should be <= 1")
                
                // Test bounding box properties
                XCTAssertGreaterThan(objPrediction.width, 0, "Width should be > 0")
                XCTAssertGreaterThan(objPrediction.height, 0, "Height should be > 0")
                
                // Test getValues() method
                let values = objPrediction.getValues()
                XCTAssertNotNil(values["class"])
                XCTAssertNotNil(values["confidence"])
                XCTAssertNotNil(values["x"])
                XCTAssertNotNil(values["y"])
                XCTAssertNotNil(values["width"])
                XCTAssertNotNil(values["height"])
            }
        }
    }
    
    #if canImport(UIKit)
    func testObjectDetectionUIImageInference() async {
        guard let model = await TestUtils.loadObjectDetectionModel() else {
            XCTFail("Failed to load object detection model")
            return
        }
        
        // Load UIImage from test assets
        guard let image = TestUtils.loadUIImage(from: "Tests/assets/hard-hat.jpeg") else {
            XCTFail("Failed to load hard-hat test image as UIImage")
            return
        }
        
        // Test detect method with UIImage
        let (predictions, inferenceError) = await model.detect(image: image)
        
        XCTAssertNil(inferenceError, "UIImage object detection inference failed: \(inferenceError?.localizedDescription ?? "unknown error")")
        XCTAssertNotNil(predictions, "Predictions should not be nil")
        
        if let predictions = predictions {
            XCTAssertGreaterThan(predictions.count, 0, "Should have at least one prediction")
            
            // Test RFObjectDetectionPrediction properties by casting
            for prediction in predictions {
                guard let objPrediction = prediction as? RFObjectDetectionPrediction else {
                    XCTFail("Prediction should be of type RFObjectDetectionPrediction")
                    continue
                }
                
                XCTAssertFalse(objPrediction.className.isEmpty, "Class name should not be empty")
                XCTAssertGreaterThanOrEqual(objPrediction.confidence, 0.0, "Confidence should be >= 0")
                XCTAssertLessThanOrEqual(objPrediction.confidence, 1.0, "Confidence should be <= 1")
            }
            
            // Verify meaningful results
            if let firstPrediction = predictions.first,
               let objPrediction = firstPrediction as? RFObjectDetectionPrediction {
                XCTAssertGreaterThan(objPrediction.confidence, 0.1, "Top prediction should have reasonable confidence")
            }
        }
    }
    #endif
} 