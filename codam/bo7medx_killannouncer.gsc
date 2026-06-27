///////////////////////////////////////////////////////////////////////////////
// PROJECT : BO7MEDX Kill Announcer v3.6
// AUTHOR  : BO7MEDX
// ENGINE  : CoD1 (CoDExtended)
//
// NOTE: this is not a pure "killstreak" script. It's a kill ANNOUNCER that
// decides, for every kill, which single announcement is the most relevant
// one to show (first blood > headshot > streak > multi-kill > nice shot).
// That's why it's named "Kill Announcer" and not "Kill Streak".
//
// LICENSE: free to modify/redistribute, but credit to BO7MEDX must stay
// in this file. Do not remove authorship credit.
///////////////////////////////////////////////////////////////////////////////

main( phase, register )
{
    if ( phase == "init" )
    {
        [[ register ]]( "PlayerKilled",  ::_onKill,  "thread" );
        [[ register ]]( "PlayerSpawned", ::_onSpawn, "thread" );
    }
    else if ( phase == "load" )
    {
        level.bka_firstblood = false;
    }
    else if ( phase == "start" )
    {
        level.bka_firstblood = false;
    }
    return;
}

// =============================================================================
// SPAWN
// Reset every per-life stat so a fresh life always starts from zero.
// =============================================================================

_onSpawn()
{
    self.bka_streak   = 0;
    self.bka_mk_count = 0;
    self.bka_mk_ticks = 0;
    self.bka_ann_5    = false;
    self.bka_ann_7    = false;
    self.bka_ann_10   = false;
    self.bka_ann_15   = false;
    self.bka_ann_20   = false;
    self.bka_team     = self.sessionteam;
    return;
}

// =============================================================================
// KILL HANDLER
//
// PRIORITY (only ONE announcement fires per kill):
//   1. First Blood    - first kill of the map, server-wide, only once
//   2. Headshot        - always wins visually, but streak/multi-kill counters
//                         still advance silently underneath it
//   3. Killstreak       - 5 / 7 / 10 / 15 / 20 kills without dying
//   4. Multi-Kill       - 2+ kills within a 4 second window
//   5. Nice Shot        - fallback when nothing else qualifies
// =============================================================================

_onKill( eInflictor, eAttacker, iDamage, sMeansOfDeath,
         sWeapon, vDir, sHitLoc,
         a7, a8, a9, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9 )
{
    self endon( "disconnect" );

    if ( self.sessionteam == "spectator" ) return;

    victim = self;

    victim thread _playDeathSound();

    // victim's life is over, wipe their per-life stats
    victim.bka_streak   = 0;
    victim.bka_mk_count = 0;
    victim.bka_mk_ticks = 0;
    victim.bka_ann_5    = false;
    victim.bka_ann_7    = false;
    victim.bka_ann_10   = false;
    victim.bka_ann_15   = false;
    victim.bka_ann_20   = false;

    if ( !isDefined( eAttacker ) ) return;   // world/fall damage etc.
    if ( !isPlayer( eAttacker ) )  return;   // killed by a non-player entity
    if ( eAttacker == victim )     return;   // suicide, no announcement

    _initAtk( eAttacker );

    // ── PRIORITY 1: FIRST BLOOD ──────────────────────────────────────────────
    if ( !level.bka_firstblood )
    {
        level.bka_firstblood   = true;
        eAttacker.bka_streak++;
        eAttacker.bka_mk_count = 1;
        eAttacker.bka_mk_ticks = level.time;

        _playAll( "bo7medx_firstblood" );
        iprintlnbold( "^1[FIRST BLOOD] ^7" + eAttacker.name + " ^7got the first kill!" );
        return;
    }

    // ── PRIORITY 2: HEADSHOT ─────────────────────────────────────────────────
    isHeadshot = false;
    if ( isDefined( sHitLoc ) )
    {
        if ( sHitLoc == "head" )
            isHeadshot = true;
    }

    if ( isHeadshot )
    {
        // headshot always wins the announcement, but we still advance the
        // streak/multi-kill counters in the background so the next kill
        // (if not a headshot) lines up with the correct milestone.
        _countStreak( eAttacker );
        _countMK( eAttacker );

        _playAll( "bo7medx_headshot" );
        iprintln( "^3[HEADSHOT] ^7" + eAttacker.name + " ^7-> Nice Shot!" );
        return;
    }

    // ── PRIORITY 3: KILLSTREAK ───────────────────────────────────────────────
    announced = _tickStreak( eAttacker );

    // ── PRIORITY 4: MULTI-KILL ───────────────────────────────────────────────
    if ( !announced )
        announced = _tickMK( eAttacker );

    // ── PRIORITY 5: NICE SHOT (fallback) ─────────────────────────────────────
    if ( !announced )
    {
        _playAll( "bo7medx_niceshot" );
        iprintln( "^2[NICE SHOT] ^7" + eAttacker.name + " ^7-> Keep it up!" );
    }

    return;
}

// =============================================================================
// DEATH SOUND
// Small delay so it doesn't overlap the kill-cam / death animation sound.
// =============================================================================

_playDeathSound()
{
    self endon( "disconnect" );
    wait 0.1;
    self playsound( "bo7medx_death" );
    return;
}

// =============================================================================
// INIT ATTACKER
// Lazily creates the stat fields the first time we see this attacker, so we
// never touch an undefined variable later in the kill handler.
// =============================================================================

