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

class FBar extends Mutator config(user);

var PlayerPawn MyPlayer;
var HUD MyHUD;

var color BlackColor, GreyColor, WhiteColor, RedColor, GreenColor, BlueColor,
	YellowColor;
var config int BarWidth;
var config int BarHeight;
var config int FontSize;

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
	local float ActualWidth;
	local float TW, TH;
	local float DefaultHealth;
	
	// Get pawn on-screen position
	if (!MapToHUD(C, MyPlayer, P, Vect(0,0,2) * MyPlayer.EyeHeight, X, Y))
		return;
	
	Y -= BarHeight * 2;

	// Set up font
	if (FontSize == 1)
		C.Font = C.MedFont;
	else if (FontSize == 2)
		C.Font = C.BigFont;
	else if (FontSize == 3)
		C.Font = C.LargeFont;
	else
		C.Font = C.SmallFont;
	C.TextSize("TEST", TW, TH);

	// Draw bar body
	C.SetPos(X, Y);
	C.DrawColor = GreyColor;
	C.Style = ERenderStyle.STY_Translucent;
	if (P.bIsPlayer)
		C.DrawRect(texture'UTMenu.VScreenStatic', BarWidth, BarHeight * 2 - 2);
	else
		C.DrawRect(texture'UTMenu.VScreenStatic', BarWidth, BarHeight);

	// Draw Pawn Name
	C.SetPos(X,Y - TH - 1);
	C.DrawColor = WhiteColor;
	C.Style = ERenderStyle.STY_Normal;
	if (P.bIsPlayer)
		C.DrawText(P.PlayerReplicationInfo.PlayerName);
	else
		C.DrawText(P.Name);
	
	// Draw health bar
	DefaultHealth = P.default.Health;
	if (Info != None)
		DefaultHealth = Info.InitialHealth;

	DrawHealthBar(C, X, Y, 1, float(P.health) / DefaultHealth);
	// if P is a player (or bot) draw a double bar: health and armor
	if (P.bIsPlayer)
		DrawArmorBar(C, X, Y + BarHeight - 2, 1, float(FetchArmorAmount(P)) / 150.0);
}

function DrawHealthBar(Canvas C, float X, float Y, float Size, float Value)
{
	local float W;
	local float H;

	H = float(BarHeight - 4);
	W = float(BarWidth - 8);

	// Draw Health bar base
	if (Value > 1.0)
		C.DrawColor = GreenColor;
	else
		C.DrawColor = RedColor;
	C.SetPos(X + 4, Y + 2);
	C.DrawRect(texture'Botpack.Static1', W, BarHeight - 4);

	// Draw health bar value
	C.SetPos(X + 4, Y + 2);
	if (Value > 1.0)
	{
		Value -= 1.0;
		if (Value > 1.0)
			Value = 1.0;
		C.DrawColor = BlueColor;
		C.DrawRect(texture'Botpack.Static1', W * Value, BarHeight - 4);
	}
	else
	{
		C.DrawColor = GreenColor;
		C.DrawRect(texture'Botpack.Static1', W * Value, BarHeight - 4);
	}
}

function DrawArmorBar(Canvas C, float X, float Y, float Size, float Value)
{
	local float W;
	local float H;

	H = float(BarHeight - 4);
	W = float(BarWidth - 8);

	C.SetPos(X + 4, Y + 2);
	if (Value > 1.0)
		Value = 1.0;
	C.DrawColor = YellowColor;
	C.DrawRect(texture'Botpack.Static1', W * Value, BarHeight - 4);
}

//------------------------------------------------------------------------------

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
	bNetTemporary=True
	BlackColor=()
	GreyColor=(R=127,G=127,B=127)
	WhiteColor=(R=255,G=255,B=255)
	RedColor=(R=255)
	GreenColor=(G=255)
	BlueColor=(B=255)
	YellowColor=(R=255,G=255)
	BarWidth=64
	BarHeight=8
	FontSize=0
}