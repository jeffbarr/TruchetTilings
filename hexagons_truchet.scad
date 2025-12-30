// Hexagons with Truchet-inspired tiles via Kerry Mitchell's article:
//
// "Generalizations of Truchet Tiles" 
// https://archive.bridgesmathart.org/2020/bridges2020-191.html
//

//
// CONFIGURATION
//	[Hexagons] controls the size and appearance of each hexagon.
//
//	[Grid] controls the overall size and configuration (including random seed)
//  of the grid of hexagons.
//
//	[Borders] controls the appearance of the four possible borders.
//
//	[Corners] controls the appearance of the four possible corners.
//
//	[Extruders] controls which extruder will be used for each type of element:
//
//		- TileExtruder - Body of the hexagon
//		- ArcExtruder  - Arcs on top of hexagon
//		- FillExtruder - Fill between arcs for patterns 3, 4, 5, and 6
//		- EdgeExtruder - Inlaid edge of hexagon
//
//	[Mat] provides an alternate way to set up borders and corners. If it 
//	is set to "Manual" then the values in [Borders] and [Corners] apply.
//
//	Otherwise, the value ("A" through "M" as documented in 
//	https://docs.google.com/document/d/1lFDn3-urD4o3PvHtm6bd0SUD1x2gzSSJPIn_AOtbqk4/edit?tab=t.0)
//	is used to set the borders and the corners.
//
//	Uses either one of two sets of patterns:
//
//	1-2			One line per hexagon side
//	3-4-5-6		Three lines per hexagon side
//
//	Or:
//	1 .. 6		Just one pattern
//
//  Can optionally rotate pattern 2 to add variety (Rotate2*).
//
//  Can optionally add embedded XY labels to each hexagon, rendered using the EdgeExtruder.
//

// BUGS
// Top border does not work if row count is odd
// Right border is positioned wrong if column count is even
//

//
// TODO
// - Add asserts or warnings for stuff that does not work well based on odd/even
// - Option to embed arcs into hexagons instead of on top
// - Arcs on half hexagons
// - Way to make underlapped border to join prints together
// - Way to map object() into a bunch of JSON that works as a config
//

/* [Hexagons] */
// Hexagon radius
_HexRadius = 20;

// Hexagon height
_HexHeight = 0.8;

// Arc height
_ArcHeight = 0.2;

// Arc width
_ArcWidth = 0.20;

// Edge height
_EdgeHeight = 0.2;

// Edge width
_EdgeWidth = 0.1;

// XY Labels
_XYLabels = false;

/* [Truchet] */
// Truchet mode
_TruchetMode = "1-2";	// ["1", "2", "3", "4", "5", "6", "1-2", "3-4-5-6"]

// Rotate pattern 2
_Rotate2 = true;

// Rotate 2 factor
_Rotate2Factor = 2;

// Rotate 2 mod
_Rotate2Mod = 5;

/* [Grid] */
// Column count
_CountX = 10;

// Row count
_CountY = 10;

// Gap
_Gap = 0.4;

// Random seed
_RandomSeed = 131313;

/* [Mat] */
// Mat
_Mat = "Manual";	// ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M"]

/* [Borders] */

// Left
_LeftBorder = true;

// Right
_RightBorder = true;

// Top
_TopBorder = true;

// Bottom
_BottomBorder = true;

/* [Corners] */

// Bottom left
_BottomLeftCorner = false;

// Top left
_TopLeftCorner = false;

// Bottom right
_BottomRightCorner = false;

// Top right
_TopRightCorner = false;

// [Extruders]

/* [Extruders] */

// Tile extruder
_TileExtruder = 1;

// Arc extruder
_ArcExtruder = 2;

// Fill extruder (or 0)
_FillExtruder = 3;

// Edge extruder (or 0)
_EdgeExtruder = 0;

// [Extruder to render]
_WhichExtruder = "All"; // ["All", 1, 2, 3, 4, 5]

// Map a value of _WhichExtruder to an OpenSCAD color
function ExtruderColor(Extruder) = 
  (Extruder == 1  ) ? "red"    : 
  (Extruder == 2  ) ? "green"  : 
  (Extruder == 3  ) ? "blue"   : 
  (Extruder == 4  ) ? "pink"   :
  (Extruder == 5  ) ? "yellow" :
                      "purple" ;
					  
module EndParams(){};

// Identifiers (index into HexPoints) for the points of the hexagon
A = 0;
B = 1;
C = 2;
D = 3;
E = 4;
F = 5;

// Index into X,Y of each HexPoints element
X = 0;
Y = 1;

