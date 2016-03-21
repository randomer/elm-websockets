module WebSockets.Server
  ( listen
  --, accept
  , send
  )
  where

import Task exposing (..)

type alias Connection =
  { id: Int
  , port_: Int
  , origin: String
  , protocol: Maybe String
  }

type alias Message =
  { connection: Connection
  , data: String
  , openConnections: List Connection
  }

type alias Server =
  { port': Int
  --, requests: Signal Request
  , openConnections: Signal (List Connection)
  , dataStream: Signal Message
  }

initRequest =
  { id = -1
  , port_ = -1
  --, origin = ""
  , protocols = []
  }

initConnection =
  { id = -1
  , port_ = -1
  , origin = ""
  , protocol = Nothing
  }

firstMatchIndex : a -> List a -> Maybe Int
firstMatchIndex thing list =
  let
    check item (i, matchedIndex) =
      let nextI = i + 1 in
      case matchedIndex of
        Just _ -> (nextI, matchedIndex)
        Nothing -> if thing == item then (nextI, Just i) else (nextI, Nothing)
    (_, res) = List.foldl check (0, Nothing) list
  in
    res

listen : Int -> List String -> { server: Server, listener: Task x (){-, requests: Signal (Task x ())-} }
listen port' protocols =
  let
    task = Signal.send newServerMbx.address { port_ = port', protocols = protocols }
    initMessage =
      { connection = initConnection
      , data = ""
      , openConnections = []
      }
    --chooseProtocol p chosen =
    --  case chosen of
    --    Just pIndex -> 
    --      case firstMatchIndex p protocols of
    --        Just matchIndex -> Just (min pIndex matchIndex)
    --        Nothing -> Just pIndex
    --    Nothing -> firstMatchIndex p protocols
    --reqTask req = Signal.send reqResultMbx.address
    --  { protocol = List.foldl chooseProtocol Nothing req.protocols
    --  , req = req
    --  }
    server =
      { port' = port'
      --, requests = 
      , openConnections = Signal.map
          (List.filter (\c -> c.port_ == port')) openConnections
      , dataStream = Signal.filterMap (\d -> if d.connection.port_ == port' then Just d else Nothing) initMessage data
      }
  in
    { server = server
    , listener = task
    --, requests = Signal.filterMap (\req -> if req.port_ == port' then Just req else Nothing) initRequest requests
    --      |> Signal.map reqTask
    }

--accept : Request -> Task x ()
--accept req =
--  Signal.send acceptedMbx.address req

send : List Connection -> String -> Task x ()
send cons data =
  Signal.send outgoingMbx.address {connections = cons, data = data}

port newServer : Signal { port_: Int, protocols: List String }
port newServer =
  newServerMbx.signal

newServerMbx = Signal.mailbox { port_ = -1, protocols = [] }

type alias Request =
  { id : Int
  , port_: Int
  --, origin: String
  , protocols: List String
  }

port requests : Signal Request

--port accepted : Signal Request
--port accepted = acceptedMbx.signal

port reqResult : Signal {protocol : Maybe String, req : Request}
port reqResult = reqResultMbx.signal

reqResultMbx = Signal.mailbox {protocol = Nothing, req = initRequest}
--acceptedMbx = Signal.mailbox initRequest

port openConnections : Signal (List Connection)

port outgoing : Signal { connections: List Int, data: String }
port outgoing = Signal.map (\o -> { connections = List.map .id o.connections, data = o.data}) outgoingMbx.signal

outgoingMbx = Signal.mailbox {connections=[], data=""}

port data : Signal { data: String, connection: Connection, openConnections: List Connection}