#!/bin/bash
# cd src
scripteditor_path='/run/user/1000/app/com.polytoria.launcher/Polytoria/Polytoria Creator/scripteditor'
watch='lune/ models/ src/ .darklua.json5'
inotifywait --recursive --monitor --format "%e %w%f" \
	--event modify,move,create,delete $watch \
| while read changed; do
    echo $changed
	lune run CompileModels
	darklua process src/client/init.luau "$scripteditor_path/client_6Y20QVQNP1MA5EFP.lua"
	darklua process src/server/init.luau "$scripteditor_path/server_Y4JCWRVDDHAOZBGJ.lua"
done
