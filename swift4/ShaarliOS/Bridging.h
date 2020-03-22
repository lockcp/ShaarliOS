//
// Bridging header to access libxml2 html parsing from swift.
//
// First adjust some settings as described by http://redqueencoder.com/wrapping-libxml2-for-swift/
//
// * add to Xcode build settings “Header Search Paths”:
//     $(SDKROOT)/usr/include/libxml2
// * add to Xcode build settings "Other Linker Flags."
//     -lxml2
//
// Also: https://github.com/SonoPlot/Swift-libxml/blob/master/LibXMLWrapperExample/LibXMLWrapperExample/Bridging-Header.h

#import <libxml/HTMLparser.h>
#import <libxml/xmlerror.h>

// static inline UInt32 xmlElementTypeToInt(xmlElementType type) {
//    return (UInt32) type;
//}
