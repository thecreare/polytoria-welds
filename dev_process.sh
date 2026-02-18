#!/bin/bash

scripteditor_path='/run/user/1000/app/com.polytoria.launcher/Polytoria/Polytoria Creator/scripteditor'
watch='src/ .darklua.json5'

inotifywait --recursive --monitor --format "%e %w%f" \
	--event modify,move,create,delete $watch \
| while read changed; do
    echo $changed
	darklua process src/init.luau "$scripteditor_path/ScriptInstance_Y5JHF2CSCTWVA2OA.lua"
done
