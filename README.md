# Blik
Easy file organisation for Mac

## Organization

### Projects

The top level unit of organization, usually coressponding to a particular product or brief from a client.
Alternatively, you could have a single project per client.

### Master folders

The primary folders of your project. Adding these lets you quickly open them. It also gives Blik access to all the files inside.

### Collections

Groups of files and folder, grouped by their role.

### Highlights

The most important files and folders from within collections. Have been wanting to come up with a simpler model here, and integrate live Spotlight searches.

## User experience

The goal for Blik’s organization model was to have something that mapped to how people think. But not necessarily mirroring their folder structure. Files often have to live in a specific place, saying some in a shared Dropbox, and others in a Git repo. Blik allows these disparate files to be organized together.

A future goal is to make setting up a project ever quicker than it is now. Just point it at a folder, and the most important files & folders are detected and organized for you.

I have thought about integrating Tags for a while, but haven’t landed on the right UI yet. I want to balance simplicity with useful functionality.

## Code

The code was originally all Objective-C. I have since been adding new code in Swift, currently Swift 3.1.
This leads to architecting using light-weight structs and enums instead of broader NSObject subclasses. This is still in transition.

### Dependencies

- [Mantle 1.x](https://github.com/Mantle/Mantle): Have not updated to Mantle’s latest version, as am replacing this with something Swiftier.
- [Syrup](https://github.com/BurntCaramel/Syrup): for asynchronous data processing
- [BurntCocoaUI](https://github.com/BurntCaramel/BurntCocoaUI): used for Swiftier menus
