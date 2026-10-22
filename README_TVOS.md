# tvOS

tvOS builds as iOS. The engine defines `DM_PLATFORM_IOS` and also `DM_PLATFORM_TVOS` (and `DM_PLATFORM_TVOS_SIMULATOR` on the simulator), and Objective-C code checks `TARGET_OS_TV`. Most of the iOS code is shared, so changes to the iOS platform layer should be built for tvOS as well.

The platforms are:

* `arm64-tvos` - Apple TV HD and Apple TV 4K
* `arm64_sim-tvos` - the tvOS Simulator on Apple Silicon Macs

## Setup

* [Install Xcode](./README_BUILD.md#xcode) and the tvOS platform (Xcode -> Settings -> Components).
* Install and build the dependencies for each platform (also repeat this after `distclean`):

        $ ./scripts/build.py --platform=arm64-tvos install_ext
        $ ./scripts/build.py --platform=arm64_sim-tvos install_ext

## Build

    $ ./scripts/build.py --platform=arm64-tvos --skip-tests build_engine -- --skip-build-tests
    $ ./scripts/build.py --platform=arm64_sim-tvos --skip-tests build_engine -- --skip-build-tests

Bob includes the tvOS engines when they are in `DYNAMO_HOME`:

    $ ./scripts/build.py build_bob --skip-tests --keep-bob-uncompressed

## Differences from iOS

* **Graphics** - Metal is the only graphics backend. There is no OpenGL ES, Vulkan or MoltenVK.
* **Window** - There are no interface orientations, reserved regions or accelerometer (CoreMotion).
* **Input** - The presses of the Siri Remote and of other remotes are keys: the arrows, Select is `KEY_ENTER` and Menu is `KEY_BACK`. The Siri Remote is also a gamepad (`GCMicroGamepad`), and its touch surface is the left stick. Menu leaves the app unless `tvos.set_menu_is_back(true)` is called. The touch surface produces touches only after `tvos.set_remote_touch(true)`, since a touch on the remote is not a touch on the screen. See the `tvos` Lua module.
* **Storage** - tvOS gives apps no persistent files. `sys.save()` keeps the saved tables in `NSUserDefaults`, which is small, so large save data should go to iCloud.
* **Bundle** - The `[tvos]` section of `game.project` has the bundle settings. The app icon and the Top Shelf images of tvOS are layered images, and come from the asset catalog in `tvos.icons_asset`.

## Running on the tvOS Simulator

Create and boot a simulator:

    $ xcrun simctl list runtimes available
    $ xcrun simctl create "Defold Apple TV" com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-3rd-generation-1080p <runtime-id>
    $ xcrun simctl boot "Defold Apple TV"

Bundle a project for the simulator, then install and launch it:

    $ java -jar bob.jar --platform arm64_sim-tvos --architectures arm64_sim-tvos --archive --bundle-output build/tvos build bundle
    $ xcrun simctl install booted build/tvos/<title>.app
    $ xcrun simctl launch --console booted <tvos.bundle_identifier>

## Running on an Apple TV

Pair the Apple TV with Xcode (Window -> Devices and Simulators). The Apple TV must be on the same network as the Mac. Bundle with a signing identity and a provisioning profile that includes the Apple TV, then install and launch the app with `devicectl`:

    $ java -jar bob.jar --platform arm64-tvos --architectures arm64-tvos --archive --identity <identity> --mobileprovisioning <profile> --bundle-output build/tvos build bundle
    $ xcrun devicectl list devices
    $ xcrun devicectl device install app --device <identifier> build/tvos/<title>.app
    $ xcrun devicectl device process launch --device <identifier> --console <tvos.bundle_identifier>

The editor does the same from Project -> Bundle -> tvOS Application, with "Install on connected device".

## Native Extensions

Extensions use the `tvos` and `arm64-tvos` (or `arm64_sim-tvos`) folders for libraries and manifests. The build server needs the tvOS SDKs in `PLATFORMSDK_DIR` and the `TVOS_VERSION` and `TVOS_VERSION_MIN` variables, see `share/extender/build_input.yml`.