// Part of hexagon to render
HEX_ALL          = 1;
HEX_LEFT         = 2;
HEX_RIGHT        = 3;
HEX_TOP          = 4;
HEX_BOTTOM       = 5;
HEX_BOTTOM_LEFT  = 6;
HEX_BOTTOM_RIGHT = 7;

// If _WhichExtruder is "All" or is not "All" and matches the 
// requested extruder, render the child nodes.

module Extruder(DoExtruder)
{
   color(ExtruderColor(DoExtruder))
   {
     if (_WhichExtruder == "All" || DoExtruder == _WhichExtruder)
     {
       children();
     }
   }
}

//
// RenderRing -
//
//	Render a ring, outside radius of Radius + Width / 2,
//	inside radius of Radius - Width / 2.
//

module RenderRing(Radius, Width)
{
	difference()
	{
		circle(Radius + Width / 2, $fn=99);
		circle(Radius - Width / 2, $fn=99);
	}
}

//
// RenderLine -
//

module RenderLine(Length, Width)
{
	translate([-Width / 2, 0, 0])
	{
		square([Width, Length], center=false);
	}
}

// 
// RenderArc -
//
//	Based on ArcIndex, render the arcs across the hexagon. Clipping
//	to the actual shape of the hexagon takes place in RenderHexagon.
//
//	Nothing is rendered if ArcIndex is 0.
//

module RenderArc(HexRadius, HexPoints, ArcIndex, ArcWidth, ArcExtruder, FillExtruder)
{
	// Commpute sides of triangles adjoining the hexagon
	DX = sin(30) * HexRadius;
	DY = sin(60) * HexRadius;

	// Compute coordinates of projections
	ProAFBC_X = HexPoints[A][X] + DX;
	ProAFBC_Y = HexPoints[B][Y];
	
	ProBCDE_X = HexPoints[C][X] - 2 * DX;
	ProBCDE_Y = HexPoints[C][Y];

	ProCDEF_X = HexPoints[D][X] - DX;
	ProCDEF_Y = HexPoints[E][Y];
	
	ProDEAF_X = HexPoints[E][X] + DX;
	ProDEAF_Y = HexPoints[E][Y] - DY;
	
	if (ArcIndex == 1)
	{
		// Rings around A, C, and E
		translate([HexPoints[A][X], HexPoints[A][Y], 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius / 2, ArcWidth);
			}
		}

