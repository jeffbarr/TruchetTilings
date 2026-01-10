@ECHO OFF
REM
REM render_hexagons_truchet.bat
REM
REM For each of the parts (A-M) of the Truchet Hexagon mat pieces, render all 4 or 5 layers
REM
REM Run this 2 levels inside of Dropbox\3D Printing\My Models\FabricPrinting\STLs:
REM
REM 1 - Go to that directory and create a new directory within it named for the mat
REM
REM 2 - Enter that directory
REM
REM 3 - Create a params file in FabricPrinting (PARAM below) with a named param set (PMAT)
REM
REM 4 - Run this script and check output for errors
REM
REM 5 - Load each mat into PrusaSlicer (%OUTFILE%_%%M), keep as objects, slice, 
REM     save as GCODE
REM
REM This generates up to 65 files and over 1.3 GB of STL within minutes
REM
REM More info: https://github.com/jeffbarr/TruchetTilings/blob/main/Images/tiling_mats.png
REM  
REM
REM TODO:
REM	- Accept a single parameter that maps to mat5/6/7 ...
REM	- Add error checking
REM 

REM Path to OpenSCAD, latest nightly build since we need object()
set OSC="C:\Program Files\OpenSCAD (Nightly)\openscad.exe"

REM Extra arguments to OpenSCAD, enable all extensions including object()
set EXTRA=--enable all

REM File to render
set INFILE=..\..\hexagons_truchet.scad

REM Param file to use (created in OpenSCAD)
set PARAM=..\..\mat6.json

REM Settings in param file
SET PMAT=Mat6

REM Base name for output files
set OUTFILE=hexagons_truchet_mat6

echo %OSC%
echo %BASE%

for %%M in (A B C D E F G H I J K L M) do (
  echo MAT: %%M
  for %%E in (1 2 3 4 5) do (
    echo   EXT: %%E
    %OSC% %EXTRA% -D "_Mat=\"%%M\"" -D "_WhichExtruder=%%E" -p %PARAM% -P %PMAT% %INFILE% -o %OUTFILE%_%%M_%%E.stl
  )
)


