#!/bin/bash

if [ "clean" == "$1" ];
then
    rm *.gcode
    rm flatcam.shell
    exit 0
fi

if [ ! -f "kicad-env-config.sh" ];
then
    echo "Please run the following command and modify the vars inside the script."
    echo "cp kicad-env-config.sh.example kicad-env-config.sh"
    exit 1
fi

echo "Loading vars..."
. ./kicad-env-config.sh

if [ -z "$1" ];
then
    echo "Please provide a project name."
    echo "Usage: ./gerber2gcode.sh <project-name> <profile>"
    exit 2
fi

if [ -z "$2" ];
then
    echo "Please provide a project name. (Available: $(ls flatcam.shell.*.tmpl | tr " " "\n" | cut -d"." -f3 | tr "\n" " "))"
    echo "Usage: ./gerber2gcode.sh $1 <profile>"
    exit 3
fi

FCU=$KICAD_PROJECTS_HOME/$1/out/$1-F.Cu.gbr
DRL=$KICAD_PROJECTS_HOME/$1/out/$1.drl

echo "open_gerber $FCU -outname pcb" > flatcam.shell
echo "open_excellon $DRL -outname drl" >> flatcam.shell

cat flatcam.shell.$2.tmpl >> flatcam.shell

echo "write_gcode pcb_iso_cnc $(pwd)/pcb.gen.gcode" >> flatcam.shell
echo "write_gcode drl_cnc $(pwd)/drl.gen.gcode" >> flatcam.shell

echo "Close flatcam once it is finished"
echo "Running $FLATCAM"
$FLATCAM --shellfile=$(pwd)/flatcam.shell

# fix single files (slowstart)
cat slowstart.gcode.tmpl > pcb_slowstart.gen.gcode
cat pcb.gen.gcode >> pcb_slowstart.gen.gcode

cat slowstart.gcode.tmpl > drl_slowstart.gen.gcode
cat drl.gen.gcode >> drl_slowstart.gen.gcode

# join single files (slowstart)
cat drl_slowstart.gen.gcode > all.gen.gcode
cat pcb_slowstart.gen.gcode >> all.gen.gcode