		translate([HexPoints[C][X], HexPoints[C][Y], 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius / 2, ArcWidth);
			}
		}
	
		translate([HexPoints[E][X], HexPoints[E][Y], 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius / 2, ArcWidth);
			}
		}
	}
	
	if (ArcIndex == 2)
	{
		// Rings around A and D, Vertical line connnecting BC and EF
		MidEF_X = (HexPoints[E][X] + HexPoints[F][X])/ 2;
		MidEF_Y = (HexPoints[E][Y] + HexPoints[F][Y])/ 2;
		
		translate([HexPoints[A][X], HexPoints[A][Y], 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius / 2, ArcWidth);
			}
		}
		
		translate([HexPoints[D][X], HexPoints[D][Y], 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius / 2, ArcWidth);
			}
		}
		
		translate([MidEF_X, MidEF_Y, 0])
		{
			Extruder(ArcExtruder)
			{
				RenderLine(2 * DY, ArcWidth);
			}
		}
	}
	
	if (ArcIndex == 3)
	{
		// Rings around A, C, and E at 1/3 and 2/3 of radius, with optional infill ring between them
		translate([HexPoints[A][X], HexPoints[A][Y], 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius / 3,     ArcWidth);
				RenderRing(2 * HexRadius / 3, ArcWidth);
			}
			
			if (FillExtruder)
			{
				Extruder(FillExtruder)
				{
					RenderRing(HexRadius / 3 + HexRadius / 6, HexRadius / 3 - ArcWidth);
				}
			}
		}
		
		translate([HexPoints[C][X], HexPoints[C][Y], 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius / 3,     ArcWidth);
				RenderRing(2 * HexRadius / 3, ArcWidth);
			}
			
			if (FillExtruder)
			{
				Extruder(FillExtruder)
				{
					RenderRing(HexRadius / 3 + HexRadius / 6, HexRadius / 3 - ArcWidth);
				}
			}
		}
	
		translate([HexPoints[E][X], HexPoints[E][Y], 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius / 3,     ArcWidth);
				RenderRing(2 * HexRadius / 3, ArcWidth);
			}
			
			if (FillExtruder)
			{
				Extruder(FillExtruder)
				{
					RenderRing(HexRadius / 3 + HexRadius / 6, HexRadius / 3 - ArcWidth);
				}
			}
		}
	}

	if (ArcIndex == 4)
	{
		// Rings at midpoint of A/B, C/D, and E/F, optional fill of center triad
		MidAB_X = (HexPoints[A][X] + HexPoints[B][X])/ 2;
		MidAB_Y = (HexPoints[A][Y] + HexPoints[B][Y])/ 2;

		MidCD_X = (HexPoints[C][X] + HexPoints[D][X])/ 2;
		MidCD_Y = (HexPoints[C][Y] + HexPoints[D][Y])/ 2;

		MidEF_X = (HexPoints[E][X] + HexPoints[F][X])/ 2;
		MidEF_Y = (HexPoints[E][Y] + HexPoints[F][Y])/ 2;

		translate([MidAB_X, MidAB_Y, 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius / 6, ArcWidth);
			}
		}
		
		translate([MidCD_X, MidCD_Y, 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius / 6, ArcWidth);
			}
		}

		translate([MidEF_X, MidEF_Y, 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius / 6, ArcWidth);
			}
		}
		
		//Rings at intersection of projections of AF & BC, BC & DE, and DE & AF
		translate([ProAFBC_X, ProAFBC_Y, 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius + HexRadius / 3, ArcWidth);
			}
		}
		
		translate([ProBCDE_X, ProBCDE_Y, 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius + HexRadius / 3, ArcWidth);
			}
		}

		translate([ProDEAF_X, ProDEAF_Y, 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius + HexRadius / 3, ArcWidth);
			}
		}
		
		if (FillExtruder)
		{
			Extruder(FillExtruder)
			{
				// Triad
				difference()
				{
					square(HexRadius * 3, center=true);
						
					union()
					{
						translate([ProAFBC_X, ProAFBC_Y, 0])
						{
							circle(HexRadius + HexRadius / 3 + ArcWidth / 4, $fn=99);
						}
						
						translate([ProBCDE_X, ProBCDE_Y, 0])
						{
							circle(HexRadius + HexRadius / 3 + ArcWidth / 4, $fn=99);
						}
				
						translate([ProDEAF_X, ProDEAF_Y, 0])
						{
							circle(HexRadius + HexRadius / 3 + ArcWidth / 4, $fn=99);
						}
					}
				}
				
				// Circles
				translate([MidAB_X, MidAB_Y, 0])
				{
					circle(HexRadius / 6 - ArcWidth / 2, $fn=99);
				}
		
				translate([MidCD_X, MidCD_Y, 0])
				{
					circle(HexRadius / 6 - ArcWidth / 2, $fn=99);
				}

				translate([MidEF_X, MidEF_Y, 0])
				{
					circle(HexRadius / 6 - ArcWidth / 2, $fn=99);
				}
			}
		}
	}

	if (ArcIndex == 5)
	{
		// Vertical lines connnecting BC and EF, rings at A and D, optional fill between vertical lines
		OneThirdEF_X = HexPoints[E][X] + HexRadius / 3;
		OneThirdEF_Y = HexPoints[E][Y];
		
		TwoThirdEF_X = HexPoints[E][X] + 2 * (HexRadius / 3);
		TwoThirdEF_Y = HexPoints[E][Y];
		
		translate([OneThirdEF_X, OneThirdEF_Y, 0])
		{
			Extruder(ArcExtruder)
			{
				RenderLine(2 * DY, ArcWidth);
			}
		}

		translate([TwoThirdEF_X, TwoThirdEF_Y, 0])
		{
			Extruder(ArcExtruder)
			{
				RenderLine(2 * DY, ArcWidth);
			}
		}
		
		if (FillExtruder)
		{
			Extruder(FillExtruder)
			{
				translate([0, -DY, 0])
				{
					RenderLine(2 * DY, HexRadius / 3 - ArcWidth / 2);
				}
			}
		}
		
		translate([HexPoints[A][X], HexPoints[A][Y], 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius / 3,     ArcWidth);
				RenderRing(2 * HexRadius / 3, ArcWidth);
			}
			
			if (FillExtruder)
			{
				Extruder(FillExtruder)
				{
					RenderRing(HexRadius / 3 + HexRadius / 6, HexRadius / 3 - ArcWidth);
				}
			}
		}
	
		translate([HexPoints[D][X], HexPoints[D][Y], 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius / 3,     ArcWidth);
				RenderRing(2 * HexRadius / 3, ArcWidth);
			}
			
			if (FillExtruder)
			{
				Extruder(FillExtruder)
				{
					RenderRing(HexRadius / 3 + HexRadius / 6, HexRadius / 3 - ArcWidth);
				}
			}
		}
	}
	
	if (ArcIndex == 6)
	{
		// Single rings at midpoint of AB and DE, double rings between AF and BC, CD and EF, optional fill between rings
		MidAB_X = (HexPoints[A][X] + HexPoints[B][X]) / 2;
		MidAB_Y = (HexPoints[A][Y] + HexPoints[B][Y]) / 2;

		MidDE_X = (HexPoints[D][X] + HexPoints[E][X]) / 2;
		MidDE_Y = (HexPoints[D][Y] + HexPoints[E][Y]) / 2;
		
		translate([MidAB_X, MidAB_Y, 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius / 6, ArcWidth);
			}
			
			if (FillExtruder)
			{
				Extruder(FillExtruder)
				{
					circle(HexRadius / 6 - ArcWidth / 2, $fn=99);
				}
			}
		}
		
		translate([MidDE_X, MidDE_Y, 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius / 6, ArcWidth);
			}
			
			if (FillExtruder)
			{
				Extruder(FillExtruder)
				{
					circle(HexRadius / 6 - ArcWidth / 2, $fn=99);
				}
			}
		}
		
		translate([ProAFBC_X, ProAFBC_Y, 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius + HexRadius / 3, ArcWidth);
				RenderRing(HexRadius + 2 * HexRadius / 3, ArcWidth);
			}

			if (FillExtruder)
			{
				Extruder(FillExtruder)
				{
					RenderRing(HexRadius + DX, HexRadius / 3 - ArcWidth);
				}
			}
		}
		
		translate([ProCDEF_X, ProCDEF_Y, 0])
		{
			Extruder(ArcExtruder)
			{
				RenderRing(HexRadius + HexRadius / 3, ArcWidth);
				RenderRing(HexRadius + 2 * HexRadius / 3, ArcWidth);
			}
			
			if (FillExtruder)
			{
				Extruder(FillExtruder)
				{
					RenderRing(HexRadius + DX, HexRadius / 3 - ArcWidth);
				}
			}
		}
	}
}

