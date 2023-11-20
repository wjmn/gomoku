module Common exposing (..)

{-| This module contains code shared in Settings, Main and Game.

It's a good place to store the really basic types and functions.

Importantly, if you have a type/function that's used in both Settings.elm and Game.elm,
I strongly suggest putting it here (to avoid circular dependencies).

I also think that these types and functions will be generally useful for
you, even if your game isn't Gomoku.

-}

--------------------------------------------------------------------------------
-- TYPES
--------------------------------------------------------------------------------


{-| Basic type representation for a two player game.
-}
type Player
    = Player1
    | Player2


{-| The game either ends up with a winner or as a draw.
-}
type Outcome
    = Winner Player
    | Draw


{-| A game is either in progress of complete.
-}
type Status
    = Playing
    | Complete Outcome


{-| A type corresponding to an integer coordinate on a board.
-}
type alias Coord =
    { x : Int
    , y : Int
    }



--------------------------------------------------------------------------------
-- CONVENIENCE FUNCTIONS
--------------------------------------------------------------------------------


{-| A convenience function for the opposite player.
-}
opponent : Player -> Player
opponent player =
    case player of
        Player1 ->
            Player2

        Player2 ->
            Player1


{-| A helper function to return the coordinates of a cell given the boardSize and its index in a flattened array.
-}
indexToCoord : Int -> Int -> Coord
indexToCoord boardSize index =
    { y = index // boardSize, x = modBy boardSize index }


{-| A helper function to return the index of a cell in a flattened array given the boardSize and its coordinates.
-}
coordToIndex : Int -> Coord -> Int
coordToIndex boardSize { x, y } =
    y * boardSize + x


{-| Checks if a coordinate is on a board, given a board size.
-}
inBounds : Int -> Coord -> Bool
inBounds boardSize coord =
    coord.x >= 0 && coord.x < boardSize && coord.y >= 0 && coord.y < boardSize


{-| Adds two coords.
-}
addCoord : Coord -> Coord -> Coord
addCoord a b =
    { x = a.x + b.x, y = a.y + b.y }


{-| Adds a coord and an x and y value (for convenience).
-}
moveCoord : Coord -> Int -> Int -> Coord
moveCoord coord x y =
    { x = coord.x + x, y = coord.y + y }
