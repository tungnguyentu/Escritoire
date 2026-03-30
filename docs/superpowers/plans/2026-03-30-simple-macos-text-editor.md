# Simple macOS Text Editor — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS text editor app with paste, save file, and find-word functionality, packaged as a proper .app bundle openable in Xcode.

**Architecture:** SwiftUI `DocumentGroup` scene with a `FileDocument` struct for automatic save/open/multi-window management. The core editor is `NSTextView` wrapped in `NSViewRepresentable` to access `NSTextFinder` for the native Find bar (Cmd+F). All document lifecycle (Save, Save As, Open Recent, dirty-state dot in title bar) is handled by `DocumentGroup` for free. Unit tests exercise the document model's read/write logic via extracted static helper methods.

**Tech Stack:** Swift 5.9+, SwiftUI 4+, AppKit (NSTextView, NSTextFinder), macOS 13+ (Ventura), Xcode 15+

---

## File Map

| File | Responsibility |
|---|---|
| `SimpleTextEditor.xcodeproj/project.pbxproj` | Xcode project definition: targets, build phases, build settings |
| `SimpleTextEditor.xcodeproj/project.xcworkspace/contents.xcworkspacedata` | Workspace envelope (required by Xcode) |
| `SimpleTextEditor/SimpleTextEditorApp.swift` | `@main` entry point; wires `DocumentGroup` with `TextDocument` + `ContentView` |
| `SimpleTextEditor/TextDocument.swift` | `FileDocument` implementation; UTF-8 encode/decode; testable static helpers |
| `SimpleTextEditor/ContentView.swift` | Root SwiftUI view; hosts `NSTextViewWrapper` |
| `SimpleTextEditor/NSTextViewWrapper.swift` | `NSViewRepresentable` bridge; configures `NSTextView` with Find bar + undo |
| `SimpleTextEditor/Info.plist` | Bundle metadata; declares `.txt` document type association |
| `SimpleTextEditor/SimpleTextEditor.entitlements` | App Sandbox + user-selected file read/write |
| `SimpleTextEditor/Assets.xcassets/` | Asset catalog (AppIcon placeholder + AccentColor) |
| `SimpleTextEditorTests/SimpleTextEditorTests.swift` | XCTest unit tests for `TextDocument` encode/decode helpers |

---

## Task 1: Project Skeleton

**Files:**
- Create: `SimpleTextEditor/SimpleTextEditor.xcodeproj/project.pbxproj`
- Create: `SimpleTextEditor/SimpleTextEditor.xcodeproj/project.xcworkspace/contents.xcworkspacedata`
- Create: `SimpleTextEditor/SimpleTextEditor/SimpleTextEditorApp.swift` (stub)
- Create: `SimpleTextEditor/SimpleTextEditor/TextDocument.swift` (stub)
- Create: `SimpleTextEditor/SimpleTextEditor/ContentView.swift` (stub)
- Create: `SimpleTextEditor/SimpleTextEditor/NSTextViewWrapper.swift` (stub)
- Create: `SimpleTextEditor/SimpleTextEditor/Info.plist`
- Create: `SimpleTextEditor/SimpleTextEditor/SimpleTextEditor.entitlements`
- Create: `SimpleTextEditor/SimpleTextEditor/Assets.xcassets/Contents.json`
- Create: `SimpleTextEditor/SimpleTextEditor/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `SimpleTextEditor/SimpleTextEditor/Assets.xcassets/AccentColor.colorset/Contents.json`
- Create: `SimpleTextEditor/SimpleTextEditorTests/SimpleTextEditorTests.swift` (stub)

- [ ] **Step 1: Initialize git repo**

```bash
cd "/Volumes/external/Projects 2/test"
git init
```

Expected output: `Initialized empty Git repository in ...`

- [ ] **Step 2: Create directory structure**

```bash
mkdir -p "/Volumes/external/Projects 2/test/SimpleTextEditor/SimpleTextEditor.xcodeproj/project.xcworkspace"
mkdir -p "/Volumes/external/Projects 2/test/SimpleTextEditor/SimpleTextEditor/Assets.xcassets/AppIcon.appiconset"
mkdir -p "/Volumes/external/Projects 2/test/SimpleTextEditor/SimpleTextEditor/Assets.xcassets/AccentColor.colorset"
mkdir -p "/Volumes/external/Projects 2/test/SimpleTextEditor/SimpleTextEditorTests"
```

- [ ] **Step 3: Create the Xcode workspace file**

Create `SimpleTextEditor/SimpleTextEditor.xcodeproj/project.xcworkspace/contents.xcworkspacedata`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
```