// Render the base of the given full or partial hexagon to the given height
module RenderHexagonBase(HexPoints, HexHeight)
{
	linear_extrude(HexHeight)
	{
		polygon(HexPoints);
	}
}

// Render the edge of the given full or partial hexagon, with the given height and width
module RenderHexagonEdge(HexPoints, EdgeWidth, EdgeHeight)
{
	linear_extrude(EdgeHeight)
	{
		difference()
		{
			// Matter
			polygon(HexPoints);
			
			// Anti=matter
			offset(delta=-EdgeWidth)
			{
				polygon(HexPoints);
			}
		}
	}
}

// Render an (X, Y) label with the given height
module RenderHexagonLabel(X, Y, Height)
{
	linear_extrude(Height)
	{
		Label = str("[", X, ",", Y, "]");
		text(text=Label, size=12, halign="center", valign="center");
	}
}

//
// Render full (HexPart = HEX_ALL) or part (the other values) of a hexagon, with arcs on top as specified by ArcIndex, 
// optional (if EdgeExtruder non-zero) inlaid edge, and optional (if XYLabel true) embedded XY coordinate label using
// EdgeExtruder.
//

module RenderHexagon(HexPart, HexRadius, HexHeight, ArcHeight, ArcWidth, ArcIndex, TileExtruder, ArcExtruder, FillExtruder, EdgeExtruder, EdgeWidth, EdgeHeight, XYLabel, X, Y)
{
	HexPointsAll = 
	[
		[HexRadius,				0],						// A
		[HexRadius * cos(60), 	HexRadius * sin(60)],	// B
		[HexRadius * cos(120), 	HexRadius * sin(120)],	// C
		[-HexRadius,			0],						// D
		[HexRadius * cos(240), 	HexRadius * sin(240)],	// E
		[HexRadius * cos(300), 	HexRadius * sin(300)]	// F
	];

	HexPointsLeft = 
	[
		[HexRadius * cos(120), 	HexRadius * sin(120)],	// C
		[-HexRadius,			0],						// D
		[HexRadius * cos(240), 	HexRadius * sin(240)]	// E
	];
	
	HexPointsRight = 
	[
		[HexRadius,				0],						// A
		[HexRadius * cos(60), 	HexRadius * sin(60)],	// B
		[HexRadius * cos(300), 	HexRadius * sin(300)]	// F
	];
		
	HexPointsBottom =
	[
		[HexRadius,				0],						// A
		[-HexRadius,			0],						// D
		[HexRadius * cos(240), 	HexRadius * sin(240)],	// E
		[HexRadius * cos(300), 	HexRadius * sin(300)]	// F
	];
	
