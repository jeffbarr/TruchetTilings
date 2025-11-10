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
//	[Extruders] controls which extruder will be used for each type of element:
//
//		- TileExtruder - Body of the hexagon
//		- ArcExtruder  - Arcs on top of hexagon
//		- FillExtruder - Fill between arcs for patterns 3, 4, 5, and 6
//		- EdgeExtruder - Inlaid edge of hexagon
//

//
// BUGS
// Right border is positioned wrong if column count is even
// Top border does not work if row count is odd
//

//
// TODO
/// - Arcs on half hexagons
// - Should Arc pattern 2 be rotated, yes, add more control
// - Way to make underlapped border to join prints together
// - Turn all PointX/PointY calculations into calls to a pair of functions
// - Option to embed arcs into hexagons instead of on top
//

//	Uses either one of two sets of patterns:
//
//	1-2			One line per hexagon side
//	3-4-5-6		Three lines per hexagon side
//
//	Or:
//	1 .. 6		Just one pattern
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

// Truchet mode
_TruchetMode = "1-2";	// ["1", "2", "3", "4", "5", "6", "1-2", "3-4-5-6"]

/* [Grid] */
// Column count
_CountX = 10;

// Row count
_CountY = 10;

// Gap
_Gap = 0.4;

// Random seed
_RandomSeed = 131313;

/* [Borders] */

// Left
_LeftBorder = true;

// Right
_RightBorder = true;

// Top
_TopBorder = true;

// Bottom
_BottomBorder = true;

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
HEX_ALL    = 1;
HEX_LEFT   = 2;
HEX_RIGHT  = 3;
HEX_TOP    = 4;
HEX_BOTTOM = 5;

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
							circle(HexRadius + HexRadius / 3, $fn=99);
						}
						
						translate([ProBCDE_X, ProBCDE_Y, 0])
						{
							circle(HexRadius + HexRadius / 3, $fn=99);
						}
				
						translate([ProDEAF_X, ProDEAF_Y, 0])
						{
							circle(HexRadius + HexRadius / 3, $fn=99);
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

// Render the edge of the given full or partial hexagon, wiht the given height and width
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

//
// Render full (HexPart = HEX_ALL) or part (the other values) of a hexagon, with arcs on top as specified by ArcIndex, 
// and optional (if EdgeExtruder non-zero) inlaid edge.
//

module RenderHexagon(HexPart, HexRadius, HexHeight, ArcHeight, ArcWidth, ArcIndex, TileExtruder, ArcExtruder, FillExtruder, EdgeExtruder, EdgeWidth, EdgeHeight)
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
	
	// Select points for full or partial hexagon
	HexPoints = (HexPart == HEX_ALL)    ? HexPointsAll    :
	            (HexPart == HEX_LEFT)   ? HexPointsLeft   :
	            (HexPart == HEX_RIGHT)  ? HexPointsRight  :
	            (HexPart == HEX_TOP)    ? HexPointsTop    :
	            (HexPart == HEX_BOTTOM) ? HexPointsBottom :
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
						}
					}
				}
				
				Extruder(EdgeExtruder)
				{
					translate([0, 0, HexHeight - EdgeHeight])
					{
						RenderHexagonEdge(HexPoints, EdgeWidth, EdgeHeight);
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
		
module main(CountX, CountY, TruchetMode, HexRadius, HexHeight, ArcHeight, ArcWidth, RandomSeed, Gap, TileExtruder, ArcExtruder, FillExtruder, EdgeExtruder, LeftBorder, RightBorder, TopBorder, BottomBorder, EdgeWidth, EdgeHeight)
{
	// Select range of random numbers (and arc indexes) based on Truchet mode
	Min = MinForTruchetMode(TruchetMode);
	Max = MaxForTruchetMode(TruchetMode);
	ArcIndexes = RandomIntsInRange(Min, Max, CountX * CountY, RandomSeed);
	
	// Compute spacing in X and Y
	SpaceX = 1.5 * (HexRadius + Gap);
	SpaceY = (HexRadius + Gap) / 2 * sqrt(3);
	
	for (Y = [0 : 2 : CountY - 1])
	{
		for (X = [0 : CountX - 1])
		{
			OddColumn = (X % 2) == 1 ? 1 : 0;
				
			PointX = SpaceX * X;
			PointY = SpaceY * (OddColumn ? Y : Y + 1);
			
			translate([PointX, PointY, 0])
			{
				ArcIndex = ArcIndexes[Y * CountX + X];
				
				// Horrible hack to see if pattern 2 rotation is a good idea  (it is)
				if (ArcIndex == 2)
				{
					Rot = ((X * 2 * Y) % 6) * 60;	// This produces a very cool variation
					rotate([0, 0, Rot])
					{
						RenderHexagon(HEX_ALL, HexRadius, HexHeight, ArcHeight, ArcWidth, ArcIndex, TileExtruder, ArcExtruder, FillExtruder, EdgeExtruder, EdgeWidth, EdgeHeight);
					}
				}
				else
				// Production code
				{
					RenderHexagon(HEX_ALL, HexRadius, HexHeight, ArcHeight, ArcWidth, ArcIndex, TileExtruder, ArcExtruder, FillExtruder, EdgeExtruder, EdgeWidth, EdgeHeight);
				}
			}
			
			if (LeftBorder && (X == 0))
			{
				PointY = SpaceY * Y;
				PointX = SpaceX * (X - 1);
				
				translate([PointX, PointY, 0])
				{
					RenderHexagon(HEX_RIGHT, HexRadius, HexHeight, ArcHeight, ArcWidth, 0, TileExtruder, ArcExtruder, FillExtruder, EdgeExtruder, EdgeWidth, EdgeHeight);
				}
			}
			
			if (RightBorder && (X == (CountX - 1)))
			{
				PointY = SpaceY * Y;
				PointX = SpaceX * (X + 1);
				
				translate([PointX, PointY, 0])
				{
					RenderHexagon(HEX_LEFT, HexRadius, HexHeight, ArcHeight, ArcWidth, 0, TileExtruder, ArcExtruder, FillExtruder, EdgeExtruder, EdgeWidth, EdgeHeight);
				}					
			}
			
			if (TopBorder && (Y == (CountY - 2)) && OddColumn)
			{
				PointY = SpaceY * (Y + 2);
							
				translate([PointX, PointY, 0])
				{
					RenderHexagon(HEX_BOTTOM, HexRadius, HexHeight, ArcHeight, ArcWidth, 0, TileExtruder, ArcExtruder, FillExtruder, EdgeExtruder, EdgeWidth, EdgeHeight);
				}
			}
			
			if (BottomBorder && (Y == 0) && !OddColumn)
			{
				PointY = SpaceY * (Y - 1);
							
				translate([PointX, PointY, 0])
				{
					RenderHexagon(HEX_TOP, HexRadius, HexHeight, ArcHeight, ArcWidth, 0, TileExtruder, ArcExtruder, FillExtruder, EdgeExtruder, EdgeWidth, EdgeHeight);
				}
			}
		}
	}
}

main(_CountX, _CountY, _TruchetMode, _HexRadius, _HexHeight, _ArcHeight, _ArcWidth, _RandomSeed, _Gap, _TileExtruder, _ArcExtruder, _FillExtruder, _EdgeExtruder, _LeftBorder, _RightBorder, _TopBorder, _BottomBorder, _EdgeWidth, _EdgeHeight);
