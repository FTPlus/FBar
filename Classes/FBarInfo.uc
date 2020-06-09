//==============================================================================
// FTPlus Bar Info
//
// Author: Ferry "FTPlus" Timmers
// Date: 24-5-2020 14:06
//
// Desc: Keeps track which pawn should have a bar.
//
//==============================================================================

class FBarInfo extends ReplicationInfo;

var int InitialHealth; // Health the target had before taking any damage
var bool bBoss;        // The target is marked as a boss

replication
{
	reliable if (bNetInitial && (Role == Role_Authority))
		InitialHealth, bBoss;
}

defaultproperties
{
	bAlwaysRelevant=True
	NetUpdateFrequency=2.000000
}
