# Polytoria Welds Library

Allows for roblox-like destruction physics using hypergraphs!

[Step-by-step setup](#step-by-step-setup) is shown below, theres also an uncopylocked [example place](https://polytoria.com/places/95824).\
If you don't need destruction, please see the [Do You Need This](#do-you-need-this) section as it explains how to create the effect of welds without a library

![GIF showing a Polytoria character shooting rockets at a randomly colored blocky bridge. Chunks of the bridge are shot off and eventually the entire bridge falls into the void.](https://github.com/thecreare/polytoria-welds/blob/main/repo/demo.gif)

## Usage

The API to interact with these welds is not instance based.
Either copy the [example place](https://polytoria.com/places/95824) or follow the instructions below to get started

### Step-by-Step Setup


1. Download the [latest `release.lua` file](https://github.com/thecreare/polytoria-welds/releases/latest)
2. Add it to your Polytoria place as a **script**, not a module script.
3. Make sure the script runs before scripts that depend on it (this can be achieved by moving it to the first position in `ScriptService`)
4. Reference the script with `local Welder = game["ScriptService"]["WelderScript"]`, making sure that your script is in `ScriptService` and named `WelderScript`
5. Call methods on the script with `Welder.Call(method_name: string, ...args)`
6. Look at the [API](#api) section, the [`examples/`](https://github.com/thecreare/polytoria-welds/tree/main/examples) directory, or the [example place](https://polytoria.com/places/95824) for specific usage

*This is the way I've chosen to get around module scripts having independent environments. If anybody knows a cleaner way to do this, **please tell me!***

### API

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

`Welder.Call("DestroyAllAssemblies")`\
Clears every registered assembly, useful for resetting the map

### Disclaimer

I thew together the API quickly, there are likely unhandled edge cases. Please report bugs, I'm happy to receive to PRs.
The API i've exposed in `init.luau` should automatically handle edge cases with extra safety checks but this makes it slightly slower than the raw API. At some point in the future I may properly document and explain how the raw API can be used if anybody needs that tiny bit of extra performance.

## Do you need this?

If you just need to create welds without ever needing to remove/destroy them, you won't need this library. Polytoria has that by default. Unlike roblox, the positions and rotations of children are inherited from their parents (see the `LocalPosition` property). This can be used to create groups of parts that move as one by making them all children of a common parent part. This library's purpose is to extend that trick with a hypergraph so groups of welded parts can be split (ie, destruction)

### Indestructible welds without any library

1. Create an unanchored, invisible parent part
2. Add whatever parts you want as children of that parent
3. Anchor all of the children
4. Test the game and all of the children should behave as one connected physics object

## Development

This library is written in luau with multiple modules, this means it needs to be processed with darklua before it can be imported into Polytoria. The release workflow should automatically process new releases and upload them to the releases section. A local development environment can be set up by editing `dev_process.sh` to point to a Polytoria lua file and executing it. When Polytoria 2.0 releases this module's structure will likely be updated to support whatever package manager ends up being standard
