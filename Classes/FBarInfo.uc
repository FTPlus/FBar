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
var bool bIsBoss;      // The target is marked as a boss
var int ArmorAmount;   // Amount of armor a player (or bot) has

replication
{
	reliable if (bNetInitial && (Role == Role_Authority))
		InitialHealth, bIsBoss;
	// Only propagate armor info for players (other than current player)
	reliable if (Pawn(Owner) != None && Pawn(Owner).bIsPlayer && !bNetOwner
			&& (Role == Role_Authority))
		ArmorAmount;
}

defaultproperties
{
	bAlwaysRelevant=True
	NetUpdateFrequency=2.000000
}
