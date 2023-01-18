const string PageUID = "ViewProfile";
uint g_numSaved = 0;
bool permissionsOkay = false;

void Main() {
    CheckRequiredPermissions();
    MLHook::RequireVersionApi('0.3.2');
    startnew(InitCoro);
    startnew(InjectMenu);
    startnew(PatchProfilePage);
}

void CheckRequiredPermissions() {
    permissionsOkay = true;
    if (!permissionsOkay) {
        NotifyWarn("You appear not to have club access.\n\nThis plugin won't work, sorry :(.");
        while(true) { sleep(10000); } // do nothing forever
    }
}

void OnDestroyed() { _Unload(); }
void OnDisabled() { _Unload(); }
void _Unload() {
    trace('_Unload, unloading hooks and removing injected ML');
    MLHook::RemoveInjectedMLFromPlayground(PageUID);
}

void InitCoro() {
    if (!permissionsOkay) return;
    sleep(50);
    // ml load
    MLHook::InjectManialinkToPlayground(PageUID, VIEWPROFILE_SCRIPT_TXT, true);
}

void ToPlaygroundML_ViewProfile(const string &in wsid) {
    MLHook::Queue_MessageManialinkPlayground(PageUID, {"OpenProfile", wsid});
}


void InjectMenu() {
    sleep(100);
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto mlApp = app.MenuManager.MenuCustom_CurrentManiaApp;
    auto layer = mlApp.UILayerCreate();
    layer.ManialinkPage = VIEWPROFILEMENU_SCRIPT_TXT;
}



void PatchProfilePage() {
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto mlApp = app.MenuManager.MenuCustom_CurrentManiaApp;
    if (mlApp.UILayers.Length == 0) throw("mlApp.UILayers.Length == 0");
    for (uint i = mlApp.UILayers.Length - 1; i >= 0; i--) {
        auto @layer = mlApp.UILayers[i];
        if (!layer.ManialinkPageUtf8.SubStr(0, 100).Contains('<manialink name="Page_Profile" version="3">'))
            continue;
        auto currHash = Crypto::Sha256(layer.ManialinkPageUtf8);
        string expectedHash = "694f25109245a3a87a6cd57c396937bdebe6925dbfa1a58e1f6dbdedd094d72a";
        print("Current profile page hash: " + currHash);
        if (currHash != expectedHash) {
            warn("Current hash != expected hash. Skipping patching (likely already patched, or a game update).");
            return;
        }
        string origML = layer.ManialinkPageUtf8;
        string toReplace = """case Router_Router::C_Event_EnteringRoute: {
			ComponentProfilePlayerInfo_SetUser(LocalUser);""";
        string replacement = """case Router_Router::C_Event_EnteringRoute: {
			declare Text[Text] Query = Router_Router::GetCurrentRouteQuery(This);
			if (!Query.existskey("AccountId")) {
				ComponentProfilePlayerInfo_SetUser(LocalUser);
				//ComponentProfilePlayerInfo_EnableMyAccessButton(True);
				ComponentProfilePlayerInfo_EnableGarageButton(True);
				//ComponentProfilePlayerInfo_EnableZoneSelection(True);
			} else {
				ComponentProfilePlayerInfo_SetUserAccountId(Query["AccountId"]);
				ComponentProfilePlayerInfo_EnableGarageButton(False);
			}""";
        layer.ManialinkPageUtf8 = origML.Replace(toReplace, replacement);
        break;
    }
}

void NotifySaved(const string &in filename) {
    string msg = "Saved ghost and replay: " + filename;
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg, vec4(.1, .6, .3, .3), 7500);
    trace(msg);
}
void NotifyForceSave() {
    string msg = "Force-saving all of your ghosts (if none show up, there probably are none atm)";
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg, vec4(.1, .6, .3, .3), 7500);
    trace(msg);
}

void NotifyWarn(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg, vec4(1, .5, .1, .5), 10000);
    warn(msg);
}


/** Called when a setting in the settings panel was changed. */
void OnSettingsChanged() {
    if (!permissionsOkay) return;
    // UpdateAllMLVariables();
}

// const string get_HotkeyStr() {
//     return S_HotkeyEnabled ? tostring(S_Hotkey) : "";
// }

// bool i_shiftKeyDown = false;
// /** Called whenever a key is pressed on the keyboard. See the documentation for the [`VirtualKey` enum](https://openplanet.dev/docs/api/global/VirtualKey). */
// UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
//     if (!permissionsOkay) return UI::InputBlocking::DoNothing;
//     if (key == VirtualKey::Shift) i_shiftKeyDown = down;
//     if (down) {
//         if (S_HotkeyEnabled && key == S_Hotkey) {
//             ToggleAutosaveActive();
//         }
//     }
//     return UI::InputBlocking::DoNothing;
// }

