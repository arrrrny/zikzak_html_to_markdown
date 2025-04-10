//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<path_provider_foundation/PathProviderPlugin.h>)
#import <path_provider_foundation/PathProviderPlugin.h>
#else
@import path_provider_foundation;
#endif

#if __has_include(<zikzak_inappwebview_ios/InAppWebViewFlutterPlugin.h>)
#import <zikzak_inappwebview_ios/InAppWebViewFlutterPlugin.h>
#else
@import zikzak_inappwebview_ios;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [PathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"PathProviderPlugin"]];
  [InAppWebViewFlutterPlugin registerWithRegistrar:[registry registrarForPlugin:@"InAppWebViewFlutterPlugin"]];
}

@end
