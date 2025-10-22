#!/bin/bash

# Testicool Xcode Project Setup Script
# This script creates a complete Xcode project structure from the SwiftUI source files
# Usage: ./setup_xcode_project.sh

set -e  # Exit on error

echo "========================================"
echo "  Testicool Xcode Project Setup"
echo "========================================"
echo ""

# Configuration
PROJECT_NAME="Testicool"
BUNDLE_ID="com.testicool.app"
TEAM_ID=""  # Leave empty for now, user can set in Xcode
DEPLOYMENT_TARGET="16.0"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_DIR="$SCRIPT_DIR/TesticoolApp"

echo "📁 Project Directory: $APP_DIR"
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode is not installed or xcodebuild is not in PATH"
    exit 1
fi

echo "✅ Xcode found: $(xcodebuild -version | head -n 1)"
echo ""

# Create Xcode project directory structure
PROJECT_DIR="$APP_DIR/$PROJECT_NAME"
XCODEPROJ="$PROJECT_DIR.xcodeproj"

echo "🔨 Creating Xcode project structure..."

# Create project directory
mkdir -p "$PROJECT_DIR"

# Create the xcodeproj bundle
mkdir -p "$XCODEPROJ"
mkdir -p "$XCODEPROJ/project.xcworkspace"
mkdir -p "$XCODEPROJ/project.xcworkspace/xcshareddata"
mkdir -p "$XCODEPROJ/xcuserdata/$USER.xcuserdatad/xcschemes"

# Generate UUIDs for Xcode project
generate_uuid() {
    uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-' | cut -c1-24
}

# Generate unique IDs
PROJECT_ID=$(generate_uuid)
MAIN_GROUP_ID=$(generate_uuid)
PRODUCT_GROUP_ID=$(generate_uuid)
TARGET_ID=$(generate_uuid)
CONFIG_LIST_TARGET=$(generate_uuid)
CONFIG_LIST_PROJECT=$(generate_uuid)
DEBUG_CONFIG_ID=$(generate_uuid)
RELEASE_CONFIG_ID=$(generate_uuid)
NATIVE_TARGET_ID=$(generate_uuid)
SOURCE_BUILD_PHASE=$(generate_uuid)
RESOURCES_BUILD_PHASE=$(generate_uuid)
FRAMEWORKS_BUILD_PHASE=$(generate_uuid)
PRODUCT_REF_ID=$(generate_uuid)

# File reference IDs
APP_FILE_ID=$(generate_uuid)
CONTENTVIEW_ID=$(generate_uuid)
BLUETOOTH_MGR_ID=$(generate_uuid)
DEVICE_STATE_ID=$(generate_uuid)
STATUS_PARSER_ID=$(generate_uuid)
PUMP_CONTROL_ID=$(generate_uuid)
STATUS_VIEW_ID=$(generate_uuid)
SETTINGS_VIEW_ID=$(generate_uuid)
INFO_PLIST_ID=$(generate_uuid)
ASSETS_ID=$(generate_uuid)
PREVIEW_ASSETS_ID=$(generate_uuid)
PREVIEW_GROUP_ID=$(generate_uuid)

# Group IDs
MODELS_GROUP_ID=$(generate_uuid)
VIEWS_GROUP_ID=$(generate_uuid)
MANAGERS_GROUP_ID=$(generate_uuid)

# Build file IDs
APP_BUILD_ID=$(generate_uuid)
CONTENTVIEW_BUILD_ID=$(generate_uuid)
BLUETOOTH_BUILD_ID=$(generate_uuid)
DEVICE_STATE_BUILD_ID=$(generate_uuid)
STATUS_PARSER_BUILD_ID=$(generate_uuid)
PUMP_CONTROL_BUILD_ID=$(generate_uuid)
STATUS_VIEW_BUILD_ID=$(generate_uuid)
SETTINGS_VIEW_BUILD_ID=$(generate_uuid)
ASSETS_BUILD_ID=$(generate_uuid)