_initAtk( atk )
{
    if ( !isDefined( atk.bka_streak ) )   atk.bka_streak   = 0;
    if ( !isDefined( atk.bka_mk_count ) ) atk.bka_mk_count = 0;
    if ( !isDefined( atk.bka_mk_ticks ) ) atk.bka_mk_ticks = 0;
    if ( !isDefined( atk.bka_ann_5 ) )    atk.bka_ann_5    = false;
    if ( !isDefined( atk.bka_ann_7 ) )    atk.bka_ann_7    = false;
    if ( !isDefined( atk.bka_ann_10 ) )   atk.bka_ann_10   = false;
    if ( !isDefined( atk.bka_ann_15 ) )   atk.bka_ann_15   = false;
    if ( !isDefined( atk.bka_ann_20 ) )   atk.bka_ann_20   = false;
    if ( !isDefined( atk.bka_team ) )     atk.bka_team     = atk.sessionteam;
    return;
}

// =============================================================================
// COUNT STREAK (silent)
// Same milestone logic as _tickStreak(), but never plays a sound or prints
// anything. Used when a headshot already "used up" the announcement slot
// for this kill, so the streak still needs to advance without double-firing.
// =============================================================================

_countStreak( atk )
{
    atk.bka_streak++;
    s = atk.bka_streak;

    // mark the milestone as already-announced so it doesn't fire again
    // on a later, non-headshot kill that lands on the same number
    if ( s == 5 )       atk.bka_ann_5  = true;
    else if ( s == 7 )  atk.bka_ann_7  = true;
    else if ( s == 10 ) atk.bka_ann_10 = true;
    else if ( s == 15 ) atk.bka_ann_15 = true;
    else if ( s == 20 ) atk.bka_ann_20 = true;
    return;
}

// =============================================================================
// COUNT MULTI-KILL (silent)
// Same window logic as _tickMK(), but never announces. Used under a headshot.
// =============================================================================

_countMK( atk )
{
    now     = level.time;
    elapsed = now - atk.bka_mk_ticks;

    if ( elapsed <= 4000 )
        atk.bka_mk_count++;
    else
        atk.bka_mk_count = 1;

    atk.bka_mk_ticks = now;
    return;
}

// =============================================================================
// KILLSTREAK (counts + announces)
// =============================================================================

_tickStreak( atk )
{
    atk.bka_streak++;
    s = atk.bka_streak;
    announced = false;

    if ( s == 5 )
    {
        if ( !atk.bka_ann_5 )
        {
            atk.bka_ann_5 = true;
            _playAll( "bo7medx_spree" );
            iprintlnbold( "^7" + atk.name + " ^7is on a ^1KILLING SPREE^7!" );
            announced = true;
        }
    }
    else if ( s == 7 )
    {
        if ( !atk.bka_ann_7 )
        {
            atk.bka_ann_7 = true;
            _playAll( "bo7medx_rampage" );
            iprintlnbold( "^7" + atk.name + " ^7is on a ^1RAMPAGE^7!" );
            announced = true;
        }
    }
    else if ( s == 10 )
    {
        if ( !atk.bka_ann_10 )
        {
            atk.bka_ann_10 = true;
            _playAll( "bo7medx_dominating" );
            iprintlnbold( "^7" + atk.name + " ^7is ^1DOMINATING^7!" );
            announced = true;
        }
    }
    else if ( s == 15 )
    {
        if ( !atk.bka_ann_15 )
        {
            atk.bka_ann_15 = true;
            _playAll( "bo7medx_unstoppable" );
            iprintlnbold( "^7" + atk.name + " ^7is ^1UNSTOPPABLE^7!" );
            announced = true;
        }
    }
    else if ( s == 20 )
    {
        if ( !atk.bka_ann_20 )
        {
            atk.bka_ann_20 = true;
            _playAll( "bo7medx_monster" );
            iprintlnbold( "^7" + atk.name + " ^7is a ^1MONSTER^7!!" );
            announced = true;
        }
    }

    return announced;
}

// =============================================================================
// MULTI-KILL (counts + announces)
// Window-based: kills inside a rolling 4 second window stack up the counter,
// any gap longer than that resets it back to 1.
// =============================================================================

_tickMK( atk )
{
    now     = level.time;
    elapsed = now - atk.bka_mk_ticks;

    if ( elapsed <= 4000 )
        atk.bka_mk_count++;
    else
        atk.bka_mk_count = 1;

    atk.bka_mk_ticks = now;

    c = atk.bka_mk_count;
    announced = false;

    if ( c == 2 )
    {
        _playAll( "bo7medx_double" );
        iprintlnbold( "^2" + atk.name + " ^7-> ^2DOUBLE KILL!" );
        announced = true;
    }
    else if ( c == 3 )
    {
        _playAll( "bo7medx_triple" );
        iprintlnbold( "^5" + atk.name + " ^7-> ^5TRIPLE KILL!" );
        announced = true;
    }
    else if ( c == 4 )
    {
        _playAll( "bo7medx_niceshot" );
        iprintlnbold( "^3" + atk.name + " ^7-> ^3MULTI KILL!" );
        announced = true;
    }
    else if ( c >= 5 )
    {
        _playAll( "bo7medx_monster" );
        iprintlnbold( "^1" + atk.name + " ^7-> ^1ULTRA KILL!" );
        announced = true;
    }

    return announced;
}

// =============================================================================
// PLAY ALL
// Broadcasts a sound alias to every connected player (server-wide announcement).
// =============================================================================

_playAll( alias )
{
    players = getentarray( "player", "classname" );
    i = 0;
    while ( i < players.size )
    {
        if ( isPlayer( players[ i ] ) )
            players[ i ] playsound( alias );
        i++;
    }
    return;
}
