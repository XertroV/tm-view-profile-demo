# Autosave Ghosts

**This plugin requires _MLHook_ -- you must install that, too.**

This plugin will autosave a playable `.Replay.gbx` file for all ghosts that you generate, even in online servers.
This includes runs that are not PBs, but the run must be completed (it does not save partial runs).
To save partial runs (that aren't able to be played against), see [Autosave Replays for MediaTracker](https://openplanet.dev/plugin/autosavereplaysformt).

Works in:
* Ranked
* COTD Quali and KO
* Local campaign (*note:* was previously unreliable, please report any bugs; if you need an alternate solution, see [Replay Recorder](https://openplanet.dev/plugin/replayrecorder))

Does not work in:
* Royal

How it works:
When you complete a run, even in online servers, a ghost is generated.
AFAIK, you can't save these ghosts using `DataFileMgr.Save_Replay` _from Angelscript_.
However, if you call `DataFileMgr.Save_Replay` from ManiaLink, then it does generate a playable replay.
This plugin automatically detects new ghosts, filters out duplicates (like your PB ghost) and external ghosts (e.g., the WR ghost), and saves the remaining ghosts.

Save path: `Trackmania\Replays\AutosavedGhosts\<MapName>\<Date>-<MapName>-<Nickname>-<RaceTime>.Replay.gbx`

License: Public Domain

Authors: XertroV

Suggestions/feedback: @XertroV on Openplanet discord

Code/issues: [https://github.com/XertroV/tm-autosave-ghosts](https://github.com/XertroV/tm-autosave-ghosts)

GL HF