- [ ] **Step 4: Create the Xcode project file**

Create `SimpleTextEditor/SimpleTextEditor.xcodeproj/project.pbxproj` with the full content below. Every UUID is a 24-character hex string. Do not change them — they cross-reference each other throughout the file.

```
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		AABB0000000000000000AAD0 /* SimpleTextEditorApp.swift in Sources */ = {isa = PBXBuildFile; fileRef = AABB0000000000000000AAC0 /* SimpleTextEditorApp.swift */; };
		AABB0000000000000000AAD1 /* TextDocument.swift in Sources */ = {isa = PBXBuildFile; fileRef = AABB0000000000000000AAC1 /* TextDocument.swift */; };
		AABB0000000000000000AAD2 /* ContentView.swift in Sources */ = {isa = PBXBuildFile; fileRef = AABB0000000000000000AAC2 /* ContentView.swift */; };
		AABB0000000000000000AAD3 /* NSTextViewWrapper.swift in Sources */ = {isa = PBXBuildFile; fileRef = AABB0000000000000000AAC3 /* NSTextViewWrapper.swift */; };
		AABB0000000000000000AAD4 /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = AABB0000000000000000AAC5 /* Assets.xcassets */; };
		AABB0000000000000000AAD5 /* SimpleTextEditorTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = AABB0000000000000000AAC9 /* SimpleTextEditorTests.swift */; };
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
		AABB0000000000000000AAE0 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = AABB0000000000000000AAAA /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = AABB0000000000000000AAAD;
			remoteInfo = SimpleTextEditor;
		};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
		AABB0000000000000000AAC0 /* SimpleTextEditorApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SimpleTextEditorApp.swift; sourceTree = "<group>"; };
		AABB0000000000000000AAC1 /* TextDocument.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TextDocument.swift; sourceTree = "<group>"; };
		AABB0000000000000000AAC2 /* ContentView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ContentView.swift; sourceTree = "<group>"; };
		AABB0000000000000000AAC3 /* NSTextViewWrapper.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NSTextViewWrapper.swift; sourceTree = "<group>"; };
		AABB0000000000000000AAC4 /* SimpleTextEditor.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = SimpleTextEditor.entitlements; sourceTree = "<group>"; };
		AABB0000000000000000AAC5 /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
		AABB0000000000000000AAC6 /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
		AABB0000000000000000AAC7 /* SimpleTextEditor.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = SimpleTextEditor.app; sourceTree = BUILT_PRODUCTS_DIR; };
		AABB0000000000000000AAC8 /* SimpleTextEditorTests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = SimpleTextEditorTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
		AABB0000000000000000AAC9 /* SimpleTextEditorTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SimpleTextEditorTests.swift; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		AABB0000000000000000AABA /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		AABB0000000000000000AABC /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		AABB0000000000000000AAAB /* root */ = {
			isa = PBXGroup;
			children = (
				AABB0000000000000000AAF0 /* SimpleTextEditor */,
				AABB0000000000000000AAF1 /* SimpleTextEditorTests */,
				AABB0000000000000000AAAC /* Products */,
			);
			sourceTree = "<group>";
		};
		AABB0000000000000000AAAC /* Products */ = {
			isa = PBXGroup;
			children = (
				AABB0000000000000000AAC7 /* SimpleTextEditor.app */,
				AABB0000000000000000AAC8 /* SimpleTextEditorTests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		};
		AABB0000000000000000AAF0 /* SimpleTextEditor */ = {
			isa = PBXGroup;
			children = (
				AABB0000000000000000AAC0 /* SimpleTextEditorApp.swift */,
				AABB0000000000000000AAC1 /* TextDocument.swift */,
				AABB0000000000000000AAC2 /* ContentView.swift */,
				AABB0000000000000000AAC3 /* NSTextViewWrapper.swift */,
				AABB0000000000000000AAC4 /* SimpleTextEditor.entitlements */,
				AABB0000000000000000AAC5 /* Assets.xcassets */,
				AABB0000000000000000AAC6 /* Info.plist */,
			);
			path = SimpleTextEditor;
			sourceTree = "<group>";
		};
		AABB0000000000000000AAF1 /* SimpleTextEditorTests */ = {
			isa = PBXGroup;
			children = (
				AABB0000000000000000AAC9 /* SimpleTextEditorTests.swift */,
			);
			path = SimpleTextEditorTests;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		AABB0000000000000000AAAD /* SimpleTextEditor */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = AABB0000000000000000AAB0 /* Build configuration list for PBXNativeTarget "SimpleTextEditor" */;
			buildPhases = (
				AABB0000000000000000AAB8 /* Sources */,
				AABB0000000000000000AABA /* Frameworks */,
				AABB0000000000000000AAB9 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = SimpleTextEditor;
			productName = SimpleTextEditor;
			productReference = AABB0000000000000000AAC7 /* SimpleTextEditor.app */;
			productType = "com.apple.product-type.application";
		};
		AABB0000000000000000AAAE /* SimpleTextEditorTests */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = AABB0000000000000000AAB1 /* Build configuration list for PBXNativeTarget "SimpleTextEditorTests" */;
			buildPhases = (
				AABB0000000000000000AABB /* Sources */,
				AABB0000000000000000AABC /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
				AABB0000000000000000AAE1 /* PBXTargetDependency */,
			);
			name = SimpleTextEditorTests;
			productName = SimpleTextEditorTests;
			productReference = AABB0000000000000000AAC8 /* SimpleTextEditorTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		AABB0000000000000000AAAA /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {
					AABB0000000000000000AAAD = {
						CreatedOnToolsVersion = 15.0;
					};
					AABB0000000000000000AAAE = {
						CreatedOnToolsVersion = 15.0;
						TestTargetID = AABB0000000000000000AAAD;
					};
				};
			};
			buildConfigurationList = AABB0000000000000000AAAF /* Build configuration list for PBXProject "SimpleTextEditor" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = AABB0000000000000000AAAB;
			productRefGroup = AABB0000000000000000AAAC /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				AABB0000000000000000AAAD /* SimpleTextEditor */,
				AABB0000000000000000AAAE /* SimpleTextEditorTests */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		AABB0000000000000000AAB9 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				AABB0000000000000000AAD4 /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		AABB0000000000000000AAB8 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				AABB0000000000000000AAD0 /* SimpleTextEditorApp.swift in Sources */,
				AABB0000000000000000AAD1 /* TextDocument.swift in Sources */,
				AABB0000000000000000AAD2 /* ContentView.swift in Sources */,
				AABB0000000000000000AAD3 /* NSTextViewWrapper.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		AABB0000000000000000AABB /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				AABB0000000000000000AAD5 /* SimpleTextEditorTests.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		AABB0000000000000000AAE1 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = AABB0000000000000000AAAD /* SimpleTextEditor */;
			targetProxy = AABB0000000000000000AAE0 /* PBXContainerItemProxy */;
		};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
		AABB0000000000000000AAB2 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
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
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		AABB0000000000000000AAB3 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MTL_FAST_MATH = YES;
				SDKROOT = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
			};
			name = Release;
		};
		AABB0000000000000000AAB4 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = SimpleTextEditor/SimpleTextEditor.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_HARDENED_RUNTIME = YES;
				INFOPLIST_FILE = SimpleTextEditor/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.example.SimpleTextEditor";
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			};
			name = Debug;
		};
		AABB0000000000000000AAB5 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = SimpleTextEditor/SimpleTextEditor.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_HARDENED_RUNTIME = YES;
				INFOPLIST_FILE = SimpleTextEditor/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.example.SimpleTextEditor";
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			};
			name = Release;
		};
		AABB0000000000000000AAB6 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.example.SimpleTextEditorTests";
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 5.0;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/SimpleTextEditor.app/Contents/MacOS/SimpleTextEditor";
			};
			name = Debug;
		};
		AABB0000000000000000AAB7 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.example.SimpleTextEditorTests";
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 5.0;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/SimpleTextEditor.app/Contents/MacOS/SimpleTextEditor";
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		AABB0000000000000000AAAF /* Build configuration list for PBXProject "SimpleTextEditor" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AABB0000000000000000AAB2 /* Debug */,
				AABB0000000000000000AAB3 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		AABB0000000000000000AAB0 /* Build configuration list for PBXNativeTarget "SimpleTextEditor" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AABB0000000000000000AAB4 /* Debug */,
				AABB0000000000000000AAB5 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		AABB0000000000000000AAB1 /* Build configuration list for PBXNativeTarget "SimpleTextEditorTests" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AABB0000000000000000AAB6 /* Debug */,
				AABB0000000000000000AAB7 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = AABB0000000000000000AAAA /* Project object */;
}
```

