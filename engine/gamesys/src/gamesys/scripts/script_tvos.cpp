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

#include "script_tvos.h"

#if defined(DM_PLATFORM_TVOS)

#include <script/script.h>
#include <platform/window.hpp>
#include "../gamesys.h"

namespace dmGameSystem
{
    static HWindow g_Window = 0;

    /*# tvOS API documentation
     *
     * Functions specific to tvOS. The module exists only on tvOS.
     *
     * @document
     * @name tvOS
     * @namespace tvos
     * @language Lua
     */

    /*# sets what the Menu button of the remote does
     *
     * The Menu button (the Back button on newer Siri Remotes) goes to the tvOS home screen by default,
     * as Apple asks of an app's first screen. When it is the back key, it is reported as `KEY_BACK`
     * (as the back button on Android) and the app stays.
     *
     * @name tvos.set_menu_is_back
     * @param menu_is_back [type:boolean] `true` to make Menu the back key, `false` to let it go to the home screen
     * @examples
     *
     * Leave the app from the start screen, go back everywhere else:
     *
     * ```lua
     * if tvos then
     *     tvos.set_menu_is_back(not at_start_screen)
     * end
     * ```
     */
    static int TVOS_SetMenuIsBack(lua_State* L)
    {
        DM_LUA_STACK_CHECK(L, 0);
        luaL_checktype(L, 1, LUA_TBOOLEAN);
        dmPlatform::SetDeviceState(g_Window, WINDOW_DEVICE_STATE_MENU_IS_BACK, lua_toboolean(L, 1));
        return 0;
    }

    /*# sets whether the remote's touch surface is reported as touches
     *
     * The touch surface of the Siri Remote is not reported as touches by default: a touch on the remote is not a
     * touch on the screen, and a thumb resting on the surface would press whatever is under the matching point.
     * When it is on, the remote's touches are reported as touches and as the left mouse button, like a trackpad:
     * a touch starts in the middle of the screen and moves with the thumb.
     *
     * The touch surface is also the left stick of the remote's gamepad, which needs no setting.
     *
     * @name tvos.set_remote_touch
     * @param remote_touch [type:boolean] `true` to report the remote's touches, `false` to let them go to tvOS
     * @examples
     *
     * Move a pointer with the touch surface in a drawing mode:
     *
     * ```lua
     * if tvos then
     *     tvos.set_remote_touch(true)
     * end
     * ```
     */
    static int TVOS_SetRemoteTouch(lua_State* L)
    {
        DM_LUA_STACK_CHECK(L, 0);
        luaL_checktype(L, 1, LUA_TBOOLEAN);
        dmPlatform::SetDeviceState(g_Window, WINDOW_DEVICE_STATE_REMOTE_TOUCH, lua_toboolean(L, 1));
        return 0;
    }

    static const luaL_reg Module_methods[] =
    {
        {"set_menu_is_back", TVOS_SetMenuIsBack},
        {"set_remote_touch", TVOS_SetRemoteTouch},
        {0, 0}
    };

    void ScriptTVOSRegister(const ScriptLibContext& context)
    {
        lua_State* L = context.m_LuaState;
        DM_LUA_STACK_CHECK(L, 0);
        g_Window = context.m_Window;
        luaL_register(L, "tvos", Module_methods);
        lua_pop(L, 1);
    }
}

#else

namespace dmGameSystem
{
    void ScriptTVOSRegister(const ScriptLibContext& context)
    {
    }
}

#endif
