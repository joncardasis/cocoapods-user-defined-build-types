# cocoapods-user-defined-build-types
![Latest Version](https://img.shields.io/badge/compatible_cocoapods-1.8.4-gray.svg)

A description of cocoapods-user-defined-build-types.

## Installation
```Bash
$ gem install cocoapods-user-defined-build-types
```

## Usage
```C
plugin 'cocoapods-user-defined-build-types'

enable_user_defined_build_types!

target "CoffeeApp" do
    pod 'Alamofire'
    pod "SwiftyJSON", :dynamic_framework => true
end
```
- Add `plugin 'cocoapods-user-defined-build-types'` to the head of your Podfile
- Add `:dynamic_framework => true` as a option to a specific pod, which makes the pod a dynamic framework
- `pod install`


SUPPORTED BUILD TYPES
- `dynamic_library`
- `dynamic_framework`
- `static_library`
- `static_framework`

## Why?
Cocoapod's `use_frameworks!` directive makes **all** integrated pods build as dynamic frameworks.

This can cause issues with certain pods. You may want some pods to be static libraries and a single pod to a dynamic framework. Cocoapods currently does not support this. The `cocoapods-user-defined-build-types` plugin allows for build types to be changed on a pod-by-pod basis, otherwise defaulting to Cocoapods default build type (static library). 

This plugin was specifically built for React Native projects to be able to incorporate dynamic Swift pods without needing to change other pods.

## Verbose Logging
Having issues? Try enabling the plugin's verbose logging from the Podfile:
```C
plugin 'cocoapods-user-defined-build-types', {
  verbose: true
}

...
```

For even more detailed logging, the development flag can be set in your terminal env: `export CP_DEV=1`.

## How
**1.8.4**
Overrides `Pod::Podfile::TargetDefinition`'s `build_type` function (from cocoapods-core) to return the specifed linking (static/dynamic) and packing (library/framework) which the pod target should use.


## License
Available under the MIT license. See the LICENSE file for more info.