	HexPointsTop =
	[
		[HexRadius,				0],						// A
		[HexRadius * cos(60), 	HexRadius * sin(60)],	// B
		[HexRadius * cos(120), 	HexRadius * sin(120)],	// C
		[-HexRadius,			0]						// D
	];
	
	HexPointsBottomRight =
	[
		[HexRadius,				0],						// A
		[HexRadius - (HexRadius * sin(30)),  0],		//
		[HexRadius * cos(300), 	HexRadius * sin(300)]	// F
	];
	
	HexPointsBottomLeft =
	[
		[-HexRadius + (HexRadius * sin(30)),   0],						//
		[-HexRadius,			               0],						// D
		[HexRadius * cos(240), 	               HexRadius * sin(240)]	// E
	];

	// Select points for full or partial hexagon
	HexPoints = (HexPart == HEX_ALL)          ? HexPointsAll         :
	            (HexPart == HEX_LEFT)         ? HexPointsLeft        :
	            (HexPart == HEX_RIGHT)        ? HexPointsRight       :
	            (HexPart == HEX_TOP)          ? HexPointsTop         :
	            (HexPart == HEX_BOTTOM)       ? HexPointsBottom      :
	            (HexPart == HEX_BOTTOM_RIGHT) ? HexPointsBottomRight :
	            (HexPart == HEX_BOTTOM_LEFT)  ? HexPointsBottomLeft  :
				[];
	
	union()
	{
		// Base with optional inlaid edge
		if (EdgeExtruder)
		{
			// Render the base, subtract the edge, then render the edge into the vacated space
			union()
			{
				Extruder(TileExtruder)
				{
					difference()
					{
						RenderHexagonBase(HexPoints, HexHeight);
					
						translate([0, 0, HexHeight - EdgeHeight])
						{
							RenderHexagonEdge(HexPoints, EdgeWidth, EdgeHeight);
							
							if (XYLabel)
							{
								RenderHexagonLabel(X, Y, EdgeHeight);
							}
						}
					}
				}
				
				Extruder(EdgeExtruder)
				{
					translate([0, 0, HexHeight - EdgeHeight])
					{
						RenderHexagonEdge(HexPoints, EdgeWidth, EdgeHeight);
						
						if (XYLabel)
						{
							RenderHexagonLabel(X, Y, EdgeHeight);
						}
					}	
				}
			}
		}
		else
		{
			Extruder(TileExtruder)
			{
				RenderHexagonBase(HexPoints, HexHeight);
			}
		}
		
		// Arcs
		if (ArcIndex)
		{
			translate([0, 0, HexHeight])
			{	
				linear_extrude(ArcHeight)
				{
					intersection()
					{
						polygon(HexPoints);

						RenderArc(HexRadius, HexPoints, ArcIndex, ArcWidth, ArcExtruder, FillExtruder);
					}
				}
			}
		}
	}
}

function RandomIntsInRange(Minimum, Maximum, Count, Seed) =
    let(floats = rands(Minimum, Maximum + 1, Count, Seed))
    [ for (f = floats) floor(f) ];
	
function MinForTruchetMode(Mode) =
	(Mode == "1")       ? 1 :
	(Mode == "2")       ? 2 :
	(Mode == "3")       ? 3 :
	(Mode == "4")       ? 4 :
	(Mode == "5")       ? 5 :
	(Mode == "6")       ? 6 :
	(Mode == "1-2")     ? 1 :
	(Mode == "3-4-5-6") ? 3 :
	                      99;

function MaxForTruchetMode(Mode) =
	(Mode == "1")       ? 1 :
	(Mode == "2")       ? 2 :
	(Mode == "3")       ? 3 :
	(Mode == "4")       ? 4 :
	(Mode == "5")       ? 5 :
	(Mode == "6")       ? 6 :
	(Mode == "1-2")     ? 2 :
	(Mode == "3-4-5-6") ? 6 :
	                      99;

function GetPointX(SpaceX, X) = (SpaceX * X);
function GetPointY(SpaceY, Y) = (SpaceY * Y);

module main(Args)
{
	echo(Args);

	// Select range of random numbers (and arc indexes) based on Truchet mode
	Min = MinForTruchetMode(Args.TruchetMode);
	Max = MaxForTruchetMode(Args.TruchetMode);
	ArcIndexes = RandomIntsInRange(Min, Max, Args.CountX * Args.CountY, Args.RandomSeed);
	
