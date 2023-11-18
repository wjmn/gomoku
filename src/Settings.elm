module Settings exposing (..)

{-| This module contains the types and default values for the game settings.
-}

import Common exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)



--------------------------------------------------------------------------------
-- SETTING DEFINITIONS
-- You can add / delete settings by modifying the following 5 steps:
-- 1. Define the data model for your settings and their types.
-- 2. Define the default values for your settings.
-- 3. Add a message type to update your settings.
-- 4. Define explicitly what happens to your settings when a message is received.
-- 5. Define a list of pickers for each setting you want to be able to change.
-- This should cover most of the basic use cases. If you need extra customisation,
-- you're welcome to edit the code below or delete everything here and start
-- from scratch.
-- For STEP 5, I've defined a bunch of helper functions for you to make things easier.
-- Helper functions include:
-- - inputString         (a small text input for the user to input a string)
-- - inputFloat          (a number input for floats)
-- - inputInt            (a number input for ints)
-- - inputFloatRange     (a range slider for floats)
-- - inputIntRange       (a range slider for ints)
-- - pickChoiceButtons   (a set of buttons for the user to pick from - good for enums)
-- - pickChoiceDropdown  (a dropdown of options for the user to pick from)
-- You can customise this further if you so wish (see the HELPER FUNCTIONS section below).
--------------------------------------------------------------------------------
-- STEP 1: Define the data model for your settings and their types.


type alias Settings =
    { playMode : PlayMode
    , computerDifficulty : ComputerDifficulty
    , boardSize : Int
    , player1Name : String
    , player1Colour : SimpleColour
    , player2Name : String
    , player2Colour : SimpleColour
    }



-- STEP 2: Define the default values for your settings.


default : Settings
default =
    { playMode = PlayHumanVsHuman
    , computerDifficulty = Easy
    , boardSize = 15
    , player1Name = "Alice"
    , player1Colour = Red
    , player2Name = "Bob"
    , player2Colour = Blue
    }



-- STEP 3: Add a message type to update your settings.
-- Your message type should have a payload attached (the new value for the setting).


type Msg
    = SetPlayMode PlayMode
    | SetComputerDifficulty ComputerDifficulty
    | SetBoardSize Int
    | SetPlayerName Player String
    | SetPlayerColour Player SimpleColour



-- STEP 4: Define explicitly what happens to your settings when a message is received.
-- Most likely, you'll just update the settings record.


update : Msg -> Settings -> Settings
update msg settings =
    case msg of
        SetPlayMode playMode ->
            { settings | playMode = playMode }

        SetComputerDifficulty difficulty ->
            { settings | computerDifficulty = difficulty }

        SetBoardSize size ->
            { settings | boardSize = size }

        SetPlayerName player name ->
            case player of
                Player1 ->
                    { settings | player1Name = name }

                Player2 ->
                    { settings | player2Name = name }

        SetPlayerColour player colour ->
            case player of
                Player1 ->
                    { settings | player1Colour = colour }

                Player2 ->
                    { settings | player2Colour = colour }



-- STEP 5: Define a list of pickers for each setting you want to be able to change.


pickers : Settings -> List SettingPickerItem
pickers settings =
    [ pickChoiceDropdown
        { label = "Play Mode"
        , onSelect = SetPlayMode
        , toString = playModeToString
        , fromString = stringToPlaymode
        , current = settings.playMode
        , options = [ ( "Human vs Human", PlayHumanVsHuman ), ( "Me vs Computer", PlayMeVsComputer ), ( "Computer vs Me", PlayComputerVsMe ) ]
        }
    , pickChoiceButtons
        { label = "Computer Difficulty"
        , onSelect = SetComputerDifficulty
        , current = settings.computerDifficulty
        , options = [ ( "Easy", Easy ), ( "Hard", Hard ) ]
        }
    , inputIntRange
        { label = "Board Size"
        , value = settings.boardSize
        , min = 8
        , max = 20
        , onChange = SetBoardSize
        }
    , inputString
        { label = "Player 1 Name"
        , value = settings.player1Name
        , onChange = SetPlayerName Player1
        }
    , pickChoiceButtons
        { label = "Player 1 Colour"
        , onSelect = SetPlayerColour Player1
        , current = settings.player1Colour
        , options = [ ( "Red", Red ), ( "Green", Green ), ( "Blue", Blue ) ]
        }
    , inputString
        { label = "Player 2 Name"
        , value = settings.player2Name
        , onChange = SetPlayerName Player2
        }
    , pickChoiceButtons
        { label = "Player 2 Colour"
        , onSelect = SetPlayerColour Player2
        , current = settings.player2Colour
        , options = [ ( "Red", Red ), ( "Green", Green ), ( "Blue", Blue ) ]
        }
    ]



