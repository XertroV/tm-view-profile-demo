const string PageUID = "AutosaveGhosts";

void Main() {
    MLHook::RequireVersionApi('0.3.2');
    startnew(InitCoro);
}

void OnDestroyed() { _Unload(); }
void OnDisabled() { _Unload(); }
void _Unload() {
    trace('_Unload, unloading hooks and removing injected ML');
    // MLHook::UnregisterMLHooksAndRemoveInjectedML();
}


void InitCoro() {
    // ml load
    MLHook::InjectManialinkToPlayground(PageUID, AUTOSAVEGHOSTS_SCRIPT_TXT, true);
    startnew(MainCoro);
}

void MainCoro() {
    uint lastDateUpdate = 0;
    while (true) {
        yield();
        if (lastMap != CurrentMap) {
            lastMap = CurrentMap;
            OnMapChange();
        }
        if (lastDateUpdate + 1000 < Time::Now) {
            lastDateUpdate = Time::Now;
            UpdateMLDate();
        }
    }
}

void OnMapChange() {
    MLHook::Queue_MessageManialinkPlayground(PageUID, {"MapNameSafe", MapNameSafe});
    UpdateMLDate();
}

void UpdateMLDate() {
    MLHook::Queue_MessageManialinkPlayground(PageUID, {"CurrentDateText", CurrentDateText});
}

/** Called when a setting in the settings panel was changed. */
void OnSettingsChanged() {}

void RenderInterface() {
}

void RenderMenu() {
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