- [ ] **Step 5: Create stub Swift source files (must compile; logic filled in Tasks 2–5)**

Create `SimpleTextEditor/SimpleTextEditor/SimpleTextEditorApp.swift`:

```swift
import SwiftUI

@main
struct SimpleTextEditorApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: TextDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
```

Create `SimpleTextEditor/SimpleTextEditor/TextDocument.swift`:

```swift
import SwiftUI
import UniformTypeIdentifiers

struct TextDocument: FileDocument {
    var text: String = ""

    static var readableContentTypes: [UTType] { [.plainText] }

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        text = ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data())
    }
}
```

Create `SimpleTextEditor/SimpleTextEditor/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    @Binding var document: TextDocument

    var body: some View {
        NSTextViewWrapper(text: $document.text)
            .frame(minWidth: 500, minHeight: 400)
    }
}
```

Create `SimpleTextEditor/SimpleTextEditor/NSTextViewWrapper.swift`:

```swift
import SwiftUI
import AppKit

struct NSTextViewWrapper: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        NSScrollView()
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NSTextViewWrapper
        init(_ parent: NSTextViewWrapper) { self.parent = parent }
    }
}
```

Create `SimpleTextEditor/SimpleTextEditorTests/SimpleTextEditorTests.swift`:

```swift
import XCTest
@testable import SimpleTextEditor

final class SimpleTextEditorTests: XCTestCase {}
```

