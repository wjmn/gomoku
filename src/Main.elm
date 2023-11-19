module Main exposing (..)

{-| This is the main interface for your game.
I would suggest keep the dynamic portions of your game in this module (e.g. actions and updates)
To make things cleaner, you can define helper functions in a separate module.
-}

import Browser
import Common exposing (..)
import Game exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Settings exposing (..)



---- MODEL ----


type Model
    = SettingsScreen Settings
    | GameplayScreen Game


init : ( Model, Cmd Msg )
init =
    ( SettingsScreen Settings.default, Cmd.none )



---- UPDATE ----


type Msg
    = SettingsMsg Settings.Msg
    | GameplayMsg Game.Msg
    | ClickedStartGame
    | ClickedStartNewGame


withCmd : Cmd Msg -> Model -> ( Model, Cmd Msg )
withCmd cmd screen =
    ( screen, cmd )


mapGameCmd : ( Game, Cmd Game.Msg ) -> ( Model, Cmd Msg )
mapGameCmd ( game, cmd ) =
    ( GameplayScreen game, Cmd.map GameplayMsg cmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg screen =
    case screen of
        SettingsScreen settings ->
            case msg of
                SettingsMsg settingsMsg ->
                    SettingsScreen (Settings.update settingsMsg settings)
                        |> withCmd Cmd.none

                ClickedStartGame ->
                    Game.init settings
                        |> mapGameCmd

                _ ->
                    screen
                        |> withCmd Cmd.none

        GameplayScreen game ->
            case msg of
                GameplayMsg gameMsg ->
                    Game.update gameMsg game
                        |> mapGameCmd

                ClickedStartNewGame ->
                    SettingsScreen game.settings
                        |> withCmd Cmd.none

                _ ->
                    screen
                        |> withCmd Cmd.none



---- VIEW ----


introText : Html Msg
introText =
    div [ class "intro-text" ]
        [ p []
            [ text "Welcome to "
            , span [ class "gomoku-title" ] [ text "Gomoku" ]
            , text ", a five-in-a-row strategy board game. The first player to place five stones in a row wins (horizontally, vertically or diagonally)."
            ]
        , p [] [ text "Choose your settings below and click Start Game to begin." ]
        ]


view : Model -> Html Msg
view screen =
    case screen of
        SettingsScreen settings ->
            div [ id "settings-screen", class "screen" ]
                [ div [ id "settings-modal" ]
                    [ div [ id "settings-modal-header" ]
                        [ h1 [ id "settings-modal-header-title" ] [ text "Gomoku" ]
                        , h2 [ id "settings-modal-header-team" ] [ text "Team Example" ]
                        ]
                    , div [ id "settings-modal-intro" ] [ introText ]
                    , div [ id "settings-modal-body" ] [ Settings.view settings |> Html.map SettingsMsg ]
                    , div [ id "settings-modal-footer" ] [ button [ id "start-game-button", onClick ClickedStartGame ] [ text "Start Game" ] ]
                    ]
                ]

        GameplayScreen game ->
            div [ id "gameplay-screen", class "screen" ]
                [ Game.view game |> Html.map GameplayMsg
                , div [ id "start-new-game-button-container" ] [ button [ id "start-new-game-button", onClick ClickedStartNewGame ] [ text "Restart" ] ]
                ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
