// Copyright 2020-2026 The Defold Foundation
// Copyright 2014-2020 King
// Copyright 2009-2014 Ragnar Svensson, Christian Murray
// Licensed under the Defold License version 1.0 (the "License"); you may not use
// this file except in compliance with the License.
//
// You may obtain a copy of the License, together with FAQs at
// https://www.defold.com/license
//
// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

package com.dynamo.bob.bundle;

import com.dynamo.bob.Platform;

// A tvOS bundle is made like an iOS one, from the [tvos] section of game.project
@BundlerParams(platforms = {"arm64-tvos", "arm64_sim-tvos"})
public class TvOSBundler extends IOSBundler {

    @Override
    protected String getPlatformSection() {
        return "tvos";
    }

    @Override
    protected String getPlatformDisplayName() {
        return "tvOS";
    }

    @Override
    protected boolean isSimulator(Platform platform) {
        return platform == Platform.Arm64TvOSSim;
    }

    @Override
    protected String getDeviceSdkName() {
        return "appletvos";
    }

    @Override
    protected String getSimulatorSdkName() {
        return "appletvsimulator";
    }

    @Override
    protected String getSimulatorPlatformName() {
        return "AppleTVSimulator";
    }

    @Override
    protected boolean hasInterfaceOrientations() {
        return false;
    }

    // The app icon and the Top Shelf images of tvOS come from the asset catalog in tvos.icons_asset
    @Override
    protected void copyIcons(BundleHelper helper) {
    }
}
