exports.onInstall = ->
  Db.shared.set 'state', 'create'
  Db.shared.set 'players', [App.ownerId()]
  Db.shared.set 'packs', [2]

exports.onUpgrade = ->
#   do Cah.wakeCzar
#   do Cah.initGame

exports.client_setPlayers = (ids) ->
  Db.shared.set 'players', ids

exports.client_setPacks = (ids) ->
  Db.shared.set 'packs', ids

exports.client_startGame = ->
  do Cah.initGame
  Db.shared.set 'state', 'game'

exports.client_resetGame = ->
  do Cah.initGame
  Db.shared.set 'state', 'create'

exports.client_nextRound = ->
  log 'next round'
  do Cah.initRound

exports.client_skip = ->
  log 'skip'
  czar = Db.shared.peek 'czar'
  if Db.shared.peek('player', czar, 'state') is 0
    do Cah.wakeCzar
  else
    do exports.client_nextRound

# Players

exports.client_pickCard = (player, card) ->
  ordinals = Util.swap(Db.shared.peek('player', player, 'selection'))
  
  # Get first available card 'slot'.
  ordinal = 1
  while ordinal < +Packs.cardInfo(Db.shared.peek('blackCard')).pick
    if ordinal not of ordinals
      break
    else
      ordinal++
  
  # If none are available,
  if ordinal of ordinals
    # replace the contents of the last card 'slot' instead.
    Db.shared.remove 'player', player, 'selection', ordinals[ordinal]
  
  # Then add new values
  Db.shared.set 'player', player, 'selection', card, ordinal

exports.client_unpickCard = (player, card) ->
  Db.shared.remove 'player', player, 'selection', card

exports.client_playCards = (player) ->
  Db.shared.set 'player', player, 'state', 0
  
  if Util.values(Db.shared.peek 'player').every(({state}) -> state is 0)
    do Cah.wakeCzar

# Czar

exports.client_pickCzar = (player) ->
  czar = Db.shared.peek 'czar'
  Db.shared.set 'player', czar, 'selection', player

# exports.client_unpickCzar = () ->
#   czar = Db.shared.peek 'czar'
#   Db.shared.remove 'player', czar, 'selection'

exports.client_playCzar = () ->
  do Cah.endRound

# Debug

exports.client_log = (msg) -> log msg; 0
