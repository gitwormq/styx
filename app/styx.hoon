::  styx: a dead man's switch for urbit
::
/-  *styx
/+  styx, default-agent, dbug, srv=server
|%
+$  versioned-state
  $%  state-0
  ==
+$  card  card:agent:gall
--
::
%-  agent:dbug
=|  state-0
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
    lib   styx
::
++  on-init
  ^-  (quip card _this)
  ~&  >  '%styx initialized'
  =.  state  default-state:lib
  :_  this
  :~  [%pass /eyre/connect %arvo %e %connect [~ /styx] %styx]
  ==
::
++  on-save
  ^-  vase
  !>(state)
::
++  on-load
  |=  old-vase=vase
  ^-  (quip card _this)
  ~&  >  '%styx reloaded'
  ::  load saved state
  =/  old=state-0  !<(state-0 old-vase)
  ::  restart timer based on loaded state
  =/  timer  (next-timer:lib now.bowl config.old last-obol.old crossing-time.old crossing-status.old)
  :_  this(state old)
  ::  restart timer on reload (groups subscription persists across reloads)
  ?~  timer
    ~
  [[%pass /timer %arvo %b %wait u.timer]]~
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  |^
  ?+    mark  (on-poke:def mark vase)
  ::
      %styx-action
    =^  cards  state  (handle-action !<(action vase))
    [cards this]
  ::
      %styx-delivery
    =/  del  !<(delivery vase)
    ~&  >>  "received delivery from {<src.bowl>}"
    =.  deliveries.state  [del deliveries.state]
    `this
  ::
      %handle-http-request
    =+  !<([id=@ta =inbound-request:eyre] vase)
    (handle-http id inbound-request)
  ==
  ::
  ++  handle-action
    |=  act=action
    ^-  (quip card _state)
    ?-    -.act
        %ping
      =/  =obol  (make-obol:lib now.bowl [%ping ~])
      =/  was-warning  ?=([%warning *] crossing-status.state)
      =.  obols.state  (add-obol:lib obol obols.state)
      =.  last-obol.state  `now.bowl
      =?  crossing-status.state  was-warning
        [%peaceful ~]
      =?  crossing-time.state  was-warning
        ~
      (make-timer-cards ~)
    ::
        %enable
      =.  enabled.config.state  %.y
      =.  crossing-status.state  [%peaceful ~]
      ::  subscribe to groups for passive obols
      =/  groups-card=card  [%pass /groups %agent [our.bowl %groups] %watch /groups/ui]
      (make-timer-cards [groups-card]~)
    ::
        %disable
      =.  enabled.config.state  %.n
      =.  crossing-status.state  [%disabled ~]
      =.  crossing-time.state  ~
      :_  state
      [status-card]~
    ::
        %abort-crossing
      =.  crossing-status.state  [%peaceful ~]
      =.  crossing-time.state  ~
      (make-timer-cards ~)
    ::
        %add-cargo
      ::  prevent self-delivery
      ?:  =(recipient.act our.bowl)
        ~&  >>>  "cannot add cargo to self"
        `state
      =/  new  (make-cargo:lib now.bowl eny.bowl recipient.act subject.act body.act)
      =.  cargos.state  (~(put by cargos.state) id.new new)
      :_  state
      [[%give %fact ~[/updates] %styx-update !>([%cargo-added new])]]~
    ::
        %add-file
      ::  prevent self-delivery
      ?:  =(recipient.act our.bowl)
        ~&  >>>  "cannot add file cargo to self"
        `state
      =/  new  (make-file-cargo:lib now.bowl eny.bowl recipient.act name.act mime.act data.act)
      =.  cargos.state  (~(put by cargos.state) id.new new)
      :_  state
      [[%give %fact ~[/updates] %styx-update !>([%cargo-added new])]]~
    ::
        %delete-cargo
      =.  cargos.state  (~(del by cargos.state) id.act)
      :_  state
      [[%give %fact ~[/updates] %styx-update !>([%cargo-deleted id.act])]]~
    ::
        %edit-cargo
      =/  old  (~(get by cargos.state) id.act)
      ?~  old  `state
      =/  new  u.old(cargo-content [%message subject.act body.act], updated now.bowl)
      =.  cargos.state  (~(put by cargos.state) id.act new)
      `state
    ::
        %set-river-width
      =.  river-width.config.state  width.act
      `state
    ::
        %set-grace-period
      =.  grace-period.config.state  period.act
      `state
    ::
        %test-delivery
      =/  carg  (~(get by cargos.state) id.act)
      ?~  carg  `state
      =/  del  (cargo-to-delivery:lib u.carg our.bowl now.bowl %.y)
      :_  state
      [[%pass /deliver/test/(scot %uv id.act) %agent [recipient.u.carg %styx] %poke %styx-delivery !>(del)]]~
    ::
        %verify
      =/  report  (build-health:lib state now.bowl)
      =/  ok-txt=tape  ?:(ok.report "yes" "no")
      =/  en-txt=tape  ?:(enabled.report "yes" "no")
      =/  tm-txt=tape  ?:(timer-set.report "yes" "no")
      ~&  >  "=== STYX HEALTH REPORT ==="
      ~&  >  "ok: {ok-txt}"
      ~&  >  "enabled: {en-txt}"
      ~&  >  "timer-set: {tm-txt}"
      ~&  >  "cargo-count: {<cargo-count.report>}"
      ~&  >  "issues: {<issues.report>}"
      ~&  >  "=========================="
      `state
    ::
        %test-roundtrip
      ::  create a test delivery to ourselves
      =/  test-del=delivery
        :*  from=our.bowl
            delivery-content=[%message 'Styx Test' 'This is a roundtrip test from styx.']
            sent=now.bowl
            is-test=%.y
        ==
      ~&  >  "sending roundtrip test..."
      :_  state
      [[%pass /deliver/roundtrip %agent [our.bowl %styx] %poke %styx-delivery !>(test-del)]]~
    ==
  ::
  ++  status-card
    ^-  card
    [%give %fact ~[/updates] %styx-update !>([%status crossing-status.state last-obol.state crossing-time.state])]
  ::
  ++  make-timer-cards
    |=  extra=(list card)
    ^-  (quip card _state)
    =/  timer  (next-timer:lib now.bowl config.state last-obol.state crossing-time.state crossing-status.state)
    =/  tcards=(list card)
      ?~  timer  ~
      [[%pass /timer %arvo %b %wait u.timer]]~
    :_  state
    :(weld tcards ~[status-card] extra)
  ::
  ++  handle-http
    |=  [id=@ta req=inbound-request:eyre]
    ^-  (quip card _this)
    =/  meth  method.request.req
    ?:  =(meth %'GET')
      ::  register passive obol on page view
      =/  =obol  (make-obol:lib now.bowl [%http ~])
      =/  was-warning  ?=([%warning *] crossing-status.state)
      =.  obols.state  (add-obol:lib obol obols.state)
      =.  last-obol.state  `now.bowl
      ::  reset warning if active
      =?  crossing-status.state  was-warning  [%peaceful ~]
      =?  crossing-time.state  was-warning  ~
      ::  reschedule timer after obol
      =/  timer  (next-timer:lib now.bowl config.state last-obol.state crossing-time.state crossing-status.state)
      =/  timer-cards=(list card)
        ?~  timer  ~
        [[%pass /timer %arvo %b %wait u.timer]]~
      =^  page-cards  this  (serve-page id)
      [(weld timer-cards page-cards) this]
    ?.  =(meth %'POST')
      (redirect id)
    =/  pax  (parse-url url.request.req)
    ?+    pax  (redirect id)
        [%styx %ping ~]
      =^  cards  state  (handle-action [%ping ~])
      :_  this
      (weld (http-redirect id) cards)
    ::
        [%styx %enable ~]
      =^  cards  state  (handle-action [%enable ~])
      :_  this
      (weld (http-redirect id) cards)
    ::
        [%styx %disable ~]
      =^  cards  state  (handle-action [%disable ~])
      :_  this
      (weld (http-redirect id) cards)
    ::
        [%styx %abort ~]
      =^  cards  state  (handle-action [%abort-crossing ~])
      :_  this
      (weld (http-redirect id) cards)
    ::
        [%styx %cargo ~]
      =/  args  (parse-body body.request.req)
      =/  rec  (~(get by args) 'recipient')
      =/  sub  (~(get by args) 'subject')
      =/  bod  (~(get by args) 'body')
      ?.  &(?=(^ rec) ?=(^ sub) ?=(^ bod))
        (redirect id)
      =/  ship  (slaw %p u.rec)
      ?~  ship  (redirect id)
      =^  cards  state  (handle-action [%add-cargo u.ship u.sub u.bod])
      :_  this
      (weld (http-redirect id) cards)
    ::
        [%styx %delete ~]
      =/  args  (parse-body body.request.req)
      =/  id-arg  (~(get by args) 'id')
      ?~  id-arg  (redirect id)
      =/  cid  (slaw %uv u.id-arg)
      ?~  cid  (redirect id)
      =^  cards  state  (handle-action [%delete-cargo u.cid])
      :_  this
      (weld (http-redirect id) cards)
    ::
        [%styx %settings ~]
      =/  args  (parse-body body.request.req)
      =/  rw  (~(get by args) 'river-width')
      =/  gp  (~(get by args) 'grace-period')
      ::  parse river-width (in days)
      =?  state  ?=(^ rw)
        =/  days  (rush u.rw dem)
        ?~  days  state
        state(river-width.config (mul u.days ~d1))
      ::  parse grace-period (in hours)
      =?  state  ?=(^ gp)
        =/  hours  (rush u.gp dem)
        ?~  hours  state
        state(grace-period.config (mul u.hours ~h1))
      :_  this
      (http-redirect id)
    ==
  ::
  ++  serve-page
    |=  id=@ta
    ^-  (quip card _this)
    =/  html  (render-page state now.bowl)
    :_  this
    (http-response id 200 ['Content-Type' 'text/html']~ (some html))
  ::
  ++  redirect
    |=  id=@ta
    ^-  (quip card _this)
    :_  this
    (http-redirect id)
  ::
  ++  http-redirect
    |=  id=@ta
    ^-  (list card)
    (http-response id 303 ['Location' '/styx']~ ~)
  ::
  ++  http-response
    |=  [id=@ta code=@ud headers=(list [key=@t value=@t]) body=(unit octs)]
    ^-  (list card)
    :~  [%give %fact ~[/http-response/[id]] %http-response-header !>([code headers])]
        [%give %fact ~[/http-response/[id]] %http-response-data !>(body)]
        [%give %kick ~[/http-response/[id]] ~]
    ==
  ::
  ++  parse-url
    |=  url=@t
    ^-  path
    =/  txt  (trip url)
    =/  idx  (fall (find "?" txt) (lent txt))
    (stab (crip (scag idx txt)))
  ::
  ++  parse-body
    |=  body=(unit octs)
    ^-  (map @t @t)
    ?~  body  ~
    =/  txt  (trip q.u.body)
    %-  ~(gas by *(map @t @t))
    %+  murn  (split-text txt '&')
    |=  pair=tape
    =/  idx  (find "=" pair)
    ?~  idx  ~
    =/  k  (scag u.idx pair)
    =/  v  (urldecode (slag +(u.idx) pair))
    `[(crip k) (crip v)]
  ::
  ++  urldecode
    |=  txt=tape
    ^-  tape
    =/  out=tape  ~
    |-
    ?~  txt  (flop out)
    ?:  =(i.txt '+')
      $(txt t.txt, out [' ' out])
    ?.  =(i.txt '%')
      $(txt t.txt, out [i.txt out])
    ?.  ?=([@ @ *] t.txt)
      $(txt t.txt, out [i.txt out])
    =/  hi  (from-hex i.t.txt)
    =/  lo  (from-hex i.t.t.txt)
    ?~  hi  $(txt t.txt, out [i.txt out])
    ?~  lo  $(txt t.txt, out [i.txt out])
    =/  ch  (add (mul u.hi 16) u.lo)
    $(txt t.t.t.txt, out [ch out])
  ::
  ++  from-hex
    |=  c=@t
    ^-  (unit @)
    ?:  &((gte c '0') (lte c '9'))  `(sub c '0')
    ?:  &((gte c 'a') (lte c 'f'))  `(add 10 (sub c 'a'))
    ?:  &((gte c 'A') (lte c 'F'))  `(add 10 (sub c 'A'))
    ~
  ::
  ++  split-text
    |=  [txt=tape d=@t]
    ^-  (list tape)
    =|  res=(list tape)
    =|  cur=tape
    |-  ^-  (list tape)
    ?~  txt  (flop ?~(cur res [cur res]))
    ?:  =(i.txt d)
      %=  $
        txt  t.txt
        res  [cur res]
        cur  ~
      ==
    %=  $
      txt  t.txt
      cur  (snoc cur i.txt)
    ==
  ::
  ++  html-escape
    |=  txt=tape
    ^-  tape
    %-  zing
    %+  turn  txt
    |=  c=@
    ^-  tape
    ?:  =(c 38)   "&amp;"   ::  &
    ?:  =(c 60)   "&lt;"    ::  <
    ?:  =(c 62)   "&gt;"    ::  >
    ?:  =(c 34)   "&quot;"  ::  "
    ?:  =(c 39)   "&#39;"   ::  '
    [c ~]
  ::
  ++  render-page
    |=  [st=state-0 now=@da]
    ^-  octs
    %-  as-octs:mimes:html
    %-  crip
    ^-  tape
    =/  status-txt=tape
      ?+  crossing-status.st  "UNKNOWN"
          [%disabled ~]  "DISABLED"
          [%peaceful ~]  "PEACEFUL"
          [%warning *]   "WARNING"
          [%crossed *]   "CROSSED"
      ==
    =/  status-cls=tape
      ?+  crossing-status.st  "unknown"
          [%disabled ~]  "disabled"
          [%peaceful ~]  "peaceful"
          [%warning *]   "warning"
          [%crossed *]   "crossed"
      ==
    =/  cargo-section=tape
      %-  zing
      %+  turn  ~(tap by cargos.st)
      |=  [id=@uv =cargo]
      ^-  tape
      =/  content-desc=tape
        ?-  -.cargo-content.cargo
          %message  "Message: {(html-escape (trip subject.cargo-content.cargo))}"
          %file     "File: {(html-escape (trip name.cargo-content.cargo))}"
        ==
      "<div style='border:1px solid #8d99ae;padding:0.5rem;margin:0.5rem 0;border-radius:4px'><b>{content-desc}</b><br>To: {<recipient.cargo>}</div>"
    =/  cargo-display=tape
      ?:  =(~ cargo-section)
        "<p style='color:#8d99ae'>No cargo configured yet.</p>"
      cargo-section
    =/  delivery-section=tape
      %-  zing
      %+  turn  deliveries.st
      |=  =delivery
      ^-  tape
      =/  content-desc=tape
        ?-  -.delivery-content.delivery
          %message  "Message: {(html-escape (trip subject.delivery-content.delivery))}"
          %file     "File: {(html-escape (trip name.delivery-content.delivery))}"
        ==
      =/  test-tag=tape  ?:(is-test.delivery " (TEST)" "")
      "<div style='border:1px solid #4ecca3;padding:0.5rem;margin:0.5rem 0;border-radius:4px'><b>{content-desc}</b>{test-tag}<br>From: {<from.delivery>}</div>"
    =/  delivery-display=tape
      ?:  =(~ delivery-section)
        "<p style='color:#8d99ae'>No cargo received yet.</p>"
      delivery-section
    =/  toggle-btn=tape
      ?:  enabled.config.st
        "<form method='post' action='/styx/disable' style='display:inline'><button class='disable'>Disable</button></form>"
      "<form method='post' action='/styx/enable' style='display:inline'><button class='enable'>Enable</button></form>"
    ::  compute current settings in human units
    =/  rw-days=@ud  (div river-width.config.st ~d1)
    =/  gp-hours=@ud  (div grace-period.config.st ~h1)
    ::  compute status subtitle
    =/  status-sub=tape
      ?+  crossing-status.st  ""
          [%disabled ~]
        "Enable to start protection"
      ::
          [%peaceful ~]
        "Timer reset just now. Warning after {<rw-days>} days."
      ::
          [%warning *]
        =/  remaining=(unit @dr)  (time-until-crossing:lib now crossing-time.st)
        ?~  remaining
          "Crossing imminent!"
        =/  hrs=@ud  (div u.remaining ~h1)
        "Crossing in {<hrs>} hours! Click 'I Yet Live' to cancel."
      ::
          [%crossed *]
        "Your cargo has been delivered."
      ==
    ;:  weld
      "<!DOCTYPE html><html><head><meta charset='utf-8'>"
      "<title>styx</title><style>"
      (trip 'body{font-family:monospace;background:#1a1a2e;color:#edf2f4;padding:2rem}')
      (trip '.container{max-width:600px;margin:0 auto}')
      (trip 'h1{color:#e94560;text-align:center}')
      (trip '.status{background:#16213e;padding:1rem;border-radius:8px;text-align:center;margin:1rem 0}')
      (trip '.badge{display:inline-block;padding:0.5rem 1rem;border-radius:20px;font-weight:bold}')
      (trip '.peaceful{background:#4ecca3;color:#000}.warning{background:#ff9f1c;color:#000}')
      (trip '.disabled{background:#8d99ae;color:#000}.crossed{background:#e94560;color:#fff}')
      (trip 'button{padding:0.5rem 1rem;border:none;border-radius:4px;cursor:pointer;margin:0.25rem}')
      (trip '.ping{background:#4ecca3;color:#000}.enable{background:#4ecca3;color:#000}')
      (trip '.disable{background:#8d99ae;color:#000}')
      (trip 'section{background:#16213e;padding:1rem;border-radius:8px;margin:1rem 0}')
      (trip 'h2{color:#e94560;margin-top:0}')
      (trip 'input,textarea{width:100%;padding:0.5rem;background:#1a1a2e;border:1px solid #8d99ae;color:#edf2f4;border-radius:4px;margin:0.25rem 0}')
      (trip '.submit{background:#e94560;color:#fff}')
      "</style></head><body><div class='container'>"
      "<h1>~~ styx ~~</h1>"
      "<div class='status'><div class='badge {status-cls}'>{status-txt}</div><p style='margin:0.5rem 0 0 0;color:#8d99ae;font-size:0.9rem'>{status-sub}</p></div>"
      "<section><h2>Actions</h2>"
      "<form method='post' action='/styx/ping' style='display:inline'><button class='ping'>I Yet Live</button></form>"
      toggle-btn
      "<p style='color:#8d99ae;font-size:0.8rem;margin-top:0.5rem'>Timer auto-resets when you use Groups or visit this page.</p>"
      "</section>"
      "<section><h2>Your Cargo (outgoing)</h2>"
      cargo-display
      "</section>"
      "<section><h2>Add Cargo</h2>"
      "<form method='post' action='/styx/cargo'>"
      "<input name='recipient' placeholder='~sampel-palnet' required>"
      "<input name='subject' placeholder='Subject' required>"
      "<textarea name='body' placeholder='Message' rows='3' required></textarea>"
      "<button type='submit' class='submit'>Add</button>"
      "</form></section>"
      "<section><h2>Received Cargo (incoming)</h2>"
      delivery-display
      "</section>"
      ::  settings section
      "<section><h2>Settings</h2>"
      "<form method='post' action='/styx/settings'>"
      "<label style='display:block;margin:0.5rem 0'>Inactivity period (days before warning):<br>"
      "<input name='river-width' type='number' min='1' max='365' value='{<rw-days>}' style='width:100px'></label>"
      "<label style='display:block;margin:0.5rem 0'>Grace period (hours to respond to warning):<br>"
      "<input name='grace-period' type='number' min='1' max='168' value='{<gp-hours>}' style='width:100px'></label>"
      "<button type='submit' class='submit' style='margin-top:0.5rem'>Save Settings</button>"
      "</form></section>"
      ::  help section
      "<section><h2>How It Works</h2>"
      "<div style='line-height:1.6'>"
      "<p><b>Styx is a dead man's switch.</b> If you stop using your ship, it will deliver all your cargo to the recipients you specify.</p>"
      "<p><b>The Timer:</b> Activity that resets your timer:</p>"
      "<ul style='margin:0.5rem 0'>"
      "<li>Using Groups (messages, reactions)</li>"
      "<li>Visiting this page</li>"
      "<li>Clicking 'I Yet Live'</li>"
      "</ul>"
      "<p><b>Warning Phase:</b> After {<rw-days>} days of no activity, you enter warning. You then have {<gp-hours>} hours to show activity or all cargo is delivered.</p>"
      "<p><b>Settings:</b> The timer settings above are global - they apply to your entire switch, not individual cargo items. When the switch fires, ALL cargo is delivered at once.</p>"
      "<p style='color:#ff9f1c'><b>Important:</b> Your ship must be running for the timer to work. Recipients must also have Styx installed to receive cargo.</p>"
      "</div></section>"
      "</div></body></html>"
    ==
  --
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+    path  (on-watch:def path)
      [%updates ~]
    ::  send initial state to new subscriber
    :_  this
    :~  [%give %fact ~ %styx-update !>([%status crossing-status.state last-obol.state crossing-time.state])]
        [%give %fact ~ %styx-update !>([%cargo-list ~(val by cargos.state)])]
        [%give %fact ~ %styx-update !>([%config config.state])]
    ==
      [%http-response *]  `this
  ==
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+    wire  (on-agent:def wire sign)
      [%groups ~]
    ?+  -.sign  `this
        %fact
      ::  any groups activity = proof of life
      =/  =obol  (make-obol:lib now.bowl [%groups ~])
      =/  was-warning  ?=([%warning *] crossing-status.state)
      =.  obols.state  (add-obol:lib obol obols.state)
      =.  last-obol.state  `now.bowl
      =?  crossing-status.state  was-warning  [%peaceful ~]
      =?  crossing-time.state  was-warning  ~
      ::  reschedule timer after obol
      =/  timer  (next-timer:lib now.bowl config.state last-obol.state crossing-time.state crossing-status.state)
      ?~  timer  `this
      :_  this
      [[%pass /timer %arvo %b %wait u.timer]]~
    ::
        %kick
      ::  re-subscribe if kicked
      :_  this
      :~  [%pass /groups %agent [our.bowl %groups] %watch /groups/ui]
      ==
    ::
        %watch-ack
      ?~  p.sign
        ~&  >  "subscribed to groups"
        `this
      ~&  >>  "groups subscription failed, will retry"
      `this
    ==
  ::
      [%deliver *]
    ?+  -.sign  (on-agent:def wire sign)
        %poke-ack
      ?~  p.sign
        ~&  >  "delivery ok"
        `this
      ~&  >>>  "delivery failed"
      `this
    ==
  ==
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?+    wire  (on-arvo:def wire sign-arvo)
      [%eyre %connect ~]
    ?>  ?=([%eyre %bound *] sign-arvo)
    ~&  >  "bound: {<accepted.sign-arvo>}"
    `this
  ::
      [%timer ~]
    ?>  ?=([%behn %wake *] sign-arvo)
    ?^  error.sign-arvo  `this
    ?.  enabled.config.state  `this
    ?:  (should-cross:lib now.bowl crossing-time.state crossing-status.state)
      =.  crossing-status.state  [%crossed now.bowl]
      =/  delivery-cards=(list card)
        %+  turn  ~(tap by cargos.state)
        |=  [id=@uv =cargo]
        =/  del  (cargo-to-delivery:lib cargo our.bowl now.bowl %.n)
        [%pass /deliver/(scot %uv id) %agent [recipient.cargo %styx] %poke %styx-delivery !>(del)]
      ~&  >  "crossing: delivering {<(lent delivery-cards)>} cargo(s)"
      [delivery-cards this]
    ?:  (should-warn:lib now.bowl config.state last-obol.state crossing-status.state)
      =.  crossing-status.state  [%warning now.bowl]
      =.  crossing-time.state  `(add now.bowl grace-period.config.state)
      ~&  >  "entering warning phase, crossing in {<grace-period.config.state>}"
      ::  schedule timer for crossing
      :_  this
      [[%pass /timer %arvo %b %wait (add now.bowl grace-period.config.state)]]~
    `this
  ==
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+    path  (on-peek:def path)
      [%x %status ~]
    ``styx-update+!>([%status crossing-status.state last-obol.state crossing-time.state])
  ::
      [%x %config ~]
    ``styx-update+!>([%config config.state])
  ::
      [%x %cargo ~]
    ``styx-update+!>([%cargo-list ~(val by cargos.state)])
  ::
      [%x %cargo @ ~]
    =/  id  (slav %uv i.t.t.path)
    =/  carg  (~(get by cargos.state) id)
    ?~  carg  [~ ~]
    ``styx-update+!>([%cargo-added u.carg])
  ::
      [%x %deliveries ~]
    ``noun+!>(deliveries.state)
  ::
      [%x %health ~]
    =/  report  (build-health:lib state now.bowl)
    ``noun+!>(report)
  ==
++  on-leave  on-leave:def
++  on-fail   on-fail:def
--
