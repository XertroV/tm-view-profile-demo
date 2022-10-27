const string PageUID = "AutosaveGhosts";
uint g_numSaved = 0;
bool permissionsOkay = false;

void Main() {
    CheckRequiredPermissions();
    MLHook::RequireVersionApi('0.3.2');
    @hook = AutosaveGhostEvents();
    startnew(InitCoro);
}

void CheckRequiredPermissions() {
    permissionsOkay = Permissions::CreateLocalReplay()
        && Permissions::PlayAgainstReplay()
        && Permissions::OpenReplayEditor();
    if (!permissionsOkay) {
        NotifyWarn("You appear not to have club access.\n\nThis plugin won't work, sorry :(.");
        while(true) { sleep(10000); } // do nothing forever
    }
}

void OnDestroyed() { _Unload(); }
void OnDisabled() { _Unload(); }
void _Unload() {
    trace('_Unload, unloading hooks and removing injected ML');
    // MLHook::UnregisterMLHooksAndRemoveInjectedML();
    MLHook::UnregisterMLHookFromAll(hook);
    MLHook::RemoveInjectedMLFromPlayground(PageUID);
}

AutosaveGhostEvents@ hook = null;
void InitCoro() {
    if (!permissionsOkay) return;
    // MLHook::RegisterMLHook(hook);
    MLHook::RegisterMLHook(hook, PageUID + "_SavedGhost");
    sleep(50);
    // ml load
    MLHook::InjectManialinkToPlayground(PageUID, AUTOSAVEGHOSTS_SCRIPT_TXT, true);
    startnew(MainCoro);
    sleep(200);
    UpdateAllMLVariables(); // send stuff to ML in case we're loading while in a map; but wait a few frames
}

void MainCoro() {
    if (!permissionsOkay) return;
    uint lastDateUpdate = 0;
    while (true) {
        yield();
        if (lastMap != CurrentMap) {
            lastMap = CurrentMap;
            OnMapChange();
        }
        // // 5 second resolution instead of 1 but cuts down on log msgs about preparing outbound
        // if (lastDateUpdate + 5000 < Time::Now) {
        //     lastDateUpdate = Time::Now;
        //     UpdateMLDate();
        // }
    }
}

void OnMapChange() {
    startnew(UpdateAllMLVariables);
}

void UpdateAllMLVariables() {
    UpdateMLAutosaveActive();
}

void ToggleAutosaveActive() {
    S_AutosaveActive = !S_AutosaveActive;
    UpdateMLAutosaveActive();
}

// crucially: used in UpdateMLAutosaveActive
bool get_AutosaveCurrentlyActive() {
    if (!S_AutosaveActive) return false;
    if (S_DisableForLocal && GetApp().PlaygroundScript !is null) return false;
    return true;
}

void UpdateMLAutosaveActive() {
    MLHook::Queue_MessageManialinkPlayground(PageUID, {"AutosaveActive", AutosaveCurrentlyActive ? "True" : "False"});
}

void ForceSaveAllGhosts() {
    NotifyForceSave();
    MLHook::Queue_MessageManialinkPlayground(PageUID, {"ResetAndSaveAll"});
    UpdateAllMLVariables();
}

/* Hook Outgoing Notification Events */
class AutosaveGhostEvents : MLHook::HookMLEventsByType {
    AutosaveGhostEvents() {
        super(PageUID);
        startnew(CoroutineFunc(this.MainCoro));
    }

    MLHook::PendingEvent@[] pending;
    void MainCoro() {
        while (true) {
            yield();
            while (pending.Length > 0) {
                ProcessEvent(pending[pending.Length - 1]);
                pending.RemoveLast();
            }
        }
    }

    void OnEvent(MLHook::PendingEvent@ event) override {
        pending.InsertLast(event);
    }

    void ProcessEvent(MLHook::PendingEvent@ event) {
        if (event.type.EndsWith("SavedGhost")) {
            OnSavedGhost(event);
        }
    }

