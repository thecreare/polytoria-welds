# Polytoria Welds Library

Allows for roblox-like destruction physics using hypergraphs!

![GIF showing a Polytoria character shooting rockets at a randomly colored blocky bridge. Chunks of the bridge are shot off and eventually the entire bridge falls into the void.](https://github.com/thecreare/polytoria-welds/blob/main/repo/demo.gif)

I thew together the API quickly, there are likely unhandled edge cases. Please report bugs, I'm happy to receive to PRs.
The API i've exposed in `init.luau` automatically handles edge cases and does extra safety checks which makes it slightly slower than the raw API. At some point in the future I may properly document and explain how the raw API can be used if anybody needs that tiny bit of extra performance.

## Installation

Download the [latest `release.lua` module](https://github.com/thecreare/polytoria-welds/releases/latest) and add it to your Polytoria place as a **script**, not a module script. Make sure the script runs before scripts that depend on it. Calling the module's methods is done with `.Call`. The module can be referenced like so: `local Welder = game["ScriptService"]["WelderScript"]`.
*This is the way I've chosen to get around module scripts having independent environments. If anybody knows a cleaner way to do this, **please tell me!***

## Usage

The API to interact with these welds is not instance based, please see `examples/` for implementations using some of the following functions.

`Welder.Call("CreateWeld", part_a: Part, part_b: Part)`\
Safely creates a weld between two parts, handles parts being initialized, unutilized, and part of separate graphs

`Welder.Call("RemoveWeld", part_a: Part, part_b: Part)`\
Removes a weld between two parts, does noting if the parts are unutilized or otherwise not welded

`Welder.Call("ClearWelds", part: Part)`\
Removes all the welds of a part, fully detaching it

`Welder.Call("ClearWeldsBulk", ...: Part)`\
Same as `ClearWelds` except it operates on a table of parts.
This will be much faster when clearing welds on many individual parts in the same assembly.
*NOTE: Polytoria is jank and so this needs to be `:Call`-ed which doesn't support tables so it uses a vararg (...) which may make this really slow. I am yet to test*

`Welder.Call("MakeWelds", part: Part, epsilon: number?, ...: DynamicInstance)`\
Creates welds to nearby parts using Environment:OverlapBox. Optionally an ignore list & epsilon can be supplied.
*NOTE: Polytoria is jank and so this needs to be `:Call`-ed which doesn't support tables so it uses a vararg (...) for the ignore list which may make this really slow. I am yet to test*

`Welder.Call("DestroyPart", part: Part)`\
Wrapper for `part:Destroy()`, handles updating of any linked assemblies.
This should **ALWAYS** be used when dealing with parts that may be part of an assembly.

`Welder.Call("DestroyPartsBulk", ...: Part)`\
Same as `DestroyPart` except it operates on a table of parts.
Similar to `ClearWeldsBulk`, this will be much faster when clearing welds on many individual parts in the same assembly.
*NOTE: Polytoria is jank and so this needs to be `:Call`-ed which doesn't support tables so it uses a vararg (...) which may make this really slow. I am yet to test*

`Welder.Call("PrintDebugInfo")`\
Prints out some basic information to the console

`Welder.Call("SetDebugEnabled", enabled: boolean)`\
When enabled, all parts will be colored based on the assembly they are a part of

## Development

This library is written in luau with multiple modules, this means it needs to be processed with darklua before it can be imported into Polytoria. The release workflow should automatically process new releases and upload them to the releases section. A local development environment can be set up by editing `dev_process.sh` to point to a Polytoria lua file and executing it. When Polytoria 2.0 releases this module's structure will likely be updated to support whatever package manager ends up being standard