--------------------------------------------------------------------------------
-- SUPPORTING TYPES
-- A few custom types I've defined for my settings, as I wanted to represent
-- some of the choices as enums.
--------------------------------------------------------------------------------


{-| Play mode (i.e. human vs human, me vs AI or AI vs me) for the game.
This is usually chosen as a setting before the game starts.
-}
type PlayMode
    = PlayHumanVsHuman
    | PlayMeVsComputer
    | PlayComputerVsMe


playModeToString : PlayMode -> String
playModeToString playMode =
    case playMode of
        PlayHumanVsHuman ->
            "Human vs Human"

        PlayMeVsComputer ->
            "Me vs Computer"

        PlayComputerVsMe ->
            "Computer vs Me"


stringToPlaymode : String -> PlayMode
stringToPlaymode string =
    case string of
        "Human vs Human" ->
            PlayHumanVsHuman

        "Me vs Computer" ->
            PlayMeVsComputer

        "Computer vs Me" ->
            PlayComputerVsMe

        _ ->
            PlayHumanVsHuman


{-| Difficulty of the computer if playing against a computer
-}
type ComputerDifficulty
    = Easy
    | Hard


{-| A simple type to represent three possible colours
-}
type SimpleColour
    = Red
    | Green
    | Blue


colourToString : SimpleColour -> String
colourToString colour =
    case colour of
        Red ->
            "red"

        Green ->
            "green"

        Blue ->
            "blue"



--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
-- If your use cases are covered by the basic types of settings above, you don't have to
-- edit any of the code below (it's boilerplate to make things easier for you).
-- However, if you need extra customisation, then you're welcome to edit it
-- if you know what you're doing (e.g. show a setting only in certain conditions,
-- or add extra specific styling to a setting).
--------------------------------------------------------------------------------


type SettingPickerItem
    = InputString { label : String, value : String, onChange : String -> Msg }
    | InputFloat { label : String, value : Float, min : Float, max : Float, onChange : Float -> Msg }
    | InputInt { label : String, value : Int, min : Int, max : Int, onChange : Int -> Msg }
    | InputFloatRange { label : String, value : Float, step : Float, min : Float, max : Float, onChange : Float -> Msg }
    | InputIntRange { label : String, value : Int, min : Int, max : Int, onChange : Int -> Msg }
    | PickChoiceButtons { label : String, options : List { label : String, onSelect : Msg, isSelected : Bool } }
    | PickChoiceDropdown { label : String, onSelect : String -> Msg, options : List { label : String, value : String, isSelected : Bool } }


inputString : { label : String, value : String, onChange : String -> Msg } -> SettingPickerItem
inputString data =
    InputString data


inputFloat : { label : String, value : Float, min : Float, max : Float, onChange : Float -> Msg } -> SettingPickerItem
inputFloat data =
    InputFloat data


inputInt : { label : String, value : Int, min : Int, max : Int, onChange : Int -> Msg } -> SettingPickerItem
inputInt data =
    InputInt data


inputFloatRange : { label : String, value : Float, step : Float, min : Float, max : Float, onChange : Float -> Msg } -> SettingPickerItem
inputFloatRange data =
    InputFloatRange data


inputIntRange : { label : String, value : Int, min : Int, max : Int, onChange : Int -> Msg } -> SettingPickerItem
inputIntRange data =
    InputIntRange data


pickChoiceButtons : { label : String, onSelect : enum -> Msg, current : enum, options : List ( String, enum ) } -> SettingPickerItem
pickChoiceButtons { label, onSelect, current, options } =
    PickChoiceButtons
        { label = label
        , options = List.map (\( optionLabel, value ) -> { label = optionLabel, onSelect = onSelect value, isSelected = value == current }) options
        }


pickChoiceDropdown : { label : String, onSelect : enum -> Msg, toString : enum -> String, fromString : String -> enum, current : enum, options : List ( String, enum ) } -> SettingPickerItem
pickChoiceDropdown { label, onSelect, toString, fromString, current, options } =
    PickChoiceDropdown
        { label = label
        , onSelect = fromString >> onSelect
        , options = List.map (\( optionLabel, value ) -> { label = optionLabel, value = toString value, isSelected = value == current }) options
        }