	// Compute spacing in X and Y
	SpaceX = 1.5 * (Args.HexRadius + Args.Gap);
	SpaceY = (Args.HexRadius + Args.Gap) / 2 * sqrt(3);
	
	// Render grid of hexagons
	for (Y = [0 : 2 : Args.CountY - 1])
	{
		for (X = [Args.StartX : Args.CountX - 1])
		{
			OddColumn = (X % 2) == 1 ? 1 : 0;
				
			PointX = GetPointX(SpaceX, X);
			PointY = GetPointY(SpaceY, (OddColumn ? Y : Y + 1));
			
			translate([PointX, PointY, 0])
			{
				ArcIndex = ArcIndexes[Y * Args.CountX + X];
				
				// Special handling for pattern 2
				if (Args.Rotate2 && (ArcIndex == 2))
				{
					Rot = ((X * Args.Rotate2Factor * Y) % Args.Rotate2Mod) * 60;
					rotate([0, 0, Rot])
					{
						RenderHexagon(HEX_ALL, Args.HexRadius, Args.HexHeight, Args.ArcHeight, Args.ArcWidth, ArcIndex, Args.TileExtruder, Args.ArcExtruder, Args.FillExtruder, Args.EdgeExtruder, Args.EdgeWidth, Args.EdgeHeight, Args.XYLabels, X, Y);
					}
				}
				else
				// All other patterns
				{
					RenderHexagon(HEX_ALL, Args.HexRadius, Args.HexHeight, Args.ArcHeight, Args.ArcWidth, ArcIndex, Args.TileExtruder, Args.ArcExtruder, Args.FillExtruder, Args.EdgeExtruder, Args.EdgeWidth, Args.EdgeHeight, Args.XYLabels, X, Y);
				}
			}
		}
	}
	
	// Render border around grid of hexagons
	for (Y = [0 : 2 : Args.CountY - 1])
	{
		for (X = [Args.StartX : Args.CountX - 1])
		{
			OddColumn = (X % 2) == 1 ? 1 : 0;
			
			// See if we are rendering adjacent to a border	and set flags appropriately	 	
			AtLeftBorder   = (X == 0);
			AtRightBorder  = (X == (Args.CountX - 1));
			AtBottomBorder = (Y == 0);
			AtTopBorder    = (Y == (Args.CountY - 2));
			
			// See if we are rendering a corner and set flags appropriately
			AtTopLeftCorner     = AtLeftBorder  && AtTopBorder;
			AtBottomLeftCorner  = AtLeftBorder  && AtBottomBorder;
			AtTopRightCorner    = AtRightBorder && AtTopBorder;
			AtBottomRightCorner = AtRightBorder && AtBottomBorder;
			
			// Left border and possible bottom left corner
			if (Args.LeftBorder && AtLeftBorder && !AtBottomLeftCorner || (AtBottomLeftCorner && Args.BottomLeftCorner))
			{
				PointX = GetPointX(SpaceX, X - 1);
				PointY = GetPointY(SpaceY, Y);
				
				translate([PointX, PointY, 0])
				{
					RenderHexagon(HEX_RIGHT, Args.HexRadius, Args.HexHeight, Args.ArcHeight, Args.ArcWidth, 0, Args.TileExtruder, Args.ArcExtruder, Args.FillExtruder, Args.EdgeExtruder, Args.EdgeWidth, Args.EdgeHeight, false, 0, 0);
				}
			}
			
			// Right border and possible bottom right corner
			if (Args.RightBorder && AtRightBorder && !AtBottomRightCorner || (AtBottomRightCorner && Args.BottomRightCorner))
			{
				PointX = GetPointX(SpaceX, X + 1);
				PointY = GetPointY(SpaceY, Y);
				
				translate([PointX, PointY, 0])
				{
					RenderHexagon(HEX_LEFT, Args.HexRadius, Args.HexHeight, Args.ArcHeight, Args.ArcWidth, 0, Args.TileExtruder, Args.ArcExtruder, Args.FillExtruder, Args.EdgeExtruder, Args.EdgeWidth, Args.EdgeHeight, false, 0, 0);
				}					
			}
			
			// Top border
			if (Args.TopBorder && AtTopBorder && OddColumn)
			{
				PointX = GetPointX(SpaceX, X);
				PointY = GetPointY(SpaceY, Y + 2);
							
				translate([PointX, PointY, 0])
				{
					RenderHexagon(HEX_BOTTOM, Args.HexRadius, Args.HexHeight, Args.ArcHeight, Args.ArcWidth, 0, Args.TileExtruder, Args.ArcExtruder, Args.FillExtruder, Args.EdgeExtruder, Args.EdgeWidth, Args.EdgeHeight, false, 0, 0);
				}
			}
			
			// Bottom border
			if (Args.BottomBorder && AtBottomBorder && !OddColumn)
			{
				PointX = GetPointX(SpaceX, X);
				PointY = GetPointY(SpaceY, Y - 1);
							
				translate([PointX, PointY, 0])
				{
					RenderHexagon(HEX_TOP, Args.HexRadius, Args.HexHeight, Args.ArcHeight, Args.ArcWidth, 0, Args.TileExtruder, Args.ArcExtruder, Args.FillExtruder, Args.EdgeExtruder, Args.EdgeWidth, Args.EdgeHeight, false, 0, 0);
				}
			}
			
			// Top left corner
			if (AtTopLeftCorner && Args.TopLeftCorner)
			{
				PointX = GetPointX(SpaceX, X - 1);
				PointY = GetPointY(SpaceY, Y + 2);

				translate([PointX, PointY, 0])
				{
					RenderHexagon(HEX_BOTTOM_RIGHT, Args.HexRadius, Args.HexHeight, Args.ArcHeight, Args.ArcWidth, 0, Args.TileExtruder, Args.ArcExtruder, Args.FillExtruder, Args.EdgeExtruder, Args.EdgeWidth, Args.EdgeHeight, false, 0, 0);
				}
			}
			
			// Top right corner
			if (AtTopRightCorner && Args.TopRightCorner)
			{
				PointX = GetPointX(SpaceX, X + 1);
				PointY = GetPointY(SpaceY, Y + 2);

				translate([PointX, PointY, 0])
				{
					RenderHexagon(HEX_BOTTOM_LEFT, Args.HexRadius, Args.HexHeight, Args.ArcHeight, Args.ArcWidth, 0, Args.TileExtruder, Args.ArcExtruder, Args.FillExtruder, Args.EdgeExtruder, Args.EdgeWidth, Args.EdgeHeight, false, 0, 0);
				}
			}
		}
	}
}

