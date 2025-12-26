::  styx: helper library
::
/-  *styx
|%
::  +default-config: sensible defaults for new users
::
++  default-config
  ^-  config
  :*  river-width=~d60          ::  60 days without activity
      grace-period=~h72         ::  72 hour warning period
      enabled=%.n               ::  disabled by default (user must opt in)
  ==
::
::  +default-state: initial agent state
::
++  default-state
  ^-  state-1
  :*  %1
      default-config
      crossing-status=[%disabled ~]
      last-obol=~
      crossing-time=~
      cargos=*(map @uv cargo)
      obols=*(list obol)
      deliveries=*(list delivery)
  ==
::
::  +time-until-warning: calculate time remaining before warning phase
::
++  time-until-warning
  |=  [now=@da =config last=(unit @da)]
  ^-  (unit @dr)
  ?~  last  ~
  =/  deadline=@da  (add u.last river-width.config)
  ?:  (gth now deadline)
    ~
  `(sub deadline now)
::
::  +time-until-crossing: calculate time remaining before final crossing
::
++  time-until-crossing
  |=  [now=@da crossing=(unit @da)]
  ^-  (unit @dr)
  ?~  crossing  ~
  ?:  (gth now u.crossing)
    ~
  `(sub u.crossing now)
::
::  +should-warn: check if we should enter warning phase
::
++  should-warn
  |=  [now=@da =config last=(unit @da) =crossing-status]
  ^-  ?
  ?.  enabled.config
    %.n
  ?+  crossing-status  %.n
      [%peaceful ~]
    ?~  last  %.n
    (gte now (add u.last river-width.config))
  ==
::
::  +should-cross: check if we should trigger final crossing
::
++  should-cross
  |=  [now=@da crossing=(unit @da) =crossing-status]
  ^-  ?
  ?+  crossing-status  %.n
      [%warning *]
    ?~  crossing  %.n
    (gte now u.crossing)
  ==
::
::  +make-obol: create an obol record
::
++  make-obol
  |=  [now=@da =obol-type]
  ^-  obol
  [when=now obol-type=obol-type]
::
::  +add-obol: add obol to history, keeping last 100
::
++  add-obol
  |=  [new=obol old=(list obol)]
  ^-  (list obol)
  =/  combined=(list obol)  [new old]
  (scag 100 combined)
::
::  +make-cargo: create a new message cargo item
::
++  make-cargo
  |=  [now=@da eny=@uvJ recipient=ship body=@t]
  ^-  cargo
  :*  id=(sham eny)
      recipient=recipient
      cargo-content=[%message body]
      created=now
      updated=now
      acked=~
  ==
::
::  +make-file-cargo: create a new file cargo item
::
++  make-file-cargo
  |=  [now=@da eny=@uvJ recipient=ship name=@t mime=@t data=@]
  ^-  cargo
  :*  id=(sham eny)
      recipient=recipient
      cargo-content=[%file name mime data]
      created=now
      updated=now
      acked=~
  ==
