# PDFDrawingView
PDFDrawingView is a lightweight PDF Viewer that has built in functionality for drawing.

# How to Use:

1. Create a PDF Document using PDFKit.
2. Import using CocoaPods or download from here.
* For CocoaPods, here is an example PodFile
```pod
# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'
source "https://github.com/jrosen081/PDFDrawingView.git"
target 'YOUR_TARGET_ID' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for drawSecure
  pod 'DrawingPDF'
end
```
3. Use the constructor method.
```swift
let pdfDrawer = PDFDrawingView(frame: backgroundView.bounds, document: documentPDF, delegate: self) //Creates an instance of the view
```
It is that simple.

# Features:
1. Normal Drawing
2. Highlighting
3. Erasing
4. Adding text boxes and being able to move and resize them.
5. Moving different lines and zooming with the lasso tool.
4. Apple Pencil compatible, with force changing the lines being drawn

# Ways to choose the tool to use
- There is a struct which has all of the options.
```swift 
public struct DrawingKeys{
        public static let draw = "draw"
        public static let scroll = "scroll"
        public static let highlight = "highlight"
        public static let text = "text"
        public static let erase = "erase"
        public static let lasso = "lasso"
    }
```    
- Here is how to tell the view what to do
```swift
pdfDrawer.drawingKey = PDFDrawingView.DrawingKeys.draw //Will have the view draw
```
- To change the color of drawing and highlighting, do the following:
```swift
pdfDrawer.drawingColor = UIColor.red //Changes the drawing color to red
pdfDrawer.highlightColor = UIColor.yellow //Changes the highlight color to yellow
```
# Implement the delegate protocol for more information about the PDFDrawingView
## The delegate tells you when:
1. The page has changed
2. The view was created
```swift
extension DrawViewController: PDFDelegate{
    func scrolled(to page: Int) {
        self.currentPageNumber = page
    }
    
    func viewWasCreated() {
        doSomething()
    }
}
```
