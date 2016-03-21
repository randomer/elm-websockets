module WebSockets.Client
  ( WebSocket
  , open
  , send
  , close
  , Status(..)
  )
  where

import Task exposing (..)

type alias Config =
  { tag: String
  , host: String
  , port_: Int
  , protocols: List String
  }

type Status
  = Connecting
  | Open String (Signal String) -- Returns server-selected protocol and a signal of incoming data
  | Closing
  | Closed

type alias WebSocket =
  { tag: String
  , host: String
  , port': Int
  , status: Signal Status
  , data: Signal String
  }

open : String -> String -> Int -> List String -> { task : Task x (), webSocket : WebSocket }
open tag host port' protocols =
  let
    --mbox = Signal.Mailbox Connecting
    statusSignal = Signal.filterMap (\so -> if so.tag == tag then Just (objectToStatus so) else Nothing) Connecting statuses
    dataSignal = Signal.filterMap (\taggedData -> if taggedData.tag == tag then Just taggedData.data else Nothing) "" data
  in
    { task = Signal.send openMbx.address (Config tag host port' protocols)
    , webSocket = WebSocket tag host port' statusSignal dataSignal
    }

send : WebSocket -> String -> Task x ()
send ws data =
  Signal.send sendMbx.address { tag = ws.tag, data = data }

close : WebSocket -> Task x ()
close ws =
  Signal.send closeMbx.address ws.tag

type alias StatusObject =
  { tag: String
  , status: Int
  , protocol: String
  , error: Maybe String
  --, wasClean: Bool
  --, code: Int -- Close event
  }

port statuses : Signal StatusObject

objectToStatus : StatusObject -> Status
objectToStatus so =
  case so.status of
    0 -> Connecting
    1 -> Open so.protocol
        <| Signal.filterMap
          (\do -> if do.tag == so.tag then Just do.data else Nothing) "" data
    2 -> Closing
    3 -> Closed
    _ -> Closed

port data : Signal { tag: String, data: String }

openMbx : Signal.Mailbox Config
openMbx = Signal.mailbox (Config "" "" -1 [])

port doOpen : Signal Config
port doOpen = openMbx.signal

sendMbx : Signal.Mailbox { tag: String, data: String }
sendMbx = Signal.mailbox { tag = "", data = "" }

port doSend : Signal { tag: String, data: String }
port doSend = sendMbx.signal

closeMbx : Signal.Mailbox String
closeMbx = Signal.mailbox ""

port doClose : Signal String
port doClose = closeMbx.signal