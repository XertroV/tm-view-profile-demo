const string VIEWPROFILE_SCRIPT_TXT = """
// one space indent otherwise they're treated as compiler preprocessor statements by openplanet
// note: now done in pre-proc-scripts.py
 #Const C_PageUID "ViewProfile"
 #Include "TextLib" as TL


// logging function, should be "MLHook_LogMe_" + PageUID
Void MLHookLog(Text msg) {
    SendCustomEvent("MLHook_LogMe_"^C_PageUID, [msg]);
}

// state

// from angelscript

Void CheckIncoming() {
    declare Text LibTMxSMRaceScoresTable_OpenProfileUserId for ClientUI;
    declare Text[][] MLHook_Inbound_ViewProfile for ClientUI;
    foreach (Event in MLHook_Inbound_ViewProfile) {
        if (Event.count < 2) {
            MLHookLog("Skipping msg with only 1 element: " ^ Event);
        } else if (Event.count < 3) {
            if (Event[0] == "OpenProfile") {
                LibTMxSMRaceScoresTable_OpenProfileUserId = Event[1];
            } else {
                MLHookLog("Skipped unknown incoming event: " ^ Event);
                continue;
            }
        } else {
            MLHookLog("Skipped unknown incoming event: " ^ Event);
            continue;
        }
        // MLHookLog("Processed Incoming Event: "^Event[0]);
    }
    MLHook_Inbound_ViewProfile = [];
}

Void OnFirstLoad() {
}

main() {
    declare Integer LoopCounter = 0;
    MLHookLog("Starting view profile ML helper");
    yield;
    OnFirstLoad();
    while (True) {
        yield;
        LoopCounter += 1;
        CheckIncoming();
    }
}
""";