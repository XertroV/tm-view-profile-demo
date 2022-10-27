const string PageUID = "AutosaveGhosts";
uint g_numSaved = 0;

void Main() {
    MLHook::RequireVersionApi('0.3.2');
    @hook = AutosaveGhostEvents();
    startnew(InitCoro);
}

void OnDestroyed() { _Unload(); }
void OnDisabled() { _Unload(); }
void _Unload() {
    trace('_Unload, unloading hooks and removing injected ML');
    MLHook::UnregisterMLHooksAndRemoveInjectedML();
}

AutosaveGhostEvents@ hook = null;
void InitCoro() {
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
    uint lastDateUpdate = 0;
    while (true) {
        yield();
        if (lastMap != CurrentMap) {
            lastMap = CurrentMap;
            OnMapChange();
        }
        // 5 second resolution instead of 1 but cuts down on log msgs about preparing outbound
        if (lastDateUpdate + 5000 < Time::Now) {
            lastDateUpdate = Time::Now;
            UpdateMLDate();
        }
    }
}

void OnMapChange() {
    startnew(UpdateAllMLVariables);
}

void UpdateAllMLVariables() {
    MLHook::Queue_MessageManialinkPlayground(PageUID, {"MapNameSafe", MapNameSafe});
    MLHook::Queue_MessageManialinkPlayground(PageUID, {"AutosaveActive", S_AutosaveActive ? "True" : "False"});
    UpdateMLDate();
}

void UpdateMLDate() {
    MLHook::Queue_MessageManialinkPlayground(PageUID, {"CurrentDateText", CurrentDateText});
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

/** Called when a setting in the settings panel was changed. */
void OnSettingsChanged() {
    UpdateAllMLVariables();
}

void RenderInterface() {
}

void RenderMenu() {
    if (UI::MenuItem("\\$f22" + Icons::Circle + "\\$z Autosave Ghosts", "", S_AutosaveActive)) {
        S_AutosaveActive = !S_AutosaveActive;
    }
}

/** Render function called every frame intended only for menu items in the main menu of the `UI`.*/
void RenderMenuMain() {
    if (!S_AutosaveActive) return;
    bool wasClicked = UI::MenuItem("\\$f22" + Icons::Circle + "\\$z Autosaving Ghosts (" + g_numSaved + ")");
    AddSimpleTooltip("Click to disable autosaving new ghosts.");
    if (wasClicked) {
        S_AutosaveActive = !S_AutosaveActive;
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
