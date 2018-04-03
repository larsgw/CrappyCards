exports.initGame = ->
  Db.shared.set 'czar', null
  Db.shared.set 'round', 0
  
  Db.shared.set 'cards', 'black', Object Packs.getBlackCards(Db.shared.peek 'packs')
  Db.shared.set 'cards', 'white', Object Packs.getWhiteCards(Db.shared.peek 'packs')
  
  players = Db.shared.peek 'players'
  players.forEach (player) ->
    Db.shared.set 'player', player, 'points', 0
    Db.shared.set 'player', player, 'cards', exports.drawCards('white', 10)
  
  do exports.initRound

exports.initRound = ->
  players = Db.shared.peek 'players'
  czar = null
  
  Db.shared.incr 'round'
  Db.shared.set 'phase', 0
  Db.shared.modify 'czar', (id) ->
    czarIndex = players.indexOf id
    czarIndex = ++czarIndex % players.length
    czar = players[czarIndex]
  
  Db.shared.set 'blackCard', exports.drawCards('black')[0]
  
  players.forEach (player) ->
    Db.shared.set 'player', player, 'state', 1
    Db.shared.remove 'player', player, 'selection'
  
  Db.shared.set 'player', czar, 'state', 0

exports.wakeCzar = ->
  czar = Db.shared.peek 'czar'
  Db.shared.set 'player', czar, 'state', 1
  
  Db.shared.set 'phase', 1
  
  Event.create
    lowPrio: 'all',
    highPrio: czar,
    text: 'Card Czar, your turn to pick the winning combination!'

exports.endRound = ->
  czar = Db.shared.peek 'czar'
  winner = Db.shared.peek 'player', czar, 'selection'
  Db.shared.incr 'player', winner, 'points'
  
  # Register data
  round = Db.shared.peek 'round'
  blackCard = Db.shared.peek 'blackCard'
  responses = {}
  for player, data of Db.shared.peek 'player'
    responses[player] = {selection: data.selection}
  roundData = {czar, winner, blackCard, responses}
  Db.shared.set 'rounds', round, roundData
  
  # Redraw cards
  draw = +Packs.cardInfo(blackCard).draw + 1
  players = Db.shared.peek 'players'
  players.forEach (player) ->
    if player isnt czar
      # TODO remove played cards
      Db.shared.modify 'player', player, 'cards', (cards) ->
        cards.concat(exports.drawCards 'white', draw)
  
  # Send notification, add log message
  Comments.post
    # Log message
    s: 'round'
    u: winner
    winner: winner
    # Notification
    path: ['rounds', round]
    pushText: App.userName(winner) + ' won the round!'
  
  # Show result to players
  Db.shared.set 'player', czar, 'state', 0
  Timer.set 5e4, 'initRound'

exports.endGame = ->
  # TODO

exports.drawCards = (color, number = 1) ->
  drawnCards = []
  Db.shared.modify 'cards', color, (cards) ->
    drawnCards = cards.splice(0, number)
    cards
  drawnCards