# Create project.pbxproj file
cat > "$XCODEPROJ/project.pbxproj" << EOF
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		${APP_BUILD_ID} /* TesticoolApp.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${APP_FILE_ID} /* TesticoolApp.swift */; };
		${CONTENTVIEW_BUILD_ID} /* ContentView.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${CONTENTVIEW_ID} /* ContentView.swift */; };
		${BLUETOOTH_BUILD_ID} /* BluetoothManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${BLUETOOTH_MGR_ID} /* BluetoothManager.swift */; };
		${DEVICE_STATE_BUILD_ID} /* DeviceState.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${DEVICE_STATE_ID} /* DeviceState.swift */; };
		${STATUS_PARSER_BUILD_ID} /* StatusParser.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${STATUS_PARSER_ID} /* StatusParser.swift */; };
		${PUMP_CONTROL_BUILD_ID} /* PumpControlView.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${PUMP_CONTROL_ID} /* PumpControlView.swift */; };
		${STATUS_VIEW_BUILD_ID} /* StatusView.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${STATUS_VIEW_ID} /* StatusView.swift */; };
		${SETTINGS_VIEW_BUILD_ID} /* SettingsView.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${SETTINGS_VIEW_ID} /* SettingsView.swift */; };
		${ASSETS_BUILD_ID} /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = ${ASSETS_ID} /* Assets.xcassets */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		${PRODUCT_REF_ID} /* ${PROJECT_NAME}.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = ${PROJECT_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; };
		${APP_FILE_ID} /* TesticoolApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TesticoolApp.swift; sourceTree = "<group>"; };
		${CONTENTVIEW_ID} /* ContentView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ContentView.swift; sourceTree = "<group>"; };
		${BLUETOOTH_MGR_ID} /* BluetoothManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = BluetoothManager.swift; sourceTree = "<group>"; };
		${DEVICE_STATE_ID} /* DeviceState.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DeviceState.swift; sourceTree = "<group>"; };
		${STATUS_PARSER_ID} /* StatusParser.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = StatusParser.swift; sourceTree = "<group>"; };
		${PUMP_CONTROL_ID} /* PumpControlView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PumpControlView.swift; sourceTree = "<group>"; };
		${STATUS_VIEW_ID} /* StatusView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = StatusView.swift; sourceTree = "<group>"; };
		${SETTINGS_VIEW_ID} /* SettingsView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SettingsView.swift; sourceTree = "<group>"; };
		${INFO_PLIST_ID} /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
		${ASSETS_ID} /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		${FRAMEWORKS_BUILD_PHASE} /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		${MAIN_GROUP_ID} = {
			isa = PBXGroup;
			children = (
				${TARGET_ID} /* ${PROJECT_NAME} */,
				${PRODUCT_GROUP_ID} /* Products */,
			);
			sourceTree = "<group>";
		};
		${PRODUCT_GROUP_ID} /* Products */ = {
			isa = PBXGroup;
			children = (
				${PRODUCT_REF_ID} /* ${PROJECT_NAME}.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
		${TARGET_ID} /* ${PROJECT_NAME} */ = {
			isa = PBXGroup;
			children = (
				${APP_FILE_ID} /* TesticoolApp.swift */,
				${CONTENTVIEW_ID} /* ContentView.swift */,
				${MANAGERS_GROUP_ID} /* Managers */,
				${MODELS_GROUP_ID} /* Models */,
				${VIEWS_GROUP_ID} /* Views */,
				${ASSETS_ID} /* Assets.xcassets */,
				${INFO_PLIST_ID} /* Info.plist */,
			);
			path = ${PROJECT_NAME};
			sourceTree = "<group>";
		};
		${MANAGERS_GROUP_ID} /* Managers */ = {
			isa = PBXGroup;
			children = (
				${BLUETOOTH_MGR_ID} /* BluetoothManager.swift */,
			);
			path = Managers;
			sourceTree = "<group>";
		};
		${MODELS_GROUP_ID} /* Models */ = {
			isa = PBXGroup;
			children = (
				${DEVICE_STATE_ID} /* DeviceState.swift */,
				${STATUS_PARSER_ID} /* StatusParser.swift */,
			);
			path = Models;
			sourceTree = "<group>";
		};
		${VIEWS_GROUP_ID} /* Views */ = {
			isa = PBXGroup;
			children = (
				${PUMP_CONTROL_ID} /* PumpControlView.swift */,
				${STATUS_VIEW_ID} /* StatusView.swift */,
				${SETTINGS_VIEW_ID} /* SettingsView.swift */,
			);
			path = Views;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		${NATIVE_TARGET_ID} /* ${PROJECT_NAME} */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = ${CONFIG_LIST_TARGET} /* Build configuration list for PBXNativeTarget "${PROJECT_NAME}" */;
			buildPhases = (
				${SOURCE_BUILD_PHASE} /* Sources */,
				${FRAMEWORKS_BUILD_PHASE} /* Frameworks */,
				${RESOURCES_BUILD_PHASE} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = ${PROJECT_NAME};
			productName = ${PROJECT_NAME};
			productReference = ${PRODUCT_REF_ID} /* ${PROJECT_NAME}.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		${PROJECT_ID} /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {
					${NATIVE_TARGET_ID} = {
						CreatedOnToolsVersion = 15.0;
					};
				};
			};
			buildConfigurationList = ${CONFIG_LIST_PROJECT} /* Build configuration list for PBXProject "${PROJECT_NAME}" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = ${MAIN_GROUP_ID};
			productRefGroup = ${PRODUCT_GROUP_ID} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				${NATIVE_TARGET_ID} /* ${PROJECT_NAME} */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		${RESOURCES_BUILD_PHASE} /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				${ASSETS_BUILD_ID} /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		${SOURCE_BUILD_PHASE} /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				${CONTENTVIEW_BUILD_ID} /* ContentView.swift in Sources */,
				${PUMP_CONTROL_BUILD_ID} /* PumpControlView.swift in Sources */,
				${DEVICE_STATE_BUILD_ID} /* DeviceState.swift in Sources */,
				${STATUS_VIEW_BUILD_ID} /* StatusView.swift in Sources */,
				${APP_BUILD_ID} /* TesticoolApp.swift in Sources */,
				${BLUETOOTH_BUILD_ID} /* BluetoothManager.swift in Sources */,
				${STATUS_PARSER_BUILD_ID} /* StatusParser.swift in Sources */,
				${SETTINGS_VIEW_BUILD_ID} /* SettingsView.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		${DEBUG_CONFIG_ID} /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = ${DEPLOYMENT_TARGET};
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		${RELEASE_CONFIG_ID} /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = ${DEPLOYMENT_TARGET};
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		$(generate_uuid) /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "";
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = Info.plist;
				INFOPLIST_KEY_NSBluetoothAlwaysUsageDescription = "Testicool needs Bluetooth access to connect to your device and control the cooling system.";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = ${BUNDLE_ID};
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
			};
			name = Debug;
		};
		$(generate_uuid) /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "";
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = Info.plist;
				INFOPLIST_KEY_NSBluetoothAlwaysUsageDescription = "Testicool needs Bluetooth access to connect to your device and control the cooling system.";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = ${BUNDLE_ID};
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		${CONFIG_LIST_PROJECT} /* Build configuration list for PBXProject "${PROJECT_NAME}" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				${DEBUG_CONFIG_ID} /* Debug */,
				${RELEASE_CONFIG_ID} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		${CONFIG_LIST_TARGET} /* Build configuration list for PBXNativeTarget "${PROJECT_NAME}" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				$(generate_uuid) /* Debug */,
				$(generate_uuid) /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = ${PROJECT_ID} /* Project object */;
}
EOF

echo "✅ Created project.pbxproj"

# Create workspace data
cat > "$XCODEPROJ/project.xcworkspace/contents.xcworkspacedata" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
EOF

echo "✅ Created workspace"

# Create scheme management
cat > "$XCODEPROJ/xcuserdata/$USER.xcuserdatad/xcschemes/xcschememanagement.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>SchemeUserState</key>
	<dict>
		<key>${PROJECT_NAME}.xcscheme_^#shared#^_</key>
		<dict>
			<key>orderHint</key>
			<integer>0</integer>
		</dict>
	</dict>
</dict>
</plist>
EOF

echo "✅ Created scheme management"

# Copy/move source files into project structure
echo ""
echo "📦 Organizing source files..."

# Copy files into Testicool directory
cp "$APP_DIR/TesticoolApp.swift" "$PROJECT_DIR/"
cp "$APP_DIR/ContentView.swift" "$PROJECT_DIR/"
cp "$APP_DIR/Info.plist" "$PROJECT_DIR/"

# Copy Managers
mkdir -p "$PROJECT_DIR/Managers"
cp "$APP_DIR/Managers/BluetoothManager.swift" "$PROJECT_DIR/Managers/"

# Copy Models
mkdir -p "$PROJECT_DIR/Models"
cp "$APP_DIR/Models/DeviceState.swift" "$PROJECT_DIR/Models/"
cp "$APP_DIR/Models/StatusParser.swift" "$PROJECT_DIR/Models/"

# Copy Views
mkdir -p "$PROJECT_DIR/Views"
cp "$APP_DIR/Views/PumpControlView.swift" "$PROJECT_DIR/Views/"
cp "$APP_DIR/Views/StatusView.swift" "$PROJECT_DIR/Views/"
cp "$APP_DIR/Views/SettingsView.swift" "$PROJECT_DIR/Views/"

# Create Assets.xcassets
mkdir -p "$PROJECT_DIR/Assets.xcassets"
cat > "$PROJECT_DIR/Assets.xcassets/Contents.json" << 'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

# Create AppIcon asset
mkdir -p "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset"
cat > "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

# Create AccentColor asset
mkdir -p "$PROJECT_DIR/Assets.xcassets/AccentColor.colorset"
cat > "$PROJECT_DIR/Assets.xcassets/AccentColor.colorset/Contents.json" << 'EOF'
{
  "colors" : [
    {
      "idiom" : "universal",
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "red" : "0.000",
          "green" : "0.478",
          "blue" : "1.000",
          "alpha" : "1.000"
        }
      }
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "✅ Source files organized"
echo ""
echo "========================================"
echo "✨ Setup Complete!"
echo "========================================"
echo ""
echo "📂 Project Location:"
echo "   $XCODEPROJ"
echo ""
echo "🚀 Next Steps:"
echo "   1. Open the project in Xcode:"
echo "      open \"$XCODEPROJ\""
echo ""
echo "   2. In Xcode:"
echo "      • Select your development team in Signing & Capabilities"
echo "      • Connect your iPhone or use the Simulator"
echo "      • Click the Play button to build and run"
echo ""
echo "   3. To test without hardware:"
echo "      • The app will work in the simulator"
echo "      • Bluetooth scanning won't find devices (simulator limitation)"
echo "      • You can still see the UI and test the interface"
echo ""
echo "   4. To test with actual hardware:"
echo "      • Deploy to a physical iOS device"
echo "      • Make sure your Arduino is powered and Bluetooth is active"
echo "      • The device should appear as 'Testicool_Prototype'"
echo ""
echo "📖 See TesticoolApp/README.md for detailed instructions"
echo ""
EOF

chmod +x "$SCRIPT_DIR/setup_xcode_project.sh"

echo "✅ Setup script created"

<function_calls>
<invoke name="TodoWrite">
<parameter name="todos">[{"content": "Create main app structure and Info.plist", "status": "completed", "activeForm": "Creating main app structure and Info.plist"}, {"content": "Implement BluetoothManager with CoreBluetooth", "status": "completed", "activeForm": "Implementing BluetoothManager with CoreBluetooth"}, {"content": "Create DeviceState model", "status": "completed", "activeForm": "Creating DeviceState model"}, {"content": "Create StatusParser for firmware responses", "status": "completed", "activeForm": "Creating StatusParser for firmware responses"}, {"content": "Implement main ContentView", "status": "completed", "activeForm": "Implementing main ContentView"}, {"content": "Create PumpControlView", "status": "completed", "activeForm": "Creating PumpControlView"}, {"content": "Create StatusView", "status": "completed", "activeForm": "Creating StatusView"}, {"content": "Create SettingsView", "status": "completed", "activeForm": "Creating SettingsView"}, {"content": "Create Xcode project setup script", "status": "completed", "activeForm": "Creating Xcode project setup script"}, {"content": "Create comprehensive README", "status": "in_progress", "activeForm": "Creating comprehensive README"}]