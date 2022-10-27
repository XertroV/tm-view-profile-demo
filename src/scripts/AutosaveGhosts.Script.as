const string AUTOSAVEGHOSTS_SCRIPT_TXT = """
// one line indent otherwise they're treated as compiler preprocessor statements by openplanet
 #Const C_PageUID "AutosaveGhosts"
 #Include "TextLib" as TL


declare Text G_PreviousMapUid;

// logging function, should be "MLHook_LogMe_" + PageUID
Void MLHookLog(Text msg) {
    SendCustomEvent("MLHook_LogMe_"^C_PageUID, [msg]);
}

/// Convert a C++ array to a script array
Integer[] ToScriptArray(Integer[] _Array) {
	return _Array;
}

declare Boolean MapChanged;

Void CheckMapChange() {
    if (Map != Null && Map.MapInfo.MapUid != G_PreviousMapUid) {
        G_PreviousMapUid = Map.MapInfo.MapUid;
        MapChanged = True;
    } else {
        MapChanged = False;
    }
}

// settings and stuff from angelscript
declare Text CurrentDateText;
declare Boolean SetCurrentDateText;
declare Text MapNameSafe;
declare Boolean SetMapNameSafe;
declare Boolean AutosaveActive;
declare Boolean SetAutosaveActive;

Void CheckIncoming() {
    declare Text[][] MLHook_Inbound_AutosaveGhosts for ClientUI;
    foreach (Event in MLHook_Inbound_AutosaveGhosts) {
        if (Event.count < 2) {
            MLHookLog("Skipped unknown incoming event: " ^ Event);
            continue;
        } else if (Event[0] == "CurrentDateText") {
            CurrentDateText = Event[1];
            SetCurrentDateText = True;
        } else if (Event[0] == "MapNameSafe") {
            MapNameSafe = Event[1];
            SetMapNameSafe = True;
        } else if (Event[0] == "AutosaveActive") {
            AutosaveActive = Event[1] == "True";
            SetAutosaveActive = True;
        } else {
            MLHookLog("Skipped unknown incoming event: " ^ Event);
            continue;
        }
        // MLHookLog("Processed Incoming Event: "^Event[0]);
    }
    MLHook_Inbound_AutosaveGhosts = [];
}

Text GetGhostFileName(CGhost Ghost) {
    declare Text Name = Ghost.Nickname;
    declare Integer GTime = Ghost.Result.Time;
    declare Text TheDate = TL::Replace(TL::Replace(System.CurrentLocalDateText, "/", "-"), ":", "-");
    // TheDate = CurrentDateText;
    declare Text MapName = MapNameSafe;
    return "AutosavedGhosts\\" ^ MapName ^ "\\" ^ TheDate ^ "-" ^ MapName ^ "-" ^ Name ^ "-" ^ GTime ^ "ms.Replay.gbx";
}

declare Boolean[Ident] SeenGhosts;
declare Integer[][][Integer] SeenTimes;
declare Integer NbLastSeen;
declare Integer OnlySaveAfter;

// will only return true for a ghost the first time it is seen
Boolean ShouldSaveGhost(CGhost Ghost) {
    if (SeenGhosts.existskey(Ghost.Id)) return False; // we've seen this ghost
    SeenGhosts[Ghost.Id] = True; // this should act to help quickly filter this ghost out from consideration again
    if (Ghost.Nickname != LocalUser.Name) return False; // only save the local user's ghosts; and not 'Personal Best' (b/c they're already saved)
    if (!SeenTimes.existskey(Ghost.Result.Time)) return True; // we don't have this time
    declare Integer[] GhostCPs = ToScriptArray(Ghost.Result.Checkpoints);
    foreach (CpTimes in SeenTimes[Ghost.Result.Time]) { // inside the for loop we'll return if we find a reason to not save this ghost
        if (CpTimes.count != GhostCPs.count) continue; // CPs differ so can't be the same
        declare Boolean IsIdentical = True;
        for (i, 0, CpTimes.count - 1) {
            if (CpTimes[i] != GhostCPs[i]) { // if CP times differ, we'll always hit this
                IsIdentical = False; // so the ghosts differ
                break;
            }
        }
        if (IsIdentical) return False; // if we find a match, return
    }
    return True; // if we get here, we haven't seen this ghost before
}

Void RecordSeen(CGhost Ghost) {
    SeenGhosts[Ghost.Id] = True;
    if (!SeenTimes.existskey(Ghost.Result.Time)) {
        SeenTimes[Ghost.Result.Time] = [];
    }
    SeenTimes[Ghost.Result.Time].add(ToScriptArray(Ghost.Result.Checkpoints));
}

// when we first load the plugin, any existing ghosts are ignored
Void OnFirstLoad() {
    NbLastSeen = DataFileMgr.Ghosts.count;
    foreach (Ghost in DataFileMgr.Ghosts) {
        RecordSeen(Ghost);
        yield;
    }
}

Void CheckGhostsCPData() {
    // wait for current date and map name from AS before saving ghosts.
    if (!SetCurrentDateText || !SetMapNameSafe) return;

    // if (DataFileMgr == Null) return;
    // if (DataFileMgr.Ghosts == Null) return;
    declare Integer NbGhosts = DataFileMgr.Ghosts.count;
    if (NbGhosts == NbLastSeen) { return; }
    MLHookLog("DataFileMgr.Ghosts found " ^ (NbGhosts - NbLastSeen) ^ " new ghosts.");
    NbLastSeen = NbGhosts;
    declare CGhost[] GhostsToSave;
    foreach (Ghost in DataFileMgr.Ghosts) {
        if (ShouldSaveGhost(Ghost)) {
            RecordSeen(Ghost);
            GhostsToSave.add(Ghost);
        }
    }
    // don't save ghosts in the first 10s of loading a map -- just record that we've seen them.
    // they'll ~never be new ghosts.
    if (Now > OnlySaveAfter && AutosaveActive) {
        foreach (Ghost in GhostsToSave) {
            declare Text ReplayFileName = GetGhostFileName(Ghost);
            DataFileMgr.Replay_Save(ReplayFileName, Map, Ghost);
            SendCustomEvent("MLHook_Event_" ^ C_PageUID ^ "_SavedGhost", [ReplayFileName]);
            MLHookLog("Saved Ghost: " ^ ReplayFileName);
        }
    } else {
        MLHookLog("Skipping " ^ GhostsToSave.count ^ " ghosts due to OnlySaveAfter or AutosaveActive");
    }
}

Void ResetGhostsState() {
    NbLastSeen = 0;
    SeenGhosts.clear();
    SeenTimes.clear();
    SetMapNameSafe = False;
    SetCurrentDateText = False;
    OnlySaveAfter = Now + 10000;
    MLHookLog("Reset ghosts state.");
}

Void OnMapChange() {
    ResetGhostsState();
}


main() {
    declare Integer LoopCounter = 0;
    MLHookLog("Starting AutosaveGhosts Feed");
    yield;
    ResetGhostsState();
    // OnFirstLoad();
    while (True) {
        yield;
        LoopCounter += 1;
        CheckIncoming();

        // main logic
        CheckGhostsCPData();
        CheckMapChange();
        if (MapChanged) OnMapChange();
    }
}
""";