string playerName;
string playerWSID;

void RenderInterface() {
    return;
    UI::SetNextWindowSize(500, 500, UI::Cond::FirstUseEver);
    if (UI::Begin("View Profile")) {
        UI::Text("Player last selected: " + playerName + "   \\$888" + playerWSID);
        UI::Text("");
        UI::Text("");
        UI::Text("");
        UI::Text("");
        if (UI::Button("View a random players profile")) {
            int nonce = Math::Rand(10000, 10000000);
            auto cp = cast<CSmArenaClient>(GetApp().CurrentPlayground);
            if (cp !is null && cp.Arena.Players.Length > 0) {
                auto ix = nonce % cp.Arena.Players.Length;
                auto p = cp.Arena.Players[ix];
                playerName = p.User.Name;
                playerWSID = p.User.WebServicesUserId;
                ToPlaygroundML_ViewProfile(p.User.WebServicesUserId);
            }
        }
    }
    UI::End();
}

// void RenderMenu() {
//     if (!permissionsOkay) return;
//     if (UI::MenuItem("\\$f22" + Icons::Circle + "\\$z Autosave Ghosts", HotkeyStr, S_AutosaveActive)) {
//         ToggleAutosaveActive();
//     }
// }

// bool isMenuMainHovered = false;
// /** Render function called every frame intended only for menu items in the main menu of the `UI`.*/
// void RenderMenuMain() {
//     if (!permissionsOkay) return;
//     isMenuMainHovered = false;
//     bool shouldRender = S_MenuBarQuickToggleOff && S_AutosaveActive || S_MenuBarQuickToggleOn && !S_AutosaveActive;
//     if (!shouldRender) return;

// 	string label, recColor, labelColor;
// 	if (Time::Stamp % 2 == 1 && S_OscillateColors) {
// 		recColor = "\\$822";
// 		labelColor = "\\$666";
// 	} else {
// 		recColor = "\\$f22";
// 		labelColor = "\\$z";
// 	}

// 	if (S_MenuBarFloatOnRight) {
// 		label = S_AutosaveActive
// 			? (recColor + Icons::Circle + labelColor + " REC (" + g_numSaved + ")")
// 			: ("\\$dd3" + Icons::Pause + " REC");
// 	} else {
// 		label = S_AutosaveActive
// 			? ("\\$f22" + Icons::Circle + "\\$z Autosaving Ghosts (" + g_numSaved + ")")
// 			: ("\\$dd3" + Icons::Pause + "\\$z Autosave Ghosts");
// 	}

// 	auto pos = UI::GetCursorPos();
// 	if (S_MenuBarFloatOnRight) {
// 	    auto textSize = Draw::MeasureString(label);
// 		UI::SetCursorPos(vec2(UI::GetWindowSize().x - textSize.x - S_MenuBarFloatOffset - UI::GetStyleVarVec2(UI::StyleVar::WindowPadding).x * 1.5, pos.y));
// 	}

// 	bool wasClicked = UI::MenuItem(label, HotkeyStr);

// 	if (S_MenuBarFloatOnRight) {
// 		UI::SetCursorPos(pos);
// 	}

//     string hotkeyExtra = S_HotkeyEnabled ? "\n\\$bbbHotkey: " + HotkeyStr + "\\$z" : "";
//     string mainTooltip = (S_AutosaveActive ? "Click to disable autosaving new ghosts.\nShift click to force-save a replay of all current personal ghosts." : "Click to start autosaving new ghosts.");
//     AddSimpleTooltip(mainTooltip + hotkeyExtra);
//     if (wasClicked && S_AutosaveActive && i_shiftKeyDown) {
//         startnew(ForceSaveAllGhosts);
//     } else if (wasClicked && !i_shiftKeyDown) {
//         ToggleAutosaveActive();
//     }
// }

string lastMap = "";
string get_CurrentMap() {
    auto map = GetApp().RootMap;
    if (map is null) return "";
    // return map.EdChallengeId;
    return map.MapInfo.MapUid;
}

string get_MapNameSafe() {
    auto map = GetApp().RootMap;
    if (map is null) return "";
    return StripFormatCodes(map.MapName);
}

string get_CurrentDateText() {
    auto mpsapi = cast<CGameManiaPlanet>(GetApp()).ManiaPlanetScriptAPI;
    return mpsapi.CurrentLocalDateText.Replace("/", "-").Replace(":", "-");
}