viewPickerItem : Settings -> SettingPickerItem -> Html Msg
viewPickerItem settings item =
    case item of
        InputString data ->
            div [ class "setting-picker-item" ]
                [ label [ class "setting-picker-item-label" ] [ text data.label ]
                , input [ class "setting-picker-item-input setting-picker-item-input-string", type_ "text", value data.value, onInput data.onChange ] []
                ]

        InputFloat data ->
            div [ class "setting-picker-item" ]
                [ label [ class "setting-picker-item-label" ] [ text data.label ]
                , input
                    [ class "setting-picker-item-input setting-picker-item-input-float"
                    , type_ "number"
                    , value (String.fromFloat data.value)
                    , Html.Attributes.min (String.fromFloat data.min)
                    , Html.Attributes.max (String.fromFloat data.max)
                    , onInput (String.toFloat >> Maybe.withDefault 0.0 >> data.onChange)
                    ]
                    []
                ]

        InputInt data ->
            div [ class "setting-picker-item" ]
                [ label [ class "setting-picker-item-label" ] [ text data.label ]
                , input
                    [ class "setting-picker-item-input setting-picker-item-input-int"
                    , type_ "number"
                    , value (String.fromInt data.value)
                    , Html.Attributes.min (String.fromInt data.min)
                    , Html.Attributes.max (String.fromInt data.max)
                    , onInput (String.toInt >> Maybe.withDefault 0 >> data.onChange)
                    ]
                    []
                ]

        InputFloatRange data ->
            div [ class "setting-picker-item" ]
                [ label [ class "setting-picker-item-label" ] [ text data.label ]
                , div [ class "setting-picker-item-input-container" ]
                    [ input
                        [ class "setting-picker-item-input setting-picker-item-input-float-range"
                        , type_ "range"
                        , value (String.fromFloat data.value)
                        , Html.Attributes.min (String.fromFloat data.min)
                        , Html.Attributes.max (String.fromFloat data.max)
                        , step (String.fromFloat data.step)
                        , onInput (String.toFloat >> Maybe.withDefault 0.0 >> data.onChange)
                        ]
                        []
                    , div [ class "setting-picker-item-input-value" ] [ text (String.fromFloat data.value) ]
                    ]
                ]

        InputIntRange data ->
            div [ class "setting-picker-item" ]
                [ label [ class "setting-picker-item-label" ] [ text data.label ]
                , div [ class "setting-picker-item-input-container" ]
                    [ input
                        [ class "setting-picker-item-input setting-picker-item-input-int-range"
                        , type_ "range"
                        , value (String.fromInt data.value)
                        , Html.Attributes.min (String.fromInt data.min)
                        , Html.Attributes.max (String.fromInt data.max)
                        , onInput (String.toInt >> Maybe.withDefault 0 >> data.onChange)
                        ]
                        []
                    , div [ class "setting-picker-item-input-value" ] [ text (String.fromInt data.value) ]
                    ]
                ]

        PickChoiceButtons data ->
            -- For convenience: don't display the computer difficulty picker if it's a human vs human play mode.
            if data.label == "Computer Difficulty" && settings.playMode == PlayHumanVsHuman then
                div [] []

            else
                div [ class "setting-picker-item" ]
                    [ label [ class "setting-picker-item-label" ] [ text data.label ]
                    , div [ class "setting-picker-item-input setting-picker-item-input-buttons" ]
                        (List.map
                            (\{ label, onSelect, isSelected } ->
                                button
                                    [ class ("setting-picker-item-button setting-picker-item-button-" ++ String.replace " " "-" label)
                                    , classList [ ( "selected", isSelected ) ]
                                    , onClick onSelect
                                    ]
                                    [ text label ]
                            )
                            data.options
                        )
                    ]

        PickChoiceDropdown data ->
            div [ class "setting-picker-item" ]
                [ label [ class "setting-picker-item-label" ] [ text data.label ]
                , select [ class "setting-picker-item-input setting-picker-item-input-select", onInput data.onSelect ]
                    (List.map
                        (\optionData ->
                            option [ value optionData.value, selected optionData.isSelected ] [ text optionData.label ]
                        )
                        data.options
                    )
                ]


viewPicker : Settings -> List SettingPickerItem -> Html Msg
viewPicker settings items =
    div [ id "settings-picker" ]
        (List.map (viewPickerItem settings) items)


view : Settings -> Html Msg
view settings =
    div [ id "settings" ]
        [ viewPicker settings (pickers settings)
        ]
