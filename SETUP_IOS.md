# iOS Setup for zikzak_html_to_markdown

The package uses `flutter_gemma` for on-device ML processing, which requires some specific setup for iOS:

## Requirements

- iOS 13.0 or higher
- Xcode 14.0 or higher

## Setup Steps

1. **Update Podfile**

   In your iOS project's `Podfile`, add the following:

   ```ruby
   # Set platform to iOS 13.0 minimum
   platform :ios, '13.0'

   # Use static linking for frameworks (required for flutter_gemma)
   use_frameworks! :linkage => :static
   ```

2. **Enable File Sharing**

   In your `Info.plist` file, add:

   ```xml
   <key>UIFileSharingEnabled</key>
   <true/>
   ```

   This allows the app to access shared files which is needed for model loading.

3. **Run Pod Install**

   After updating the Podfile, run:

   ```bash
   cd ios
   pod install
   ```

4. **Handling Static Framework Issues**

   If you encounter issues with static frameworks during pod install, add this to your Podfile's post_install section:

   ```ruby
   post_install do |installer|
     installer.pods_project.targets.each do |target|
       flutter_additional_ios_build_settings(target)
       
       # Fix for static frameworks issue
       target.build_configurations.each do |config|
         config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
         
         # Allow linking against static libraries/XCFrameworks
         config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
         config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
         config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
       end
     end
   end
   ```

## Model Downloads

For privacy and performance reasons, models are processed locally on the device. You will need to:

1. Download a Gemma model (recommended: 2b-it) from Kaggle
2. Place it in your app's shared documents folder or provide a download mechanism in your app

## Troubleshooting

- If you see `The plugin "flutter_gemma" requires a higher minimum iOS deployment target`, make sure your platform in Podfile is set to '13.0' or higher.
- If you see errors about static frameworks, ensure you're using `:linkage => :static` with `use_frameworks!`
- If the model doesn't load, check that the file path is correct and the model file is accessible to your app
