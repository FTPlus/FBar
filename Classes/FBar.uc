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
var config int BossHealth; // Initial health a scripted pawn should have to be
// considered a boss.

//------------------------------------------------------------------------------

function PostBeginPlay()
{
	Level.Game.RegisterDamageMutator(Self);
	Super.PostBeginPlay();
}

//------------------------------------------------------------------------------

function MutatorTakeDamage(out int ActualDamage, Pawn Victim, Pawn InstigatedBy,
	out Vector HitLocation, out Vector Momentum, name DamageType)
{
	local FBarInfo Info;

	if (ScriptedPawn(Victim) != None)
	{
		// A monster was hit
		foreach Victim.ChildActors(class'FBarInfo', Info)
			break;
		// If Victim does not yet have a FBar instance, spawn one
		if (Info == None)
		{
			Info = Spawn(class'FBarInfo', Victim);
			if (Info != None)
			{
				Info.InitialHealth = Victim.Health + ActualDamage;
				Info.bIsBoss = Info.InitialHealth > BossHealth;
					/*|| ScriptedPawn(Victim).bIsBoss;*/
			}
		}
	}
	else if (Victim.bIsPlayer)
	{
		// A player (or bot) was hit
		foreach Victim.ChildActors(class'FBarInfo', Info)
			break;

		if (Info != None)
			UpdateArmorAmount(Victim, Info, 0);
	}
	if (NextDamageMutator != None)
		NextDamageMutator.MutatorTakeDamage(ActualDamage, Victim, InstigatedBy,
			HitLocation, Momentum, DamageType);
}

//------------------------------------------------------------------------------

function bool HandlePickupQuery(Pawn Other, Inventory Item, out byte bAllowPickup)
{
	local FBarInfo Info;

	if (Other.bIsPlayer && Item.bIsAnArmor)
	{
		// A player (or bot) picked up Armor
		foreach Other.ChildActors(class'FBarInfo', Info)
			break;

		if (Info != None)
			UpdateArmorAmount(Other, Info, Item.Charge);
	}
	return Super.HandlePickupQuery(Other, Item, bAllowPickup);
}

//------------------------------------------------------------------------------

function ModifyPlayer(Pawn Other)
{
	local FBarInfo Info;

	Super.ModifyPlayer(Other);

	// A player (or bot) spawned
	foreach Other.ChildActors(class'FBarInfo', Info)
		break;

	// If the player does not yet have a FBar instance, spawn one
	if (Info == None)
	{
		Info = Spawn(class'FBarInfo', Other);
		if (Info != None)
		{
			Info.InitialHealth = Other.Health;
			Info.bIsBoss = false;
		}
	}
}

//------------------------------------------------------------------------------
// Updated the current Armor level of a Pawn in the associated FBarInfo
//------------------------------------------------------------------------------

function UpdateArmorAmount(Pawn Target, FBarInfo Info, int Amount)
{
	local Inventory Inv;

	if (Info == None)
		return;

	for (Inv = Target.Inventory; Inv != None; Inv = Inv.Inventory)
		if (Inv.bIsAnArmor)
			Amount += Inv.Charge;

	Info.ArmorAmount = Min(Amount, 150);
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
	foreach AllActors(class'FBarInfo', Info)
	{
		P = Pawn(Info.Owner);
		if (P == None)
			continue;

		// Ignore invisible or already death Pawns
		if (P == MyPlayer || P.health < 1 || P.bHidden)
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
// Draw the status bar
//------------------------------------------------------------------------------

simulated function DrawBar(Canvas C, Pawn P, FBarInfo Info)
{
	local float X, Y, W, H, Size;
	local float TW, TH;
	local float Value;
	local string Text;

	// Get pawn on-screen position
	if (!MapToHUD(C, MyPlayer, P, Vect(0,0,1) * P.CollisionHeight, X, Y))
		return;

	// set up information
	if (P.bIsPlayer)
		Text = P.PlayerReplicationInfo.PlayerName;
	else
		Text = String(P.Name);

	if (Info.bIsBoss)
	{
		// Draw large bar
		W = BarWidth * 4;
		H = BarHeight * 2;
		C.Font = C.LargeFont;
		Text = Caps(Text);
	}
	else
	{
		// Draw small bar
		W = BarWidth;
		H = BarHeight;
		C.Font = C.SmallFont;
	}
	Y -= 32;
	C.TextSize(Text, TW, TH);

	// Draw bar body
	C.SetPos(X, Y);
	C.DrawColor = GreyColor;
	C.Style = ERenderStyle.STY_Translucent;
	if (P.bIsPlayer)
		C.DrawRect(texture'UTMenu.VScreenStatic', W, H * 2 - 2);
	else
		C.DrawRect(texture'UTMenu.VScreenStatic', W, H);

	// Draw Pawn Name
	C.SetPos(X, Y - TH - 1);
	C.DrawColor = WhiteColor;
	C.Style = ERenderStyle.STY_Normal;
	C.DrawText(Text);

	X += 4;
	Y += 2;

	// Draw Health bar base
	Value = float(P.health) / Info.InitialHealth;
	if (Value > 1.0)
		C.DrawColor = GreenColor;
	else
		C.DrawColor = RedColor;
	C.SetPos(X, Y);
	C.DrawRect(texture'Botpack.Static1', W - 8, H - 4);

	// Draw health bar value
	C.SetPos(X, Y);
	if (Value > 1.0)
	{
		Value -= 1.0;
		if (Value > 1.0)
			Value = 1.0;
		C.DrawColor = BlueColor;
		C.DrawRect(texture'Botpack.Static1', (W - 8) * Value, H - 4);
	}
	else
	{
		C.DrawColor = GreenColor;
		C.DrawRect(texture'Botpack.Static1', (W - 8) * Value, H - 4);
	}

	Y += H - 2;

	// if P is a player (or bot) draw a double bar: health and armor
	if (P.bIsPlayer)
	{
		Value = float(Info.ArmorAmount) / 150.0;
		C.SetPos(X, Y);
		if (Value > 1.0)
			Value = 1.0;
		C.DrawColor = YellowColor;
		C.DrawRect(texture'Botpack.Static1', (W - 8) * Value, H - 4);
	}
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
	YellowColor=(R=219,G=146)
	BarWidth=64
	BarHeight=8
	BossHealth=1000
}
