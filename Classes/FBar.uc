//==============================================================================
// FTPlus Bar Mutator
//
// Author: Ferry "FTPlus" Timmers
// Date: 13-10-2007 22:11
//
// Desc: This Mutator draws status bars above players citing their name,
//       and their current health and armor status. This Mutator also works
//       for Monsters with, for instance, MonsterHunt.
//
//==============================================================================

class FBar extends Mutator;

var PlayerPawn MyPlayer;
var HUD MyHUD;

//------------------------------------------------------------------------------

function PostBeginPlay()
{
	Level.Game.RegisterDamageMutator(Self);
}

//------------------------------------------------------------------------------

function MutatorTakeDamage(out int ActualDamage, Pawn Victim, Pawn InstigatedBy,
	out Vector HitLocation, out Vector Momentum, name DamageType)
{
	local FBarInfo Info;

	if (ScriptedPawn(Victim) != None && PlayerPawn(InstigatedBy) != None)
	{
		// A player hits a monster
		foreach Victim.ChildActors(class'FBarInfo', Info)
			break;
		// If Victim has not yet a FBar instance, spawn one
		if (Info == None)
			Info = Spawn(class'FBarInfo', Victim);
		if (Info != None)
		{
			Info.Target = Victim;
			Info.InitialHealth = Victim.Health + ActualDamage;
		}
	}
	if (NextDamageMutator != None)
		NextDamageMutator.MutatorTakeDamage(ActualDamage, Victim, InstigatedBy,
			HitLocation, Momentum, DamageType);
}

//------------------------------------------------------------------------------

function ScoreKill(Pawn Killer, Pawn Other)
{
	local FBarInfo Info;

	// Destroy FBarInfo if the killed pawn had one
	if (Other != None)
	{
		foreach Other.ChildActors(class'FBarInfo', Info)
			break;
		if (Info != None)
			Info.Destroy();
	}
	if (NextMutator != None)
		NextMutator.ScoreKill(Killer, Other);
}

//------------------------------------------------------------------------------

simulated function Tick(float DeltaTime)
{
	if (!bHUDMutator && Level.NetMode != NM_DedicatedServer)
		RegisterHUDMutator();
}

//------------------------------------------------------------------------------

simulated function PostRender(Canvas C)
{
	local Pawn P;
	local FBarInfo Info;
	local Vector Eyes;
	
	MyPlayer = C.Viewport.Actor;
	if ( MyPlayer != None )
		MyHUD = MyPlayer.myHUD;
	
	if ( NextHUDMutator != None )
		NextHUDMutator.PostRender(C);
	
	Eyes = MyPlayer.Location + Vect(0,0,1) * MyPlayer.EyeHeight;
	
	// Find Pawns and draw bars
	//for (P = Level.PawnList; P != None; P = P.NextPawn)
	foreach AllActors(class'Pawn', P)
	{
		// Ignore invisible Pawns
		if (P == MyPlayer || P.health < 1 || P.bHidden)
			continue;
		
		// Ignore flocked Pawns (looks kinda silly :D)
		if (FlockPawn(P) != None)
			continue;

		// Ignore monsters, they are treated separately
		if (ScriptedPawn(P) != None)
			continue;
		
		// Ignore non-visible Pawns
		if (!FastTrace(Eyes, P.Location))
			continue;
		
		// Draw bar
		DrawBar(C, P, None);
	}

	// Find monsters that have been damaged before and draw bars
	foreach AllActors(class'FBarInfo', Info)
	{
		P = Info.Target;
		if (P == None)
			continue;

		// Ignore non-visible Pawns
		if (!FastTrace(Eyes, P.Location))
			continue;

		// Draw bar
		DrawBar(C, P, Info);
	}

}