    void OnSavedGhost(MLHook::PendingEvent@ event) {
        g_numSaved++;
        if (event.data.Length < 0) {
            warn("OnSavedGhost didn't get a file name!");
        } else {
            NotifySaved(event.data[0]);
        }
    }

    // void OnSavedGhost(MLHook::PendingEvent@ event) {
    // }
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
    UpdateAllMLVariables();
}

const string get_HotkeyStr() {
    return S_HotkeyEnabled ? tostring(S_Hotkey) : "";
}

bool i_shiftKeyDown = false;
/** Called whenever a key is pressed on the keyboard. See the documentation for the [`VirtualKey` enum](https://openplanet.dev/docs/api/global/VirtualKey). */
UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    if (!permissionsOkay) return UI::InputBlocking::DoNothing;
    if (key == VirtualKey::Shift) i_shiftKeyDown = down;
    if (down) {
        if (S_HotkeyEnabled && key == S_Hotkey) {
            ToggleAutosaveActive();
        }
    }
    return UI::InputBlocking::DoNothing;
}

void RenderInterface() {
}

void RenderMenu() {
    if (!permissionsOkay) return;
    if (UI::MenuItem("\\$f22" + Icons::Circle + "\\$z Autosave Ghosts", HotkeyStr, S_AutosaveActive)) {
        ToggleAutosaveActive();
    }
}

bool isMenuMainHovered = false;
/** Render function called every frame intended only for menu items in the main menu of the `UI`.*/
void RenderMenuMain() {
    if (!permissionsOkay) return;
    isMenuMainHovered = false;
    bool shouldRender = S_MenuBarQuickToggleOff && S_AutosaveActive || S_MenuBarQuickToggleOn && !S_AutosaveActive;
    if (!shouldRender) return;
    string label = S_AutosaveActive
        ? ("\\$f22" + Icons::Circle + "\\$z Autosaving Ghosts (" + g_numSaved + ")")
        : ("\\$dd3" + Icons::Pause + "\\$z Autosave Ghosts");
    bool wasClicked = UI::MenuItem(label, HotkeyStr);
    string hotkeyExtra = S_HotkeyEnabled ? "\n\\$bbbHotkey: " + HotkeyStr + "\\$z" : "";
    string mainTooltip = (S_AutosaveActive ? "Click to disable autosaving new ghosts.\nShift click to force-save a replay of all current personal ghosts." : "Click to start autosaving new ghosts.");
    AddSimpleTooltip(mainTooltip + hotkeyExtra);
    if (wasClicked && S_AutosaveActive && i_shiftKeyDown) {
        startnew(ForceSaveAllGhosts);
    } else if (wasClicked && !i_shiftKeyDown) {
        ToggleAutosaveActive();
    }
}

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

/*

settings

*/

[Setting category="Autosave Ghosts" name="Autosave Active?" description="While active, this plugin will autosave replays. When not active, it will sit in the background, biding its time, waiting for you to reactivate it."]
bool S_AutosaveActive = true;

[Setting category="Autosave Ghosts" name="MenuBar Quick Toggle Off" description="Show a button in the main menu bar to quickly toggle autosaving off (stop saving replays)."]
bool S_MenuBarQuickToggleOff = true;

[Setting category="Autosave Ghosts" name="MenuBar Quick Toggle On" description="Show a button in the main menu bar to quickly toggle autosaving on (start saving replays)."]
bool S_MenuBarQuickToggleOn = false;

[Setting category="Autosave Ghosts" name="Disable for Local Runs" description="When checked, replays will not be autosaved for local runs."]
bool S_DisableForLocal = false;

[Setting category="Autosave Ghosts" name="Hotkey Enabled" description="The hotkey will only work if this is checked."]
bool S_HotkeyEnabled = true;

[Setting category="Autosave Ghosts" name="Hotkey" description="Hotkey to toggle saving or not."]
VirtualKey S_Hotkey = VirtualKey::F7;