//
// Gather arguments and call main:
//
//	BaseArgs are the arguments used regardless of _Mat
//	ManualArgs are additional arguments if Mat is set to "Manual"
//	MatA_Args ... MatJ_Args are used if Mat is set to "A" ... "J", respectively
//

BaseArgs = 
	object(
			[
				["ArcExtruder",			_ArcExtruder],
				["ArcHeight", 			_ArcHeight],
				["ArcWidth", 			_ArcWidth],
				["CountX", 				_CountX],
				["CountY", 				_CountY],
				["EdgeExtruder",		_EdgeExtruder],
				["EdgeHeight",			_EdgeHeight],
				["EdgeWidth",			_EdgeWidth],
				["FillExtruder",		_FillExtruder],
				["Gap",					_Gap],
				["HexHeight", 			_HexHeight],
				["HexRadius", 			_HexRadius],
				["RandomSeed",			_RandomSeed],
				["Rotate2", 			_Rotate2],
				["Rotate2Factor",		_Rotate2Factor],
				["Rotate2Mod",			_Rotate2Mod],
				["TileExtruder",		_TileExtruder],
				["TruchetMode", 		_TruchetMode],
				["XYLabels",		    _XYLabels]
			]
		);

ManualArgs =
	object(
			[
				["StartX",				0],
				["LeftBorder",			_LeftBorder],				
				["RightBorder",			_RightBorder],
				["TopBorder",			_TopBorder],
				["BottomBorder",		_BottomBorder],
				["TopLeftCorner",		_TopLeftCorner],
				["TopRightCorner",		_TopRightCorner],
				["BottomLeftCorner",	_BottomLeftCorner],
				["BottomRightCorner",	_BottomRightCorner]
			]
	);

MatA_Args = 
	object(
			[
				["StartX",				0],
				["LeftBorder",			true],				
				["RightBorder",			true],
				["TopBorder",			true],
				["BottomBorder",		true],
				["TopLeftCorner",		true],
				["TopRightCorner",		true],
				["BottomLeftCorner",	true],
				["BottomRightCorner",	true]
			]
	);
		
MatB_Args = 
	object(
			[
				["StartX",				0],
				["LeftBorder",			true],				
				["RightBorder",			false],
				["TopBorder",			true],
				["BottomBorder",		false],
				["TopLeftCorner",		true],
				["TopRightCorner",		false],
				["BottomLeftCorner",	true],
				["BottomRightCorner",	false]
			]
	);

MatC_Args = 
	object(
			[
				["StartX",				1],
				["LeftBorder",			false],				
				["RightBorder",			true],
				["TopBorder",			true],
				["BottomBorder",		false],
				["TopLeftCorner",		false],
				["TopRightCorner",		true],
				["BottomLeftCorner",	false],
				["BottomRightCorner",	true]
			]
	);

