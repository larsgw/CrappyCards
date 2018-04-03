{APP_STATE, ROUND_PHASE, PLAYER_STATE} = Enums.get()

exports.onInstall = ->
  Db.shared.set 'state', APP_STATE.CREATE
  Db.shared.set 'players', [App.ownerId()]
  Db.shared.set 'packs', [2]

exports.onUpgrade = ->
#   do Game.wakeCzar
#   do Game.initGame

exports.client_setPlayers = (ids) ->
  Db.shared.set 'players', ids

exports.client_setPacks = (ids) ->
  Db.shared.set 'packs', ids

exports.client_startGame = ->
  do Game.initGame
  Db.shared.set 'state', APP_STATE.GAME

exports.client_resetGame = ->
  do Game.initGame
  Db.shared.set 'state', APP_STATE.CREATE

exports.client_nextRound = ->
  log 'next round'
  do Game.initRound

exports.client_skip = ->
  log 'skip'
  if Db.shared.peek('phase') is ROUND_PHASE.PLAYER
    do Game.wakeCzar
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
  Db.shared.set 'player', player, 'state', PLAYER_STATE.IDLE
  
  if Util.values(Db.shared.peek 'player').every(({state}) ->
    state is PLAYER_STATE.IDLE)
    do Game.wakeCzar

# Czar

exports.client_pickCzar = (player) ->
  czar = Db.shared.peek 'czar'
  Db.shared.set 'player', czar, 'selection', player

# exports.client_unpickCzar = () ->
#   czar = Db.shared.peek 'czar'
#   Db.shared.remove 'player', czar, 'selection'

exports.client_playCzar = () ->
  do Game.endRound

# Debug

exports.client_log = (msg) -> log msg; 0
