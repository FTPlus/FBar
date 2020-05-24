//==============================================================================
// FTPlus Bar Info
//
// Author: Ferry "FTPlus" Timmers
// Date: 24-5-2020 14:06
//
// Desc: Keeps track which pawn should have a bar.
//
//==============================================================================

class FBarInfo extends Info;

var Pawn Target;       // The pawn this info object belongs to
var int InitialHealth; // Health the target had before taking any damage
