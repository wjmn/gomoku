module Game exposing (..)

{-| This file handles all the game logic and provides the Gameplay interface to the Main application.alias.

You will probably need to modify almost all of the code in this file for your game.
(the majority of this file is game logic for Gomoku, although it might be helpful for you to
see how the game logic is integrated into the core parts needed for Elm's architecture).

The core parts you need to implement are:

1.  A type for your Game model
2.  An initialisation function that takes a Settings record and returns a Game record
3.  A Msg type that represents all the possible messages that can be sent from the interface to the game logic
4.  An update function that takes a Msg and a Game and returns a new Game
5.  A view function that takes a Game and returns Html Msg (the interface for the game)

You'll probably want to implement a lot of helper functions to make the above easier.

-}

import Array exposing (Array)
import Common exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List exposing (..)
import Maybe.Extra exposing (combine)
import Process
import Random
import Random.List
import Settings exposing (PlayMode(..), Settings)
import Task
import Tuple exposing (first)



--------------------------------------------------------------------------------
-- GAME MODEL
--------------------------------------------------------------------------------


{-| A record type which contains all of the game state.

This needs to be sufficiently detailed to represent the entire game state, i.e.
if you save this record, turn off your computer, and then reload this record,
you should be able to pick up the game exactly where you left off.

We also need some metadata including the settings used to initialise
the game, the status (whether it's still going or completed), and
whose turn it currently is.

You might also like to pre-calculate some data and store it here
if you will use it a lot.

-}
type alias Game =
    { settings : Settings
    , status : Status
    , turn : Player
    , board : Array Cell
    }


{-| A cell on the board can be empty or occupied by a player
-}
type Cell
    = Empty
    | OccupiedBy Player


{-| Create the initial game data given the settings.

In Gomoku, an initial game starts with Player1's turn and an empty board.

Need to check here on whether playing solo or not - if the first turn is the
computer's turn, then we also need to generate the first move.

-}
init : Settings -> ( Game, Cmd Msg )
init settings =
    let
        initialSettings =
            { settings = settings
            , status = Playing
            , turn = Player1
            , board = Array.repeat (settings.boardSize * settings.boardSize) Empty
            }
    in
    case settings.playMode of
        PlayHumanVsHuman ->
            ( initialSettings, Cmd.none )

        PlayComputerVsMe ->
            ( initialSettings, Task.perform (\_ -> PauseThenMakeComputerMove) (Process.sleep 250) )

        PlayMeVsComputer ->
            ( initialSettings, Cmd.none )



--------------------------------------------------------------------------------
-- GAME LOGIC
--
-- What moves can you make in Gomoku? Well there's only one (put a stone on an
-- empty cell) That makes the move representation very simple.
--
-- I've defined it as an enum though, so if you want you can add more and still
-- use the same basic game logic:
--
-- 1. Apply the move to the game state to return a new game state
-- 2. Check if the game completes or if it continues
--
-- This repeats, but it repeats in the Elm Architecture update loop, not here.
--
-- So don't worry about any `while` loops - just focus on the game logic for a single
-- move.
--------------------------------------------------------------------------------


{-| The possible moves that a player can make.
-}
type Move
    = MarkEmptyCell Coord


{-| Apply a move to a game state, returning a new game state.

Because Gomoku is an alternating game, we know which player made the move based
on whose turn it is (which is stored in the game state).

However, if your game is simultaneous, then you will need to add data on which
player made the move to either this function, or to the move payload.

-}
applyMove : Game -> Move -> Game
applyMove game move =
    case move of
        MarkEmptyCell coord ->
            let
                newBoard =
                    setCell (coordToIndex game.settings.boardSize coord) game.turn game.board
            in
            if playerWonWithCoord game.settings.boardSize coord newBoard then
                { game | board = newBoard, status = Complete (Winner game.turn) }

            else if boardIsFull newBoard then
                { game | board = newBoard, status = Complete Draw }

            else
                { game | board = newBoard, turn = opponent game.turn }



--------------------------------------------------------------------------------
-- INTERFACE LOGIC
--
-- This section deals with how to map the interface to the game logic.
--
-- Msg contains messages that can be sent from the game interface. You should then
-- choose how to handle them in terms of game logic.
--
-- This also sets scaffolding for the computer players - when a computer player
-- makes a move, they generate a message (ReceivedComputerMove) which is then handled
-- just like a player interacting with the interface.
--------------------------------------------------------------------------------


{-| An enumeration of all messages that can be sent from the interface to the game
-}
type Msg
    = ClickedSquare Int
    | PauseThenMakeComputerMove
    | ReceivedComputerMove Move
    | NoOp


{-| A convenience function to pipe a command into a (Game, Cmd Msg) tuple.
-}
withCmd : Cmd Msg -> Game -> ( Game, Cmd Msg )
withCmd cmd game =
    ( game, cmd )


{-| The main update function for the game, which takes an interface message and returns
a new game state as well as any additional commands to be run.
-}
update : Msg -> Game -> ( Game, Cmd Msg )
update msg game =
    case msg of
        -- This interface message (when the user clicks a square) simply maps to the MarkEmptyCell game move.
        ClickedSquare index ->
            let
                nextState =
                    MarkEmptyCell (indexToCoord game.settings.boardSize index)
                        |> applyMove game
            in
            case nextState.status of
                Playing ->
                    case game.settings.playMode of
                        PlayHumanVsHuman ->
                            nextState
                                |> withCmd Cmd.none

                        -- If the game is continuing and it's the computer's turn, then we need to generate a move.
                        -- To make it more "human-like", pause for 250 milliseconds before generating a move.
                        _ ->
                            nextState
                                |> withCmd (Task.perform (\_ -> PauseThenMakeComputerMove) (Process.sleep 250))

                Complete _ ->
                    nextState
                        |> withCmd Cmd.none

        -- This interface message is generated by the computer player when it's time to make a move.
        PauseThenMakeComputerMove ->
            case game.settings.computerDifficulty of
                -- Example of using randomness to generate a move (an "Easy" player)
                -- See the makeComputerMoveEasy function
                Settings.Easy ->
                    game |> withCmd (makeComputerMoveEasy game)

                -- Example of deterministically generating a move (a "Hard" player)
                -- See the makeComputerMoveHard function
                Settings.Hard ->
                    game |> withCmd (makeComputerMoveHard game)

        -- Once the computer makes a move, we handle it just like a player move.
        -- Howeever it looks a bit simpler because we know the next move will be a player move.
        ReceivedComputerMove move ->
            applyMove game move
                |> withCmd Cmd.none

        -- A NoOp message is used to ignore messages (it doesn't change the game state).
        NoOp ->
            game
                |> withCmd Cmd.none



--------------------------------------------------------------------------------
-- GAME VIEW FUNCTION
-- This will look very big because translating the game to HTML can be verbose.
-- But it's not complicated, it's just a lot of code.
--------------------------------------------------------------------------------


{-| The main view function that gets called from the Main application.

Essentially, takes a game and projects it into a HTML interface where Messages
can be sent from.

-}
view : Game -> Html Msg
view game =
    div [ id "game-screen-container" ]
        [ div [ id "game-header" ] [ viewStatus game ]
        , div [ id "game-main" ] [ viewBoard game ]
        ]


{-| View the Gomoku status at the top of the game board
-}
viewStatus : Game -> Html Msg
viewStatus ({ settings } as game) =
    let
        colour =
            case game.status of
                Complete (Winner Player1) ->
                    settings.player1Colour |> Settings.colourToString

                Complete (Winner Player2) ->
                    settings.player2Colour |> Settings.colourToString

                Complete Draw ->
                    "black"

                Playing ->
                    currentColour game |> Settings.colourToString

        ( statusClass, statusText ) =
            case game.status of
                Playing ->
                    case settings.playMode of
                        PlayHumanVsHuman ->
                            ( "status-playing", currentName game ++ "'s turn." )

                        PlayComputerVsMe ->
                            case game.turn of
                                Player1 ->
                                    ( "status-thinking", currentName game ++ " is thinking..." )

                                Player2 ->
                                    ( "status-playing", "Your turn." )

                        PlayMeVsComputer ->
                            case game.turn of
                                Player1 ->
                                    ( "status-playing", "Your turn." )

                                Player2 ->
                                    ( "status-thinking", currentName game ++ " is thinking..." )

                Complete (Winner Player1) ->
                    case settings.playMode of
                        PlayHumanVsHuman ->
                            ( "status-won", currentName game ++ " WINS!" )

                        PlayComputerVsMe ->
                            ( "status-lost", "You lost..." )

                        PlayMeVsComputer ->
                            ( "status-won", "You win!" )

                Complete (Winner Player2) ->
                    case settings.playMode of
                        PlayHumanVsHuman ->
                            ( "status-won", currentName game ++ " WINS!" )

                        PlayComputerVsMe ->
                            ( "status-won", "You win!" )

                        PlayMeVsComputer ->
                            ( "status-lost", "You lost...)" )

                Complete Draw ->
                    ( "status-draw", "It's a draw." )
    in
    div [ id "game-status", class statusClass, class colour ]
        [ div [ class ("game-status-text " ++ colour) ] [ text statusText ]
        , div [ class "firework-container", classList [ ( "show", statusClass == "status-won" ) ] ]
            [ div [ class "firework" ] []
            , div [ class "firework" ] []
            , div [ class "firework" ] []
            ]
        , div
            [ class "flash"
            , class statusClass
            , classList [ ( "show", statusClass == "status-won" || statusClass == "status-lost" || statusClass == "status-draw" ) ]
            ]
            []
        ]


{-| View the actual Gomoku game board
-}
viewBoard : Game -> Html Msg
viewBoard game =
    let
        boardSize =
            game.settings.boardSize

        -- Convert a single cell to HTML
        -- There's quite a bit more going here as we need to handle the
        -- cell rendering quite differently depending on the current game state
        -- (and also we want to make sure the cell only sends messages if it's empty
        -- and the game is actually continuing and it's our turn).
        cellView index cell =
            let
                onClickEvent =
                    if cell == Empty then
                        case game.status of
                            Playing ->
                                case game.settings.playMode of
                                    PlayHumanVsHuman ->
                                        ClickedSquare index

                                    PlayComputerVsMe ->
                                        case game.turn of
                                            Player1 ->
                                                NoOp

                                            Player2 ->
                                                ClickedSquare index

                                    PlayMeVsComputer ->
                                        case game.turn of
                                            Player1 ->
                                                ClickedSquare index

                                            Player2 ->
                                                NoOp

                            Complete _ ->
                                NoOp

                    else
                        NoOp

                cellColour =
                    case cell of
                        Empty ->
                            "empty"

                        OccupiedBy Player1 ->
                            game.settings.player1Colour |> Settings.colourToString

                        OccupiedBy Player2 ->
                            game.settings.player2Colour |> Settings.colourToString
            in
            div
                [ class "game-cell-container"
                , onClick onClickEvent
                ]
                [ div [ class "game-cell", class cellColour ]
                    [ div [ class "game-cell-line vertical" ] []
                    , div [ class "game-cell-line horizontal" ] []
                    , div [ class "game-cell-marker", class cellColour ] []
                    ]
                ]
    in
    div
        [ id "game-board-container"
        ]
        [ div
            [ id "game-board"
            , Html.Attributes.style "grid-template-columns" ("repeat(" ++ String.fromInt boardSize ++ ", 1fr)")
            , Html.Attributes.style "grid-template-rows" ("repeat(" ++ String.fromInt boardSize ++ ", 1fr)")
            ]
            (List.indexedMap cellView (Array.toList game.board))
        ]



--------------------------------------------------------------------------------
-- COMPUTER: EASY PLAYER
--------------------------------------------------------------------------------


{-| Logic for an "easy" computer player.

This is a simple player which sorts the possible moves by
a basic score (based on the number of neighbours next to the move)
and then randomly picks one out of the top 5.

Randomness is a little more tricky in Elm than other languages as Elm is pure,
so this might be useful as a reference of how you might use Randomness in your
computer AI players. Essentially any random events get wrapped in a
Random type that you need to map/andThen under (ala Haskell monads).

Your computer player function takes a game and returns a move, which you
then wrap in ReceivedComputerMove to create a Cmd Msg.

-}
makeComputerMoveEasy : Game -> Cmd Msg
makeComputerMoveEasy game =
    let
        emptyCells =
            game.board
                |> Array.indexedMap (\index cell -> ( index, cell ))
                |> Array.filter (\( _, cell ) -> cell == Empty)

        score ( index, cell ) =
            let
                coord =
                    indexToCoord game.settings.boardSize index

                halfBoard =
                    toFloat game.settings.boardSize / 2.0

                centralTendency =
                    1.0 - (abs (halfBoard - toFloat coord.x) + abs (halfBoard - toFloat coord.y)) / toFloat game.settings.boardSize

                newBoard =
                    setCell (coordToIndex game.settings.boardSize coord) game.turn game.board

                newBoardOpponent =
                    setCell (coordToIndex game.settings.boardSize coord) (opponent game.turn) game.board

                numNextTo =
                    [ ( -1, -1 ), ( -1, 0 ), ( -1, 1 ), ( 0, -1 ), ( 0, 1 ), ( 1, -1 ), ( 1, 0 ), ( 1, 1 ) ]
                        |> List.map (\( dx, dy ) -> moveCoord coord dx dy)
                        |> List.filter (\c -> inBounds game.settings.boardSize c)
                        |> List.map (\c -> Array.get (coordToIndex game.settings.boardSize c) newBoard |> Maybe.withDefault Empty)
                        |> List.filter (\c -> c == OccupiedBy game.turn)
                        |> List.length
            in
            --- If you can win with a move, then score it extremely highly
            if playerWonWithCoord game.settings.boardSize coord newBoard then
                99999999.99999
                -- If the opponent will win with this move, then score it quite highly

            else if playerWonWithCoord game.settings.boardSize coord newBoardOpponent then
                88888888.88888
                -- Otherwise score it based on how many neighbours it has and how close to the center it is

            else
                toFloat numNextTo + centralTendency

        allScores =
            emptyCells
                |> Array.map (\c -> ( c, score c ))

        maxScore =
            allScores
                |> Array.map Tuple.second
                |> Array.toList
                |> List.maximum
                |> Maybe.withDefault 0
    in
    -- If there's a move that causes you or opponent to win, then definitely choose it
    if maxScore > 100000 then
        allScores
            |> Array.toList
            |> List.sortBy Tuple.second
            |> List.reverse
            |> List.head
            |> Maybe.map (\( index, _ ) -> index)
            |> Maybe.withDefault ( 0, Empty )
            |> first
            |> indexToCoord game.settings.boardSize
            |> MarkEmptyCell
            |> Random.constant
            |> Random.generate ReceivedComputerMove

    else
        -- Otherwise, randomly choose one of the top 5 scoring moves
        allScores
            |> Array.toList
            |> List.sortBy Tuple.second
            |> List.reverse
            |> List.take 5
            |> List.map first
            |> Random.List.choose
            |> Random.map
                (\maybeIndex ->
                    maybeIndex
                        |> first
                        |> Maybe.withDefault ( 0, Empty )
                        |> first
                        |> indexToCoord game.settings.boardSize
                        |> MarkEmptyCell
                )
            |> Random.generate ReceivedComputerMove



--------------------------------------------------------------------------------
-- COMPUTER: HARD PLAYER
--------------------------------------------------------------------------------


{-| Very similar to the easy player.

This function is deterministic however, so the way it is returned
is slightly different (wrap in Task.perform).

This player is slightly better than the Easy player, and will score
cells based on the size of the largest row of stones it will make
for you or your opponent. It's not that challenging to beat, however.

-}
makeComputerMoveHard : Game -> Cmd Msg
makeComputerMoveHard game =
    let
        emptyCells =
            game.board
                |> Array.indexedMap (\index cell -> ( index, cell ))
                |> Array.filter (\( _, cell ) -> cell == Empty)

        score ( index, cell ) =
            let
                coord =
                    indexToCoord game.settings.boardSize index

                halfBoard =
                    toFloat game.settings.boardSize / 2.0

                centralTendency =
                    1.0 - (abs (halfBoard - toFloat coord.x) + abs (halfBoard - toFloat coord.y)) / toFloat game.settings.boardSize

                allFives =
                    allFivesWithCoord game.settings.boardSize coord

                newBoard =
                    setCell (coordToIndex game.settings.boardSize coord) game.turn game.board

                myMostRow =
                    mostInARow game.turn game.settings.boardSize newBoard allFives

                newBoardOpponent =
                    setCell (coordToIndex game.settings.boardSize coord) (opponent game.turn) game.board

                oppMostRow =
                    mostInARow (opponent game.turn) game.settings.boardSize newBoardOpponent allFives

                numNextTo =
                    [ ( -1, -1 ), ( -1, 0 ), ( -1, 1 ), ( 0, -1 ), ( 0, 1 ), ( 1, -1 ), ( 1, 0 ), ( 1, 1 ) ]
                        |> List.map (\( dx, dy ) -> moveCoord coord dx dy)
                        |> List.filter (\c -> inBounds game.settings.boardSize c)
                        |> List.map (\c -> Array.get (coordToIndex game.settings.boardSize c) newBoard |> Maybe.withDefault Empty)
                        |> List.filter (\c -> c == OccupiedBy game.turn)
                        |> List.length
            in
            if playerWonWithCoord game.settings.boardSize coord newBoard then
                99999999.99999

            else if playerWonWithCoord game.settings.boardSize coord newBoardOpponent then
                88888888.88888

            else
                toFloat numNextTo + centralTendency + toFloat myMostRow * 100.0 + toFloat oppMostRow * 100.0

        heuristicMove =
            emptyCells
                |> Array.toList
                |> List.sortBy score
                |> List.reverse
                |> List.head
                |> Maybe.withDefault ( 0, Empty )
                |> first
                |> indexToCoord game.settings.boardSize
                |> MarkEmptyCell
    in
    Task.perform ReceivedComputerMove (Task.succeed heuristicMove)



--------------------------------------------------------------------------------
-- GAME HELPER FUNCTIONS
-- Helper functions to implement the game logic.
-- You probably won't need any of these, as they're specific to this
-- implementation of Gomoku.
--------------------------------------------------------------------------------


{-| A convenience function for piping to set a cell on the board.
-}
setCell : Int -> Player -> Array Cell -> Array Cell
setCell index player board =
    Array.set index (OccupiedBy player) board


{-| A convenient piece of data to create a list of all possible
offsets of five numbers in a row containing 0.
-}
fiveWindows : List (List Int)
fiveWindows =
    [ [ -4, -3, -2, -1, 0 ]
    , [ -3, -2, -1, 0, 1 ]
    , [ -2, -1, 0, 1, 2 ]
    , [ -1, 0, 1, 2, 3 ]
    , [ 0, 1, 2, 3, 4 ]
    ]


{-| Returns a list of all five-in-a-rows horizontally containing a coord
-}
rowOfFivesWithCoord : Int -> Coord -> List (List Coord)
rowOfFivesWithCoord boardSize c =
    fiveWindows
        |> List.map (\dxs -> List.map (\dx -> moveCoord c dx 0) dxs)
        |> List.filter (\coords -> List.all (inBounds boardSize) coords)


{-| Returns a list of all five-in-a-rows vertically containing a coord
-}
colOfFivesWithCoord : Int -> Coord -> List (List Coord)
colOfFivesWithCoord boardSize c =
    fiveWindows
        |> List.map (\dys -> List.map (\dy -> moveCoord c 0 dy) dys)
        |> List.filter (\coords -> List.all (inBounds boardSize) coords)


{-| Returns a list of all five-in-a-rows diagonally containing a coord
-}
diagsWithCoord : Int -> Coord -> List (List Coord)
diagsWithCoord boardSize c =
    let
        diag =
            fiveWindows
                |> List.map (\ds -> List.map (\d -> moveCoord c d d) ds)

        diagMirrored =
            fiveWindows
                |> List.map (\ds -> List.map (\d -> moveCoord c d -d) ds)
    in
    List.append diag diagMirrored
        |> List.filter (\coords -> List.all (inBounds boardSize) coords)


{-| Returns a list of all five-in-a-rows (any direction) containing a coord
-}
allFivesWithCoord : Int -> Coord -> List (List Coord)
allFivesWithCoord boardSize c =
    List.concat
        [ rowOfFivesWithCoord boardSize c
        , colOfFivesWithCoord boardSize c
        , diagsWithCoord boardSize c
        ]


{-| Returns True if all the cells in a list of coords are occupied by the same player -
-}
isWinningFive : Int -> Array Cell -> List Coord -> Bool
isWinningFive boardSize board coords =
    coords
        |> List.map (\coord -> Array.get (coordToIndex boardSize coord) board)
        |> combine
        |> Maybe.map (\cells -> List.all ((==) (OccupiedBy Player1)) cells || List.all ((==) (OccupiedBy Player2)) cells)
        |> Maybe.withDefault False


{-| Helper: take from a list while predicate is true
-}
takeWhile : (a -> Bool) -> List a -> List a
takeWhile predicate list =
    case list of
        [] ->
            []

        x :: xs ->
            if predicate x then
                x :: takeWhile predicate xs

            else
                []


{-| Helper: drop from a list while predicate is true
-}
dropWhile : (a -> Bool) -> List a -> List a
dropWhile predicate list =
    case list of
        [] ->
            []

        x :: xs ->
            if predicate x then
                dropWhile predicate xs

            else
                list


{-| Return the maximum number of cells occupied by a player in a row in a collection of lists of coords in a row
-}
mostInARow : Player -> Int -> Array Cell -> List (List Coord) -> Int
mostInARow player boardSize board fives =
    fives
        |> List.map
            (\five ->
                five
                    |> List.map (\coord -> Array.get (coordToIndex boardSize coord) board |> Maybe.withDefault Empty)
                    |> dropWhile ((/=) (OccupiedBy player))
                    |> takeWhile ((==) (OccupiedBy player))
                    |> List.length
            )
        |> List.maximum
        |> Maybe.withDefault 0


{-| Returns True if a player has won with their move in a given coordinate.
-}
playerWonWithCoord : Int -> Coord -> Array Cell -> Bool
playerWonWithCoord boardSize coord newBoard =
    allFivesWithCoord boardSize coord
        |> List.any (isWinningFive boardSize newBoard)


{-| Returns True if the board is full
-}
boardIsFull : Array Cell -> Bool
boardIsFull board =
    board
        |> Array.toList
        |> List.all (\cell -> cell /= Empty)


{-| Returns the colour of the current player
-}
currentColour : Game -> Settings.SimpleColour
currentColour game =
    case game.turn of
        Player1 ->
            game.settings.player1Colour

        Player2 ->
            game.settings.player2Colour


{-| Returns the name of the current player
-}
currentName : Game -> String
currentName game =
    case game.turn of
        Player1 ->
            game.settings.player1Name

        Player2 ->
            game.settings.player2Name
