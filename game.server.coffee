{APP_STATE, ROUND_PHASE, PLAYER_STATE} = Enums.get()

exports.initGame = ->
  # Init vars
  Db.shared.set 'czar', null
  Db.shared.set 'round', 0
  Db.shared.set 'rounds', {}
  
  # Get cards
  Db.shared.set 'cards', 'black', Object Packs.getBlackCards(Db.shared.peek 'packs')
  Db.shared.set 'cards', 'white', Object Packs.getWhiteCards(Db.shared.peek 'packs')
  
  # Player: init vars and get cards
  players = Db.shared.peek 'players'
  players.forEach (player) ->
    Db.shared.set 'player', player, 'points', 0
    Db.shared.set 'player', player, 'cards', exports.drawCards('white', 10)
  
  Event.create
    normalPrio: 'all',
    text: 'The game is starting!'
  
  # Start first round
  do exports.initRound

exports.initRound = ->
  players = Db.shared.peek 'players'
  czar = null
  
  Db.shared.incr 'round'
  Db.shared.set 'phase', ROUND_PHASE.PLAYER
  Db.shared.modify 'czar', (id) ->
    czarIndex = players.indexOf id
    czarIndex = ++czarIndex % players.length
    czar = players[czarIndex]
  
  Db.shared.set 'blackCard', exports.drawCards('black')[0]
  
  players.forEach (player) ->
    Db.shared.set 'player', player, 'state', PLAYER_STATE.BUSY
    Db.shared.remove 'player', player, 'selection'
  
  Db.shared.set 'player', czar, 'state', PLAYER_STATE.IDLE

exports.wakeCzar = ->
  czar = Db.shared.peek 'czar'
  Db.shared.set 'player', czar, 'state', PLAYER_STATE.BUSY
  
  Db.shared.set 'phase', ROUND_PHASE.CZAR
  
  Event.create
    lowPrio: 'all',
    normalPrio: czar,
    text: 'Card Czar, your turn to pick the winning combination!'

exports.endRound = ->
  players = Db.shared.ref 'player'
  
  czar = Db.shared.peek 'czar'
  winner = players.peek czar, 'selection'
  players.incr winner, 'points'
  
  round = Db.shared.peek 'round'
  blackCard = Db.shared.peek 'blackCard'
  draw = +Packs.cardInfo(blackCard).draw + 1
  responses = {}
  
  for player, {selection} of players.peek()
    if +player isnt czar
      # Register response
      responses[player] = {selection}
      
      players.modify player, 'cards', (cards) ->
        # Remove played cards
        for card of selection
          i = cards.indexOf +card
          cards.splice(i, 1)
        
        # Draw cards
        cards.concat(exports.drawCards 'white', draw)
  
  # Register round data
  roundData = {czar, winner, blackCard, responses}
  Db.shared.set 'rounds', round, roundData
  
  # Send notification, add log message
  Comments.post
    # Log message
    s: 'round'
    u: czar
    winner: winner
    
    # Notification
    
    # TODO this creates a permanent grey bubble for that
    # rounds page, which is quite annoying as you then
    # have to click 3 times to go to that page
    path: ['rounds', round]
    pushText: App.userName(winner) + ' won the round!'
  
  # Show result to players
  players.set czar, 'state', PLAYER_STATE.IDLE
  Timer.set 5e3, 'client_nextRound'

exports.endGame = ->
  # TODO

exports.drawCards = (color, number = 1) ->
  drawnCards = []
  Db.shared.modify 'cards', color, (cards) ->
    drawnCards = cards.splice(0, number)
    cards
  drawnCards
