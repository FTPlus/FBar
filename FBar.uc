//==============================================================================
// FTPlus Bar Mutator
//
//==============================================================================

class FBarMutator extends Mutator;

var        bool       bInitialized;
var        FBar  Bars[10];

var        PlayerPawn MyPlayer;
var        HUD        MyHUD;

simulated function Tick(float DeltaTime)
{

	if(bInitialized || Level.NetMode == NM_DedicatedServer) return;
	
    if ( !bHUDMutator && Level.NetMode != NM_DedicatedServer )
        RegisterHUDMutator();
		
	bInitialized = bHUDMutator;
}

//------------------------------------------------------------------------------
// Map to HUD was Created by Wormbo
//------------------------------------------------------------------------------
simulated function bool MapToHUD(Canvas C, PlayerPawn Owner, Actor Target, vector Offset, out float XX, out float YY)
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

function int FetchArmorAmount(pawn P)
{
	local int Amount;
	local Inventory Inv;
	
	Amount = 0;
	
	for( Inv=P.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		if (Inv.bIsAnArmor)
			Amount += Inv.Charge;
	}
	
	return (Min(Amount, 150));
}

simulated function DrawBar(Canvas C, Pawn P)
{
	local float X, Y;
	
	if (!MapToHUD(C, MyPlayer, P, Vect(0,0,2) * MyPlayer.EyeHeight, X, Y)
	 || !FastTrace(P.Location, MyPlayer.Location + Vect(0,0,1) * MyPlayer.EyeHeight))
		return;
	
	Y -= 32;
	
	C.SetPos(X, Y);
	C.DrawColor.R = 127;
	C.DrawColor.G = 127;
	C.DrawColor.B = 127;
	C.Style = ERenderStyle.STY_Translucent;
	C.DrawRect(texture'UTMenu.VScreenStatic', 64, 16);
	
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
	if(P.health > P.default.health)
	{
		C.DrawColor.G = 0;
		C.DrawColor.B = 255;
		C.DrawRect(texture'Botpack.Static1', 56.0 * (float(P.health-P.default.health)/P.default.health), 4);
	}
	else
	{
		C.DrawColor.G = 255;
		C.DrawColor.B = 0;
		C.DrawRect(texture'Botpack.Static1', 56.0 * (float(P.health)/P.default.health), 4);
	}
	
	C.DrawColor.R = 255;
	C.DrawColor.G = 255;
	C.DrawColor.B = 0;
	C.SetPos(X + 4, Y + 10);
	C.DrawRect(texture'Botpack.Static1', 56.0 * (FetchArmorAmount(P)/150.0), 4);
}

simulated function DrawTwoColorID(canvas Canvas, string TitleString, string ValueString, int YStart )
{
	local float XL, YL, XOffset, X1;

	Canvas.Style = Style;
	Canvas.StrLen(TitleString$": ", XL, YL);
	X1 = XL;
	Canvas.StrLen(ValueString, XL, YL);
	XOffset = Canvas.ClipX/2 - (X1+XL)/2;
	Canvas.SetPos(XOffset, YStart);
	XOffset += X1;
	Canvas.DrawText(TitleString);
	Canvas.SetPos(XOffset, YStart);
	Canvas.DrawText(ValueString);
	Canvas.DrawColor = MyHUD.WhiteColor;
}

simulated function PostRender(canvas C)
{
	local Pawn P;
	
	if(NextHUDMutator != none)
		NextHUDMutator.postRender(c); 

	if(MyHUD == none) 
	{
	    MyPlayer = c.Viewport.Actor;
	    if ( MyPlayer != None )
    	    MyHUD = MyPlayer.myHUD;		
	}
	
	for (P = Level.PawnList; P != None; P = P.NextPawn)
	{
		if (P == MyPlayer || P.health < 1 || P.bHidden)
			return;
		
		DrawBar(C, P);
	}
	
}
