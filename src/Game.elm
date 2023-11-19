module Game exposing (..)

import Array exposing (Array)
import Common exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List exposing (..)
import Maybe.Extra exposing (combine)
import Random
import Random.List
import Settings exposing (PlayMode(..), Settings)
import Task
import Tuple exposing (first)
import Process



--------------------------------------------------------------------------------
-- GAME MODEL
--------------------------------------------------------------------------------


{-| A record containing all of the game state.
In TicTacToe, the main data needed is the board (an array of cells).
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


{-| Create the initial game data given the settings.
In TicTacToe, An initial game starts with Player1's turn and an empty board.
Need to check here on whether playing solo or not - if the first turn is the
computer's turn, then also need to generate the first move.
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
            (initialSettings, Task.perform (\_ -> PauseThenMakeComputerMove) (Process.sleep 250))

        PlayMeVsComputer ->
            ( initialSettings, Cmd.none )


{-| A cell on the board can be empty or occupied by a player
-}
type Cell
    = Empty
    | OccupiedBy Player



--------------------------------------------------------------------------------
-- GAME LOGIC
--
-- What moves can you make in TicTacToe? Well there's only one (you can mark an
-- empty cell) That makes the move representation very simple.
--
-- I've defined it as an enum though, so if you want you can add more and still
-- use the same basic game logic:
-- 1. Apply the move to the game state to return a new game state
-- 2. Check if the game completes or if it continues
-- This repeats, but it repeats in the Elm Architecture update loop, not here.
-- So don't worry about any while loops - just focus on the game logic for a single
-- move.
--------------------------------------------------------------------------------


{-| The possible moves that a player can make.
-}
type Move
    = MarkEmptyCell Coord


{-| Apply a move to a game state, returning a new game state.
Because TicTacToe is an alternating game, we know which player made the move.
If your game is simultaneous, then you will need to add which player made the
move to either this function, or to the move payload/data.
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
-- This section deals with how to map the interface to the game logic.
-- Msg contains messages that can be sent from the game interface. You should then
-- choose how to handle them in terms of game logic.
-- This also sets scaffolding for the computer players - when a computer player
-- makes a move, they generate a message (ReceivedComputerMove) which is then handled
-- just like a player interacting with the interface.
--------------------------------------------------------------------------------


type Msg
    = ClickedSquare Int
    | PauseThenMakeComputerMove
    | ReceivedComputerMove Move
    | NoOp


withCmd : Cmd Msg -> Game -> ( Game, Cmd Msg )
withCmd cmd game =
    ( game, cmd )


update : Msg -> Game -> ( Game, Cmd Msg )
update msg game =
    case msg of
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

                        _ ->
                            nextState 
                            |> withCmd (Task.perform (\_ -> PauseThenMakeComputerMove) (Process.sleep 250))

                Complete _ ->
                    nextState
                        |> withCmd Cmd.none

        PauseThenMakeComputerMove ->
            case game.settings.computerDifficulty of 
                -- Example of using randomness to generate a move
                Settings.Easy ->
                    game |> withCmd (makeComputerMoveEasy game)

                -- Example of deterministically generating a move
                Settings.Hard ->
                    game |> withCmd (makeComputerMoveHard game)

        ReceivedComputerMove move -> 
            applyMove game move
                |> withCmd Cmd.none

        NoOp ->
            game
                |> withCmd Cmd.none



--------------------------------------------------------------------------------
-- GAME VIEW FUNCTION
-- This will look very big because translating the game to HTML can be verbose.
-- But it's not complicated, it's just a lot of code.
--------------------------------------------------------------------------------


view : Game -> Html Msg
view game =
    div [ id "game-screen-container" ]
        [ div [ id "game-header" ] [ viewStatus game ]
        , div [ id "game-main" ] [ viewBoard game ]
        ]


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

        (statusClass, statusText) =
            case game.status of
                Playing ->
                    case settings.playMode of
                        PlayHumanVsHuman ->
                            ("status-playing", currentName game ++ "'s turn.")

                        PlayComputerVsMe ->
                            case game.turn of
                                Player1 ->
                                    ("status-thinking", currentName game ++ " is thinking...")

                                Player2 ->
                                    ("status-playing", "Your turn.")

                        PlayMeVsComputer ->
                            case game.turn of
                                Player1 ->
                                    ("status-playing", "Your turn.")

                                Player2 ->
                                    ("status-thinking", currentName game ++ " is thinking...")

                Complete (Winner Player1) ->
                    case settings.playMode of
                        PlayHumanVsHuman ->
                            ("status-won", currentName game ++ " WINS!")

                        PlayComputerVsMe ->
                            ("status-lost", "You lost...")

                        PlayMeVsComputer ->
                            ("status-won", "You win!")

                Complete (Winner Player2) ->
                    case settings.playMode of
                        PlayHumanVsHuman ->
                            ("status-won", currentName game ++ " WINS!")

                        PlayComputerVsMe ->
                            ("status-won", "You win!")

                        PlayMeVsComputer ->
                            ("status-lost", "You lost...)")

                Complete Draw ->
                    ("status-draw", "It's a draw.")
    in
    div [ id "game-status", class statusClass, class colour ]
        [ div [ class ("game-status-text " ++ colour) ] [ text statusText ]
        , div [ class "firework-container", classList [("show", statusClass == "status-won")]] 
            [div [class "firework"] []
            , div [class "firework"] []
            , div [class "firework"] []
            ] 
        , div [class "flash", class statusClass, classList [("show", statusClass == "status-won" || statusClass == "status-lost" || statusClass == "status-draw")]] [] ]

viewBoard : Game -> Html Msg
viewBoard game =
    let
        boardSize =
            game.settings.boardSize

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
            if playerWonWithCoord game.settings.boardSize coord newBoard then
                99999999.99999

            else if playerWonWithCoord game.settings.boardSize coord newBoardOpponent then
                88888888.88888

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
--------------------------------------------------------------------------------


{-| A convenience function for piping to set a cell on the board.
-}
setCell : Int -> Player -> Array Cell -> Array Cell
setCell index player board =
    Array.set index (OccupiedBy player) board


fiveWindows : List (List Int)
fiveWindows =
    [ [ -4, -3, -2, -1, 0 ]
    , [ -3, -2, -1, 0, 1 ]
    , [ -2, -1, 0, 1, 2 ]
    , [ -1, 0, 1, 2, 3 ]
    , [ 0, 1, 2, 3, 4 ]
    ]


rowOfFivesWithCoord : Int -> Coord -> List (List Coord)
rowOfFivesWithCoord boardSize c =
    fiveWindows
        |> List.map (\dxs -> List.map (\dx -> moveCoord c dx 0) dxs)
        |> List.filter (\coords -> List.all (inBounds boardSize) coords)


colOfFivesWithCoord : Int -> Coord -> List (List Coord)
colOfFivesWithCoord boardSize c =
    fiveWindows
        |> List.map (\dys -> List.map (\dy -> moveCoord c 0 dy) dys)
        |> List.filter (\coords -> List.all (inBounds boardSize) coords)


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


allFivesWithCoord : Int -> Coord -> List (List Coord)
allFivesWithCoord boardSize c =
    List.concat
        [ rowOfFivesWithCoord boardSize c
        , colOfFivesWithCoord boardSize c
        , diagsWithCoord boardSize c
        ]


isWinningFive : Int -> Array Cell -> List Coord -> Bool
isWinningFive boardSize board coords =
    coords
        |> List.map (\coord -> Array.get (coordToIndex boardSize coord) board)
        |> combine
        |> Maybe.map (\cells -> List.all ((==) (OccupiedBy Player1)) cells || List.all ((==) (OccupiedBy Player2)) cells)
        |> Maybe.withDefault False


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


playerWonWithCoord : Int -> Coord -> Array Cell -> Bool
playerWonWithCoord boardSize coord newBoard =
    allFivesWithCoord boardSize coord
        |> List.any (isWinningFive boardSize newBoard)


boardIsFull : Array Cell -> Bool
boardIsFull board =
    board
        |> Array.toList
        |> List.all (\cell -> cell /= Empty)


currentColour : Game -> Settings.SimpleColour
currentColour game =
    case game.turn of
        Player1 ->
            game.settings.player1Colour

        Player2 ->
            game.settings.player2Colour


currentName : Game -> String
currentName game =
    case game.turn of
        Player1 ->
            game.settings.player1Name

        Player2 ->
            game.settings.player2Name