//------------------------------------------------------------------------------
// Map to HUD was Created by Wormbo
//------------------------------------------------------------------------------
simulated function bool MapToHUD(Canvas C, PlayerPawn Owner, Actor Target,
                                 vector Offset, out float XX, out float YY)
{
	local float TanFOVx, TanFOVy;
	local float TanX, TanY;
	local float dx, dy;
	local vector X, Y, TargetDir, Dir, XY;
	
	if (Owner == None || Target == None)
		return (false);
	
	// Direction to target
	TargetDir = Target.Location - (Owner.Location + Vect(0,0,1) * Owner.EyeHeight);
	TargetDir += Offset;
	
	TanFOVx = Tan(Owner.FOVAngle * Pi / 360);
	TanFOVy = (C.ClipY / C.ClipX) * TanFOVx;
	GetAxes(Owner.ViewRotation, Dir, X, Y);
	
	Dir *= TargetDir dot Dir;
	XY = TargetDir - Dir;
	dx = XY dot X;
	dy = XY dot Y;
	
	TanX = dx / VSize(dir);
	TanY = dy / VSize(dir);
	
	XX = C.ClipX * 0.5 * (1 + TanX / TanFOVx);
	YY = C.ClipY * 0.5 * (1 - TanY / TanFOVy);
	
	return (Dir dot vector(Owner.ViewRotation) > 0
	        && XX == FClamp(XX, C.OrgX, C.ClipX)
	        && YY == FClamp(YY, C.OrgY, C.ClipY));
}

//------------------------------------------------------------------------------
// Gets current Armor level
//------------------------------------------------------------------------------

function int FetchArmorAmount(Pawn P)
{
	local int Amount;
	local Inventory Inv;
	
	Amount = 0;
	
	for (Inv = P.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if (Inv.bIsAnArmor)
			Amount += Inv.Charge;
	}
	
	return (Min(Amount, 150));
}

//------------------------------------------------------------------------------
// Draw the status bar
//------------------------------------------------------------------------------

simulated function DrawBar(Canvas C, Pawn P, FBarInfo Info)
{
	local float X, Y;
	local float factor;
	
	// Get pawn on-screen position
	if (!MapToHUD(C, MyPlayer, P, Vect(0,0,2) * MyPlayer.EyeHeight, X, Y))
		return;
	
	Y -= 32;
	
	// Draw bar body
	C.SetPos(X, Y);
	C.DrawColor.R = 127;
	C.DrawColor.G = 127;
	C.DrawColor.B = 127;
	C.Style = ERenderStyle.STY_Translucent;
	C.DrawRect(texture'UTMenu.VScreenStatic', 64, 16);
	
	// Draw Pawn Name
	C.SetPos(X,Y-9);
	C.DrawColor.R = 255;
	C.DrawColor.G = 255;
	C.DrawColor.B = 255;
	C.Style = ERenderStyle.STY_Normal;
	C.Font = C.SmallFont;
	if (P.bIsPlayer)
		C.DrawText(P.PlayerReplicationInfo.PlayerName);
	else
		C.DrawText(P.Name);
	
	// Health calculation
	factor = float(P.health) / P.default.health;
	
	// Draw Health bar
	C.DrawColor.B = 0;
	if (P.health > P.default.health)
	{
		C.DrawColor.R = 0;
		C.DrawColor.G = 255;
	}
	else
	{
		C.DrawColor.R = 255;
		C.DrawColor.G = 0;
	}
	C.SetPos(X + 4, Y + 2);
	C.DrawRect(texture'Botpack.Static1', 56, 4);

	C.SetPos(X + 4, Y + 2);
	C.DrawColor.R = 0;
	if (P.health > P.default.health)
	{
		C.DrawColor.G = 0;
		C.DrawColor.B = 255;
		C.DrawRect(texture'Botpack.Static1', 56.0 * ((float(P.health)%P.default.health)/P.default.health), 4);
	}
	else
	{
		C.DrawColor.G = 255;
		C.DrawColor.B = 0;
		C.DrawRect(texture'Botpack.Static1', 56.0 * factor, 4);
	}
	
	// Draw Armor bar, or logaritmic healthbar
	if (P.bIsPlayer)
	{
		C.DrawColor.R = 255;
		C.DrawColor.G = 255;
		C.DrawColor.B = 0;
		C.SetPos(X + 4, Y + 10);
		C.DrawRect(texture'Botpack.Static1', 56.0 * (FetchArmorAmount(P)/150.0), 4);
	}
	else
	{
		if (factor < 11)
		{
			C.DrawColor.R = 255;
			C.DrawColor.G = 255;
			C.DrawColor.B = 0;
			C.SetPos(X + 4, Y + 10);
			C.DrawRect(texture'Botpack.Static1', 5.6 * (int(factor) - 1), 4);
		}
		else
		{
			C.DrawColor = C.DrawColor * 0;
			C.SetPos(X + 4, Y + 7);
			C.DrawText(int(factor));
		}
	}
}

//------------------------------------------------------------------------------

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
	bNetTemporary=True
}