- [ ] **Step 6: Create App Sandbox entitlements**

Create `SimpleTextEditor/SimpleTextEditor/SimpleTextEditor.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 7: Create Info.plist**

Create `SimpleTextEditor/SimpleTextEditor/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>txt</string>
            </array>
            <key>CFBundleTypeName</key>
            <string>Plain Text Document</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Default</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.plain-text</string>
            </array>
        </dict>
    </array>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(MARKETING_VERSION)</string>
    <key>CFBundleVersion</key>
    <string>$(CURRENT_PROJECT_VERSION)</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
    <key>NSHumanReadableDescription</key>
    <string>A simple macOS text editor</string>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 8: Create asset catalog files**

Create `SimpleTextEditor/SimpleTextEditor/Assets.xcassets/Contents.json`:

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Create `SimpleTextEditor/SimpleTextEditor/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
{
  "images" : [
    { "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Create `SimpleTextEditor/SimpleTextEditor/Assets.xcassets/AccentColor.colorset/Contents.json`:

```json
{
  "colors" : [
    { "idiom" : "universal" }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 9: Verify the project compiles (no logic yet — just stubs)**

```bash
cd "/Volumes/external/Projects 2/test/SimpleTextEditor"
xcodebuild build \
  -project SimpleTextEditor.xcodeproj \
  -scheme SimpleTextEditor \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tail -5
```

Expected output ends with: `** BUILD SUCCEEDED **`

If you see `BUILD FAILED`, check the error carefully. Common causes:
- Missing file: verify all files in Step 5–8 were created at exactly the paths listed.
- UUID mismatch: do not edit any UUID in `project.pbxproj`.

- [ ] **Step 10: Initial commit**

```bash
cd "/Volumes/external/Projects 2/test"
git add SimpleTextEditor/ docs/
git commit -m "chore: initial project skeleton (stubs compile, no logic)"
```

---

## Task 2: TextDocument — Tests First, Then Implementation

**Files:**
- Modify: `SimpleTextEditor/SimpleTextEditor/TextDocument.swift`
- Modify: `SimpleTextEditor/SimpleTextEditorTests/SimpleTextEditorTests.swift`

This is the only file with non-trivial logic: UTF-8 encode/decode. We follow TDD strictly.

- [ ] **Step 1: Write the failing tests**

Replace `SimpleTextEditor/SimpleTextEditorTests/SimpleTextEditorTests.swift` entirely:

```swift
import XCTest
@testable import SimpleTextEditor

final class TextDocumentTests: XCTestCase {

    // MARK: - decode(fileWrapper:)

    func test_decode_returnsTextFromValidUTF8Data() throws {
        let expected = "Hello, macOS text editor!"
        let data = expected.data(using: .utf8)!
        let wrapper = FileWrapper(regularFileWithContents: data)

        let result = try TextDocument.decode(fileWrapper: wrapper)

        XCTAssertEqual(result, expected)
    }

    func test_decode_handlesUnicodeAndEmoji() throws {
        let expected = "日本語テスト 🌍"
        let wrapper = FileWrapper(regularFileWithContents: expected.data(using: .utf8)!)

        XCTAssertEqual(try TextDocument.decode(fileWrapper: wrapper), expected)
    }

    func test_decode_throwsOnInvalidUTF8Bytes() {
        // 0xC3 starts a 2-byte sequence; 0x28 '(' is not a valid continuation byte
        let badData = Data([0xC3, 0x28])
        let wrapper = FileWrapper(regularFileWithContents: badData)

        XCTAssertThrowsError(try TextDocument.decode(fileWrapper: wrapper))
    }

    func test_decode_throwsForDirectoryWrapper() {
        let wrapper = FileWrapper(directoryWithFileWrappers: [:])

        XCTAssertThrowsError(try TextDocument.decode(fileWrapper: wrapper))
    }

    func test_decode_handlesEmptyData() throws {
        let wrapper = FileWrapper(regularFileWithContents: Data())

        XCTAssertEqual(try TextDocument.decode(fileWrapper: wrapper), "")
    }

    // MARK: - encode(text:)

    func test_encode_producesRegularFileWrapper() {
        let wrapper = TextDocument.encode(text: "hello")

        XCTAssertNotNil(wrapper.regularFileContents)
    }

    func test_encode_dataDecodesBackToOriginalText() throws {
        let text = "Save this text"
        let wrapper = TextDocument.encode(text: text)

        let data = try XCTUnwrap(wrapper.regularFileContents)
        let decoded = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertEqual(decoded, text)
    }

    // MARK: - Round-trip

    func test_roundTrip_textSurvivesEncodeAndDecode() throws {
        let original = "Round-trip: 日本語 🌍 & ASCII"

        let roundtripped = try TextDocument.decode(fileWrapper: TextDocument.encode(text: original))

        XCTAssertEqual(roundtripped, original)
    }

    // MARK: - init

    func test_init_defaultTextIsEmpty() {
        XCTAssertEqual(TextDocument().text, "")
    }

    func test_init_storesCustomText() {
        XCTAssertEqual(TextDocument(text: "hello").text, "hello")
    }
}
```

- [ ] **Step 2: Run tests — verify they FAIL**

```bash
cd "/Volumes/external/Projects 2/test/SimpleTextEditor"
xcodebuild test \
  -project SimpleTextEditor.xcodeproj \
  -scheme SimpleTextEditor \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | grep -E "(FAILED|error:|test_)"
```

Expected: Tests that reference `TextDocument.decode` and `TextDocument.encode` will fail with a compiler error — those methods don't exist yet on the stub. You should see errors like `value of type 'TextDocument' has no member 'decode'`.

- [ ] **Step 3: Implement TextDocument**

Replace `SimpleTextEditor/SimpleTextEditor/TextDocument.swift` entirely:

```swift
import SwiftUI
import UniformTypeIdentifiers

struct TextDocument: FileDocument {
    var text: String

    static var readableContentTypes: [UTType] { [.plainText] }

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        text = try TextDocument.decode(fileWrapper: configuration.file)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        TextDocument.encode(text: text)
    }

    // MARK: - Testable helpers

    /// Decodes UTF-8 text from a file wrapper. Throws `CocoaError(.fileReadCorruptFile)` on failure.
    static func decode(fileWrapper: FileWrapper) throws -> String {
        guard let data = fileWrapper.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return string
    }

    /// Encodes text as a UTF-8 regular file wrapper.
    static func encode(text: String) -> FileWrapper {
        FileWrapper(regularFileWithContents: text.data(using: .utf8)!)
    }
}
```

- [ ] **Step 4: Run tests — verify they PASS**

```bash
cd "/Volumes/external/Projects 2/test/SimpleTextEditor"
xcodebuild test \
  -project SimpleTextEditor.xcodeproj \
  -scheme SimpleTextEditor \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | grep -E "(PASSED|FAILED|Test Suite)"
```

Expected: All 10 tests pass. Final line: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
cd "/Volumes/external/Projects 2/test"
git add SimpleTextEditor/SimpleTextEditor/TextDocument.swift \
        SimpleTextEditor/SimpleTextEditorTests/SimpleTextEditorTests.swift
git commit -m "feat: implement TextDocument with UTF-8 encode/decode (TDD)"
```

---

## Task 3: NSTextViewWrapper — Real NSTextView with Find Bar

**Files:**
- Modify: `SimpleTextEditor/SimpleTextEditor/NSTextViewWrapper.swift`

- [ ] **Step 1: Replace stub with full implementation**

Replace `SimpleTextEditor/SimpleTextEditor/NSTextViewWrapper.swift` entirely:

```swift
import SwiftUI
import AppKit

/// Bridges NSTextView into SwiftUI. Provides: paste (automatic), undo/redo,
/// native Find bar (Cmd+F), spell check, and plain-text mode.
struct NSTextViewWrapper: NSViewRepresentable {
    @Binding var text: String

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> NSScrollView {
        // NSTextView.scrollableTextView() returns a pre-configured NSScrollView
        // containing a properly sized, vertically resizable NSTextView.
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.isRichText = false                         // plain text only
        textView.allowsUndo = true                          // Cmd-Z / Cmd-Shift-Z
        textView.usesFindBar = true                         // inline Find bar (Cmd-F)
        textView.isIncrementalSearchingEnabled = true       // live highlighting
        textView.isContinuousSpellCheckingEnabled = true    // red underlines
        textView.isAutomaticQuoteSubstitutionEnabled = false // keep straight quotes
        textView.isAutomaticDashSubstitutionEnabled = false  // keep double dashes
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.delegate = context.coordinator

        textView.string = text
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        // Guard against unnecessary resets that would move the cursor.
        if textView.string != text {
            textView.string = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NSTextViewWrapper

        init(_ parent: NSTextViewWrapper) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
```

- [ ] **Step 2: Build to confirm compilation**

```bash
cd "/Volumes/external/Projects 2/test/SimpleTextEditor"
xcodebuild build \
  -project SimpleTextEditor.xcodeproj \
  -scheme SimpleTextEditor \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tail -3
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd "/Volumes/external/Projects 2/test"
git add SimpleTextEditor/SimpleTextEditor/NSTextViewWrapper.swift
git commit -m "feat: implement NSTextViewWrapper with NSTextFinder find bar"
```

---

## Task 4: ContentView — Root SwiftUI View

**Files:**
- Modify: `SimpleTextEditor/SimpleTextEditor/ContentView.swift`

- [ ] **Step 1: Replace stub with full implementation**

Replace `SimpleTextEditor/SimpleTextEditor/ContentView.swift` entirely:

```swift
import SwiftUI

struct ContentView: View {
    @Binding var document: TextDocument

    var body: some View {
        NSTextViewWrapper(text: $document.text)
            .frame(minWidth: 500, minHeight: 400)
    }
}

// MARK: - Preview
#Preview {
    ContentView(document: .constant(TextDocument(text: "Preview text here.\nLine two.")))
}
```

- [ ] **Step 2: Build to confirm compilation**

```bash
cd "/Volumes/external/Projects 2/test/SimpleTextEditor"
xcodebuild build \
  -project SimpleTextEditor.xcodeproj \
  -scheme SimpleTextEditor \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tail -3
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd "/Volumes/external/Projects 2/test"
git add SimpleTextEditor/SimpleTextEditor/ContentView.swift
git commit -m "feat: implement ContentView hosting NSTextViewWrapper"
```

---

## Task 5: App Entry Point — Wire DocumentGroup

**Files:**
- Modify: `SimpleTextEditor/SimpleTextEditor/SimpleTextEditorApp.swift`

The stub is already correct. Verify it, then run the full test suite as a final gate before the next stage.

- [ ] **Step 1: Verify SimpleTextEditorApp.swift is correct**

Confirm `SimpleTextEditor/SimpleTextEditor/SimpleTextEditorApp.swift` contains exactly:

```swift
import SwiftUI

@main
struct SimpleTextEditorApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: TextDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
```

If the stub in Task 1 was created correctly, no change is needed.

- [ ] **Step 2: Run full test suite**

```bash
cd "/Volumes/external/Projects 2/test/SimpleTextEditor"
xcodebuild test \
  -project SimpleTextEditor.xcodeproj \
  -scheme SimpleTextEditor \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | grep -E "(PASSED|FAILED|Test Suite|TEST SUCCEEDED|TEST FAILED)"
```

Expected: 10 tests passed, `** TEST SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd "/Volumes/external/Projects 2/test"
git add SimpleTextEditor/SimpleTextEditor/SimpleTextEditorApp.swift
git commit -m "feat: wire DocumentGroup app entry point"
```

---

## Task 6: Open in Xcode and Run

The app is complete. Open it in Xcode for signing configuration and a live run.

- [ ] **Step 1: Open the project in Xcode**

```bash
open "/Volumes/external/Projects 2/test/SimpleTextEditor/SimpleTextEditor.xcodeproj"
```

- [ ] **Step 2: Set your development team**

In Xcode:
1. Click `SimpleTextEditor` in the Project Navigator (left panel)
2. Select the `SimpleTextEditor` **target** (not the project)
3. Go to **Signing & Capabilities** tab
4. Set **Team** to your Apple ID (add one via Xcode > Settings > Accounts if needed)
5. Xcode will auto-manage the provisioning profile

> Without a team set, builds will fail with a code-signing error when running on device/simulator. For testing without an Apple ID, use `CODE_SIGNING_ALLOWED=NO` via `xcodebuild` only (not for running the `.app`).

- [ ] **Step 3: Run the app**

Press **Cmd+R** (or Product > Run).

The app will launch. You should see an empty editor window with the title "Untitled".

- [ ] **Step 4: Manual acceptance checklist**

Work through each item. All must pass.

**Paste:**
- [ ] Copy any text from another app (e.g., from Safari or Terminal)
- [ ] Click in the text editor window
- [ ] Press **Cmd+V** — text should appear at the cursor

**Find:**
- [ ] Type several words in the editor (e.g., "hello world hello")
- [ ] Press **Cmd+F** — the native Find bar appears at the bottom of the window
- [ ] Type "hello" — both occurrences should be highlighted in yellow
- [ ] Press **Return** or the chevron buttons to jump between matches
- [ ] Press **Escape** to dismiss the Find bar

**Save:**
- [ ] Type some text in the editor
- [ ] Notice the dot (•) in the window's close button — this is the "unsaved changes" indicator
- [ ] Press **Cmd+S** — a Save dialog appears (first save of an Untitled document)
- [ ] Choose a location and save as a `.txt` file
- [ ] The dot disappears from the close button
- [ ] Press **Cmd+S** again — it saves silently (no dialog, because the file now has a path)

**Open:**
- [ ] Press **Cmd+O** — an Open dialog appears
- [ ] Navigate to a `.txt` file and open it — the content loads in a new window

**Undo/Redo:**
- [ ] Type some text, then press **Cmd+Z** — text is removed character by character
- [ ] Press **Cmd+Shift+Z** — text is restored

---

## Self-Review

### Spec Coverage

| Requirement | Covered by |
|---|---|
| Paste text | NSTextView automatic responder chain (Task 3) |
| Save file | DocumentGroup + FileDocument (Tasks 1, 2, 5) |
| Find word | NSTextFinder via `usesFindBar = true` (Task 3) |
| macOS 13+ target | `MACOSX_DEPLOYMENT_TARGET = 13.0` in project.pbxproj (Task 1) |
| App runs as .app bundle | Xcode project with PBXNativeTarget (Task 1) |
| Unit tests | TextDocumentTests covering encode/decode (Task 2) |

### No Placeholders Scan

- All code blocks contain complete, runnable Swift code. No "TBD" or "TODO" markers.
- All commands include expected output.
- All file paths are absolute or clearly relative to the project root.
- Type names and method signatures are consistent across all tasks (`TextDocument.decode(fileWrapper:)`, `TextDocument.encode(text:)`, `NSTextViewWrapper`, `ContentView`, `TextDocument`).
