# Gomoku: An Example Game for the Dr Ecco Heuristic Problem Solving Website

This is a minimal example game that fulfils all the basic requirements of the *Heuristic Problem Solving* final project. 

Namely, this is:
1. An interactive strategy game, with
2. Thoroughly commented source code, which
3. Runs directly in the browser, 
4. Prompts for configuration of game parameters before starting the game,
5. Implements a multi-player mode and a single-player mode against a computer AI, and
6. Implements two difficulty levels of computer AI.

# Developing

Make sure you have [Elm](https://elm-lang.org/) and [`create-elm-app`](https://github.com/halfzebra/create-elm-app) installed. 

To run the development server:

```
elm-app start
```

To build the application, run the build script (make sure you have execution permissions):

```
./build.sh
```

# Directory Structure

Within the root directory of this project:
1. `elm.json` contains information used by Elm (e.g. dependencies). Don't modify this file directly. 
2. `build.sh` is the script used to build a production build ready for deployment to the Dr Ecco website. This replaces the build folder with a new build.  
3. The `src` directory contains all the actual game code. 
4. The `public` directory contains assets that are copied directly to the final production build. 
5. The `tests` directory contains tests for the Elm code (I haven't implemented any though). 
6. The `elm-stuff` directory (ignored by Git) contains Elm dependencies. Don't modify this folder directly. 
7. The `build` directory (ignored by Git) contains the production build produced by `build.sh`. **Don't try to make changes to files in this folder** as they will just be deleted when `build.sh` is rerun. Leave any changes to files in this folder up to `build.sh`.

Within the `src` folder, there are five Elm files in this project:
1. `src/Main.elm` is the entrypoint that handles delegating to the Settings and Game screen views. 
2. `src/Common.elm` contains basic utility types and functions shared by both `Settings.elm` and `Game.elm`.
3. `src/Settings.elm` contains the model, view and update for the Settings screen. 
4. `src/Game.elm` contains the model, view and update for the Gameplay screen (including all the game logic). 
5. `src/index.js` contains the JavaScript entrypoint for the live development server. This file is not used for the production build. If you modify this file, you **also** need to make sure that you make the same changes to `public/index.html` so that these changes will be reflected in the production build. 
6. `src/main.css` contains all the CSS styling. I recommend just keeping all your CSS styles in this one file and modify it as necessary. **If you add another CSS file, you need to add references to it in both `src/index.js` (for the live development server) and `public/index.html` (for the production build).**

Within the `public` folder, there are three essential static assets:
1. `public/index.html` contains the HTML entrypoint that is used by both the live development server and the production build. 
2. `public/index.md` is a Markdown file that gets converted to the information page for your game. The TOML frontmatter of this file must contain a `title` variable (your game name) as well as an `extra` section with a `team` variable (your team name) and a `thumbnail` variable (the name of the thumbnail image). 
3. `public/thumbnail.png` is a square image used as a thumbnail for your game. Your thumbnail image will be scaled to about 150px wide on the website, so don't make it too detailed. 

You are welcome to add other assets you need to access from your game (e.g. image files) into the `public` folder. They will be copied to the build root directory by the build script. 

# Making your Own Game

I suggest you use the [blank game template](https://github.com/wjmn/drecco-game-template) as the starting point for your own game, but you might find this helpful as a reference. The tricky thing with using a finished game like this as a template is that you won't be able to compile it if you just try to modify small bits of it - it's much easier to instead incrementally build up the functionality of your game from a blank template. 

# Deployment

If you're just developing a game, don't worry about this section. 

*Note for deployers to the Dr Ecco website*: for deployment, copy the `build` directory into the Dr Ecco website games folder under the relevant year, rename the `build` folder to the game name, then run `zola build` to regenerate the Dr Ecco website.