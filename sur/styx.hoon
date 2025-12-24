::  styx: dead man's switch types
::
::    The ferryman waits for no one, but he is patient.
::
|%
::  +obol: proof of life token
::
::    Named for the coins placed on the dead's eyes to pay Charon.
::    Each obol resets the crossing timer.
::
+$  obol
  $:  when=@da            ::  timestamp of proof
      =obol-type          ::  how the obol was generated
  ==
::
+$  obol-type
  $%  [%ping ~]           ::  manual "I'm alive" action
      [%poke who=ship]    ::  received a poke from another ship
      [%http ~]           ::  web UI activity
      [%groups ~]         ::  groups/chat activity
  ==
::
::  +cargo: payload to deliver upon crossing
::
::    For Phase 1, only message type is supported.
::
+$  cargo
  $:  id=@uv                    ::  unique identifier
      recipient=ship            ::  who receives this cargo
      =cargo-content            ::  the payload
      created=@da               ::  when cargo was created
      updated=@da               ::  last modification
  ==
::
+$  cargo-content
  $%  [%message subject=@t body=@t]
      [%file name=@t mime=@t data=@]
  ==
::
::  +crossing-status: state of the dead man's switch
::
::    The boat's position on the river Styx.
::
+$  crossing-status
  $%  [%peaceful ~]             ::  all is well, timer running normally
      [%warning since=@da]      ::  in grace period, can still abort
      [%crossing ~]             ::  final release in progress
      [%crossed when=@da]       ::  cargo has been delivered
      [%disabled ~]             ::  switch is turned off
  ==
::
::  +config: user configuration
::
+$  config
  $:  river-width=@dr           ::  time without obol before warning
      grace-period=@dr          ::  warning period before release
      enabled=?                 ::  is the switch active
  ==
::
::  +state-0: agent state (version 0)
::
+$  state-0
  $:  %0
      =config
      =crossing-status
      last-obol=(unit @da)      ::  when we last received proof of life
      crossing-time=(unit @da)  ::  when crossing will occur (if in warning)
      cargos=(map @uv cargo)    ::  all configured cargo
      obols=(list obol)         ::  history of obols (capped)
      deliveries=(list delivery)  ::  received deliveries from others
  ==
::
::  +action: pokes into the agent
::
+$  action
  $%  ::  life signs
      [%ping ~]                         ::  manual proof of life
      ::  cargo management
      [%add-cargo recipient=ship subject=@t body=@t]
      [%add-file recipient=ship name=@t mime=@t data=@]
      [%edit-cargo id=@uv subject=@t body=@t]
      [%delete-cargo id=@uv]
      ::  configuration
      [%set-river-width width=@dr]
      [%set-grace-period period=@dr]
      [%enable ~]
      [%disable ~]
      ::  testing
      [%test-delivery id=@uv]           ::  send cargo now as test
      [%test-roundtrip ~]               ::  send test to self, verify system works
      ::  diagnostics
      [%verify ~]                       ::  run system health check
      ::  emergency
      [%abort-crossing ~]               ::  cancel during warning phase
  ==
::
::  +update: subscription updates
::
+$  update
  $%  [%status =crossing-status last-obol=(unit @da) crossing-time=(unit @da)]
      [%cargo-list cargos=(list cargo)]
      [%cargo-added =cargo]
      [%cargo-deleted id=@uv]
      [%config =config]
      [%obol-received =obol]
      [%cargo-delivered id=@uv to=ship success=?]
      [%warning message=@t]
      [%crossed ~]
  ==
::
::  +delivery: message sent to recipient on crossing
::
+$  delivery
  $:  from=ship
      =delivery-content
      sent=@da
      is-test=?
  ==
::
+$  delivery-content
  $%  [%message subject=@t body=@t]
      [%file name=@t mime=@t data=@]
  ==
::
::  +health: system health report
::
+$  health
  $:  ok=?                        ::  overall system healthy
      enabled=?                   ::  switch is enabled
      =crossing-status            ::  current status
      timer-set=?                 ::  is behn timer active
      next-event=(unit @da)       ::  when next event fires
      last-obol=(unit @da)        ::  when last proof of life
      last-obol-type=(unit obol-type)  ::  how last obol was generated
      cargo-count=@ud             ::  number of cargo items
      issues=(list @t)            ::  list of any problems
  ==
--
