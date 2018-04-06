constants =
  APP_STATE:
    CREATE: 'create'
    GAME: 'game'

  ROUND_PHASE:
    PLAYER: 0
    CZAR: 1

  PLAYER_STATE:
    IDLE: 0
    BUSY: 1

exports.APP_STATE = constants.APP_STATE
exports.ROUND_PHASE = constants.ROUND_PHASE
exports.PLAYER_STATE = constants.PLAYER_STATE

# Magic trickery to escape the sandbox
exports.get = ->
  enums = {}
  for name, values of constants
    enums[name] = values
  enums