::
::  +next-timer: calculate when to set the next behn timer
::
::    Returns the next important time to wake up:
::    - If peaceful: wake at warning time
::    - If warning: wake at crossing time
::    - Otherwise: no timer needed
::
++  next-timer
  |=  [now=@da =config last=(unit @da) crossing=(unit @da) =crossing-status]
  ^-  (unit @da)
  ?.  enabled.config
    ~
  ?+  crossing-status  ~
      [%peaceful ~]
    ?~  last  ~
    `(add u.last river-width.config)
  ::
      [%warning *]
    crossing
  ==
::
::  +format-duration: human-readable duration
::
++  format-duration
  |=  d=@dr
  ^-  @t
  =/  days  (div d ~d1)
  =/  hours  (div (mod d ~d1) ~h1)
  =/  mins  (div (mod d ~h1) ~m1)
  ?:  (gte days 1)
    (crip "{(scow %ud days)} day{?:(=(days 1) "" "s")}")
  ?:  (gte hours 1)
    (crip "{(scow %ud hours)} hour{?:(=(hours 1) "" "s")}")
  (crip "{(scow %ud mins)} minute{?:(=(mins 1) "" "s")}")
::
::  +format-date: render @da as human-readable string
::
++  format-date
  |=  d=@da
  ^-  tape
  =/  dat  (yore d)
  =/  months=(list tape)
    :~  "Jan"  "Feb"  "Mar"  "Apr"  "May"  "Jun"
        "Jul"  "Aug"  "Sep"  "Oct"  "Nov"  "Dec"
    ==
  =/  mon=tape  (snag (dec m.dat) months)
  =/  hr=@ud  h.t.dat
  =/  mn=@ud  m.t.dat
  =/  hr-pad=tape  ?:((lth hr 10) "0" "")
  =/  mn-pad=tape  ?:((lth mn 10) "0" "")
  "{mon} {<d.t.dat>}, {<y.dat>} {hr-pad}{<hr>}:{mn-pad}{<mn>}"
::
::  +cargo-to-json: serialize cargo to JSON string
::
++  cargo-to-json
  |=  =cargo
  ^-  tape
  =/  msg=tape
    ?-  -.cargo-content.cargo
      %message  (trip body.cargo-content.cargo)
      %file     (trip name.cargo-content.cargo)
    ==
  =/  typ=tape
    ?-  -.cargo-content.cargo
      %message  "message"
      %file     "file"
    ==
  =/  ack-str=tape
    ?~  acked.cargo  "null"
    "\"{(format-date u.acked.cargo)}\""
  ;:  weld
    "\{\"id\":\"{<id.cargo>}\","
    "\"recipient\":\"{<recipient.cargo>}\","
    "\"type\":\"{typ}\","
    "\"content\":\"{(json-escape msg)}\","
    "\"created\":\"{(format-date created.cargo)}\","
    "\"acked\":"
    ack-str
    "\}"
  ==
::
::  +json-escape: escape special chars for JSON
::
++  json-escape
  |=  txt=tape
  ^-  tape
  %-  zing
  %+  turn  txt
  |=  c=@
  ^-  tape
  ?:  =(c 34)   "\\\""    ::  "
  ?:  =(c 92)   "\\\\"    ::  \
  ?:  =(c 10)   "\\n"     ::  newline
  ?:  =(c 13)   "\\r"     ::  carriage return
  ?:  =(c 9)    "\\t"     ::  tab
  [c ~]
::
::  +cargo-to-delivery: convert cargo to delivery
::
++  cargo-to-delivery
  |=  [=cargo from=ship now=@da is-test=?]
  ^-  delivery
  =/  content=delivery-content
    ?-  -.cargo-content.cargo
      %message  [%message body.cargo-content.cargo]
      %file     [%file name.cargo-content.cargo mime.cargo-content.cargo data.cargo-content.cargo]
    ==
  :*  from=from
      cargo-id=id.cargo
      delivery-content=content
      sent=now
      is-test=is-test
  ==
::
::  +build-health: generate health report from state
::
++  build-health
  |=  [st=state-1 now=@da]
  ^-  health
  =/  issues=(list @t)  ~
  ::  check for issues
  =?  issues  &(enabled.config.st ?=(~ last-obol.st))
    ['enabled but no obols recorded' issues]
  =?  issues  &(enabled.config.st =(~ cargos.st))
    ['enabled but no cargo configured' issues]
  =?  issues  ?=([%crossed *] crossing-status.st)
    ['cargo has been delivered (crossed)' issues]
  ::  calculate next event
  =/  next-event=(unit @da)
    (next-timer now config.st last-obol.st crossing-time.st crossing-status.st)
  ::  get last obol type
  =/  last-type=(unit obol-type)
    ?~  obols.st  ~
    `obol-type.i.obols.st
  ::  build report
  :*  ok==(~ issues)
      enabled=enabled.config.st
      crossing-status=crossing-status.st
      timer-set=?=(^ next-event)
      next-event=next-event
      last-obol=last-obol.st
      last-obol-type=last-type
      cargo-count=~(wyt by cargos.st)
      issues=(flop issues)
  ==
--
