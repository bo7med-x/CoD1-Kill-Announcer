# BO7MEDX Kill Announcer

A server-side kill announcer for **Call of Duty 1**, built for **CoDExtended (CEX)** - tested and working on the latest CEX release.

On every kill it picks **one** announcement to show - First Blood, Headshot, Killstreak, Multi-Kill, or a generic Nice Shot - plus a death sound for the victim.

It's called "Kill Announcer" and not "Kill Streak" because killstreaks are only one of the things it can announce.

## Download

**[Click here to download](https://github.com/bo7med-x/CoD1-Kill-Announcer/releases/download/v3.6/bmx_killannouncer.zip)**

The zip contains both pk3 files:
- `_srv_bo7medx_killannouncer_script.pk3`
- `zzz_bo7medx_killannouncer_sounds.pk3`

## Announcement priority

Only one announcement fires per kill, in this order:

1. **First Blood** - first kill of the map, once per map
2. **Headshot** - always wins the announcement on a headshot kill
3. **Killstreak** - 5 / 7 / 10 / 15 / 20 kills without dying
4. **Multi-Kill** - 2+ kills inside a 4 second window
5. **Nice Shot** - fallback when nothing above qualifies
6. **Death Sound** - always plays for the victim, on every death

## Requirements

- CoD1 server running **CoDExtended (CEX)**, latest release

## Installation

1. [Download the zip](https://github.com/bo7med-x/CoD1-Kill-Announcer/releases/download/v3.6/bmx_killannouncer.zip) and extract it - it contains both pk3 files:
   - `_srv_bo7medx_killannouncer_script.pk3`
   - `zzz_bo7medx_killannouncer_sounds.pk3`
2. Put both pk3 files in your server's **`main`** folder.
3. Open your server's **`modlist.gsc`** and add this line inside it:

   ```
   [[ register ]]( "BO7MEDX Kill Announcer", codam\bo7medx_killannouncer::main );
   ```

4. Restart the server (or `map_restart`) so the modlist picks it up.

**Important:** keep the `_srv_` prefix on `_srv_bo7medx_killannouncer_script.pk3` exactly as it is - don't rename or remove it. That prefix is what keeps this pk3 server-side only, so it does **not** get downloaded by connecting clients (it doesn't need to be on their machine at all). The `zzz_bo7medx_killannouncer_sounds.pk3` is the only one that gets downloaded to clients, since they need the actual sound files to hear the announcements.

## License / Credit

You're free to modify this script however you want. The only requirement is that credit to **BO7MEDX** stays in the file - don't remove the authorship credit.

## Contact

- Discord: **@bo7medx** / **@bo7med_x**