MatD_Args =
	object(
			[
				["StartX",				0],
				["LeftBorder",			true],				
				["RightBorder",			false],
				["TopBorder",			false],
				["BottomBorder",		true],
				["TopLeftCorner",		false],
				["TopRightCorner",		false],
				["BottomLeftCorner",	true],
				["BottomRightCorner",	false]
			]
	);

MatE_Args = 
	object(
			[
				["StartX",				1],
				["LeftBorder",			false],				
				["RightBorder",			true],
				["TopBorder",			false],
				["BottomBorder",		true],
				["TopLeftCorner",		false],
				["TopRightCorner",		false],
				["BottomLeftCorner",	true],
				["BottomRightCorner",	true]
			]
	);

MatF_Args = 
	object(
			[
				["StartX",				1],
				["LeftBorder",			false],				
				["RightBorder",			false],
				["TopBorder",			true],
				["BottomBorder",		false],
				["TopLeftCorner",		false],
				["TopRightCorner",		false],
				["BottomLeftCorner",	false],
				["BottomRightCorner",	false]
			]
	);

MatG_Args =
	object(
			[
				["StartX",				0],
				["LeftBorder",			true],				
				["RightBorder",			false],
				["TopBorder",			false],
				["BottomBorder",		false],
				["TopLeftCorner",		false],
				["TopRightCorner",		false],
				["BottomLeftCorner",	true],
				["BottomRightCorner",	false]
			]
	);

MatH_Args =
	object(
			[
				["StartX",				1],
				["LeftBorder",			false],				
				["RightBorder",			false],
				["TopBorder",			false],
				["BottomBorder",		false],
				["TopLeftCorner",		false],
				["TopRightCorner",		false],
				["BottomLeftCorner",	false],
				["BottomRightCorner",	false]
			]
	);

MatI_Args =
	object(
			[
				["StartX",				1],
				["LeftBorder",			false],				
				["RightBorder",			true],
				["TopBorder",			false],
				["BottomBorder",		false],
				["TopLeftCorner",		false],
				["TopRightCorner",		false],
				["BottomLeftCorner",	false],
				["BottomRightCorner",	true]
			]
	);

MatJ_Args = 
	object(
			[
				["StartX",				1],
				["LeftBorder",			false],				
				["RightBorder",			false],
				["TopBorder",			false],
				["BottomBorder",		true],
				["TopLeftCorner",		false],
				["TopRightCorner",		false],
				["BottomLeftCorner",	false],
				["BottomRightCorner",	false]
			]
	);

MatK_Args = 
	object(
			[
				["StartX",				0],
				["LeftBorder",			true],				
				["RightBorder",			false],
				["TopBorder",			true],
				["BottomBorder",		true],
				["TopLeftCorner",		true],
				["TopRightCorner",		false],
				["BottomLeftCorner",	true],
				["BottomRightCorner",	false]
			]
	);

MatL_Args = 
	object(
			[
				["StartX",				1],
				["LeftBorder",			false],				
				["RightBorder",			true],
				["TopBorder",			true],
				["BottomBorder",		true],
				["TopLeftCorner",		false],
				["TopRightCorner",		true],
				["BottomLeftCorner",	false],
				["BottomRightCorner",	true]
			]
	);


MatM_Args = 
	object(
			[
				["StartX",				1],
				["LeftBorder",			false],				
				["RightBorder",			false],
				["TopBorder",			true],
				["BottomBorder",		true],
				["TopLeftCorner",		false],
				["TopRightCorner",		false],
				["BottomLeftCorner",	false],
				["BottomRightCorner",	false]
			]
	);
	
MatArgs =
	(_Mat == "Manual") ? ManualArgs :
	(_Mat == "A")      ? MatA_Args  :
	(_Mat == "B")      ? MatB_Args  :
	(_Mat == "C")      ? MatC_Args  :
	(_Mat == "D")      ? MatD_Args  :
	(_Mat == "E")      ? MatE_Args  :
	(_Mat == "F")      ? MatF_Args  :
	(_Mat == "G")      ? MatG_Args  :
	(_Mat == "H")      ? MatH_Args  :
	(_Mat == "I")      ? MatI_Args  :
	(_Mat == "J")      ? MatJ_Args  :
	(_Mat == "K")      ? MatK_Args  :
	(_Mat == "L")      ? MatL_Args  :
	(_Mat == "M")      ? MatM_Args  :
                         NULL;
 
main(object(BaseArgs, MatArgs));
