const string VIEWPROFILEMENU_SCRIPT_TXT = """
<manialink name="Page_TestUILayers" version="3">
<script><!--

 #Const C_PageUID "ViewProfileMenu"
 #Include "Libs/Nadeo/MenuLibs/Common/Menu/Router_ML.Script.txt" as Router

 #Const C_Chris92_WSID "17868d60-b494-4b88-81df-f4ddfdae1cf1"

Void MLHookLog(Text msg) {
    SendCustomEvent("MLHook_LogMe_"^C_PageUID, [msg]);
}

Void CheckIncoming() {
    declare Text LibTMxSMRaceScoresTable_OpenProfileUserId for LocalUser;

    declare Text[][] MLHook_Inbound_ViewProfileMenu for LocalUser;

    foreach (Event in MLHook_Inbound_ViewProfileMenu) {
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
    }

    MLHook_Inbound_ViewProfileMenu = [];
}

Void OnFirstLoad() {
    declare Text LibTMxSMRaceScoresTable_OpenProfileUserId for LocalUser = "";
    MLHookLog("Nb UILayers: " ^ ParentApp.UILayers.count);
    // create layer for profile screen
    // declare profileLayer <=> ParentApp.UILayerCreate();
    // profileLayer.ManialinkPage = GetProfileML();
    // LibTMxSMRaceScoresTable_OpenProfileUserId = C_Chris92_WSID;
	// Router::CreateRoute();
	Router::Push(This, "/profile", ["AccountId" => C_Chris92_WSID]);
}

main() {
    declare Integer LoopCounter = 0;
    MLHookLog("Starting view profile ML helper");

    sleep(500);
    OnFirstLoad();
    yield;
    while (True) {
        yield;
        LoopCounter += 1;
        CheckIncoming();
    }
}

--></script>
</manialink>
""".Replace('_"_"_"_', '"""');