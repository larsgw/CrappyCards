{APP_STATE, ROUND_PHASE, PLAYER_STATE} = Enums

exports.render = ->
  state = Db.shared.get 'state'
  
  # Routing
  
  if state is APP_STATE.CREATE
    if Page.state.get(0) is 'config'
      if not App.userIsAdmin App.userId()
        Ui.emptyText 'Only available for admins'
      else if Page.state.get(1) is 'players'
        do r_config_players
      else if Page.state.get(1) is 'packs'
        do r_config_packs
      else
        do r_config
    else
      if App.userIsAdmin App.userId()
        Ui.button 'Create a game', -> Page.nav ['config']
      else
        Ui.emptyText 'Waiting for admin to start the game'

  else if state is APP_STATE.GAME
    if Page.state.get(0) is 'players'
      do r_players
    else if Page.state.get(0) is 'rounds'
      do r_rounds
    else if Page.state.get(0) is 'config'
      Page.nav ['_settings']
    else
      do r_game

  if Page.state.get(0) is undefined
    Comments.enable
      messages:
        round: (c) -> App.userName(c.winner) + ' won the round!'
        game: (c) -> App.userName(c.winner) + ' won the game!'

r_game = ->
  Page.setActions [
    icon: 'history'
    label: 'Rankings'
    action: -> Page.nav ['players']
  ]
  
  # Rendering helpers
  renderNumber = (number) ->
    Dom.span ->
      Dom.addClass 'number'
      Dom.text number
  
  renderCardContents = (card, ordinal) -> ->
    {packs: [pack], text, draw, pick, watermark} = Packs.cardInfo card
    
    # Text
    Dom.p -> Dom.userText text, {emoji: false}
    
    Dom.div ->
      Dom.addClass 'footer'
      
      # Watermark
      Dom.span ->
        Dom.addClass 'watermark'
        
        {watermark, name} = Packs.packInfo pack
        
        Dom.text watermark
        Dom.onTap -> Modal.show watermark, name, ['ok', 'Ok']
      
      # Number
      if draw? and pick?
        renderNumber(pick)
      else if ordinal?
        renderNumber(ordinal)
  
  renderCard = (color, contents, onTap) ->
    Dom.div ->
      Dom.addClass 'card'
      Dom.addClass color
      
      do contents
      
      if onTap?
        Dom.onTap onTap
  
  # Rendering logic
  Dom.div ->
    Dom.css Css.game()
    Dom.addClass 'table'
    
    players = Db.shared.get 'players'
    czar = Db.shared.get 'czar'
    user = App.userId()
    
    isPlayer = players.includes user
    isCzar = user is czar
    
    # Common area:
    #   * black card
    #   * submit buttons

    Dom.div ->
      Dom.addClass 'common'
      Dom.addClass 'cards'
      
      blackCard = Db.shared.get('blackCard')
      renderCard 'black', renderCardContents blackCard
      
      renderCard 'white', ->
        userState = Db.shared.get 'player', user, 'state'
        
        showButton = false
        if userState is PLAYER_STATE.BUSY
          if isCzar and Db.shared.get('player', user, 'selection')?
            showButton = true
          else if isPlayer
            {pick} = Packs.cardInfo(blackCard)
            picked = Db.shared.count('player', user, 'selection').get()
            showButton = +picked is +pick
        
        if showButton
          Ui.button 'Confirm', -> Server.call 'play', user
        else if userState is PLAYER_STATE.BUSY
          Dom.p -> Ui.emptyText 'Your turn'
        else if isPlayer
          Dom.p -> Ui.emptyText 'Waiting...'
        
        Dom.div ->
          Dom.addClass 'footer'
          Dom.style {textAlign: 'center', textTransform: 'uppercase'}
          Dom.text if isCzar then 'Czar' else if isPlayer then 'Player' else 'Spectator'
    
    Dom.div -> Dom.addClass 'sep'
    
    # Player hand
    #   * When playing, if player cards, else nothing
    #   * Overlay for Card Czar
    #   * Played cards when selecting
    
    Dom.div ->
      Dom.addClass 'hand'
      Dom.addClass 'cards'
      
      phase = Db.shared.get 'phase'
      
      # Card picking phase (players)
      if phase is ROUND_PHASE.PLAYER
        if isCzar
          Ui.emptyText 'Card Czar'
        else if isPlayer
          cards = Db.shared.get 'player', user, 'cards'
          cards.forEach (card) ->
            ordinal = Db.shared.get 'player', user, 'selection', card
            cardType = if ordinal? then 'selected' else 'white'
            onTap = null
            
            if Db.shared.get('player', user, 'state') is PLAYER_STATE.BUSY
              action = if ordinal? then 'unpickCard' else 'pickCard'
              onTap = -> Server.call action, user, card
            
            renderCard cardType, renderCardContents(card, ordinal), onTap
        else
          Ui.emptyText 'Waiting for players to play cards...'
      
      # Card selecting phase (czar)
      else if phase is ROUND_PHASE.CZAR
        Db.shared.iterate 'player', (playerData) ->
          player = +playerData.key()
          
          if player isnt czar
            Dom.div ->
              Dom.addClass 'group'
              czarState = Db.shared.get 'player', czar, 'state'
              
              cardType = 'white'
              onTap = null
              
              if isCzar or czarState is PLAYER_STATE.IDLE
                selected = player is Db.shared.get 'player', czar, 'selection'
                cardType = if selected then 'selected' else 'white'
              if isCzar and czarState is PLAYER_STATE.BUSY
                action = if selected then 'unpickCzar' else 'pickCzar'
                onTap = -> Server.call action, player
              
              playerData.iterate 'selection', (ordinal) ->
                card = ordinal.key()
                renderCard cardType, renderCardContents(card, ordinal.get()), onTap
              , (ordinal) -> +ordinal.get()
    
    Dom.div -> Dom.addClass 'sep'
    
    # Admin tools:
    #   * Skip (to Czar or to next round)
    #   * Next round
    # Info:
    #   * About (Git README)
    #   * License (cards, mainly)

    Dom.div ->
      Dom.addClass 'print'
      
      if App.userIsAdmin user
        Dom.a ->
          Dom.text 'skip phase'
          Dom.onTap -> Server.call 'skip'
        Dom.a ->
          Dom.text 'next round'
          Dom.onTap -> Server.call 'nextRound'
      
      Dom.a ->
        Dom.text 'about'
        Dom.onTap -> App.openUrl 'https://github.com/larsgw/CrappyCards/blob/master/README.md'
      Dom.a ->
        Dom.text 'license'
        Dom.onTap -> App.openUrl 'https://github.com/larsgw/CrappyCards/blob/master/LICENSE.md'

r_round = (query) ->
  roundData = Db.shared.ref 'rounds', query
  
  if not roundData?
    Page.nav ['rounds']
    return
  
  Page.setTitle 'Round ' + query
  
  {czar, winner, blackCard} = roundData.peek()
  {text} = Packs.cardInfo blackCard
  
  Dom.css h2: marginTop: 30
  
  # Black card
  Dom.div ->
    Dom.style
      padding: '30px'
      background: 'black'
      color: 'white'
    Dom.userText text
  
  # Czar
  Dom.h2 'Czar'
  
  Ui.item
    avatar: App.userAvatar czar
    content: App.userName czar
    sub: 'Card Czar'
  
  # Reponses
  Dom.h2 'Responses'
  
  roundData.iterate 'responses', (response) ->
    player = +response.key()
    
    Ui.item
      avatar: App.userAvatar player
      content: ->
        response.iterate 'selection', (card) ->
          {text} = Packs.cardInfo card.key()
          Dom.p -> Dom.userText '"' + text + '"'
        , (card) -> +card.peek()
      sub: ->
        Dom.span App.userName(player) + if player is winner then ' (winner)' else ''
        
        Dom.span ->
          Dom.style {float: 'right'}
          
          Comments.renderLike
            store: ['rounds', query, 'responses', player, 'likes']
            userId: player
            size: 16
            aboutWhat: "cards"
            noExpand: true
  , (player) -> if +player.key() is winner then -1 else 0

r_rounds = ->
  Page.setTitle 'Round history'
  
  query = Page.state.get(1)
  if query?
    return r_round query
  
  if Db.shared.count('rounds').get() is 0
    Ui.emptyText 'No rounds finished yet!'
  
  Db.shared.iterate 'rounds', (roundData) ->
    round = roundData.key()
    {czar, winner} = roundData.get()
    
    Ui.item
      avatar: App.userAvatar winner
      onTap: -> Page.nav ['rounds', round]
      
      prefix: ->
        Dom.span ->
          Dom.style {margin: '0 16px'}
          Dom.text '#' + round
      content: App.userName(czar) + ' chose ' + App.userName(winner) + '\'s response'
    
  , (round) -> -round.key()

r_players = ->
  Page.setTitle 'Rankings'
  
  czar = Db.shared.get('czar')
  
  Db.shared.iterate 'player', (player) ->
    id = +player.key()
    {points, state} = player.get()
    fontWeight = if App.userId() is id then 'bold' else 'normal'
    
    Ui.item
      avatar: App.userAvatar(id)
      sub: if id is czar then 'Card Czar' else if state is PLAYER_STATE.BUSY then 'Selecting' else undefined
      onTap: -> App.userInfo(id)
      
      prefix: ->
        Dom.span ->
          Dom.style {margin: '0 16px', fontWeight}
          Dom.text points + ' pts'
      content: ->
        Dom.style {fontWeight}
        Dom.text App.userName(id)
  
  Dom.div -> Dom.style height: '20px'
  
  Ui.button 'View rounds history', -> Page.nav ['rounds']

exports.renderSettings = ->
  if Db.shared.get('state') is APP_STATE.CREATE
    Ui.button 'Set up the game', -> Page.nav ['config']
  else
    Ui.button 'Reset', ->
      Server.call 'resetGame'
      Page.nav ['config']

r_config = ->
  Page.setTitle 'Create a new game'
  
  # Players
  players = Db.shared.get 'players'
  
  Dom.section ->
    if players.length is 0
      Ui.emptyText 'No players selected'
    else
      players.forEach (player) ->
        Ui.item
          avatar: App.userAvatar(player)
          content: App.userName(player)
          onTap: -> App.userInfo(player)

    Ui.item
      content: -> Ui.button 'Change', -> Page.nav ['config', 'players']
  
  # Packs
  packs = Db.shared.get 'packs'
  
  Dom.section ->
    if packs.length is 0
      Ui.emptyText 'No packs selected'
    else
      packs.forEach (pack) ->
        {name, watermark} = Packs.packInfo pack
        Ui.item
          prefix: ->
            Dom.span ->
              Dom.style
                margin: '0 8px 0 0'
                padding: '4px 8px'
                fontFamily: 'monospace'
                fontWeight: 'bold'
                border: '1px solid'
                borderRadius: '4px'
              Dom.text watermark
          content: name

    Ui.item
      content: -> Ui.button 'Change', -> Page.nav ['config', 'packs']
  
  Ui.bigButton 'Start game', ->
    Server.call 'startGame'
    Page.nav []

r_config_players = ->
  Page.setTitle 'Add players'
  
  players = Db.shared.get 'players'
  people = Object.keys(App.users.get()).map((player) -> [+player, null])
  
  if people.length is 0
    Ui.emptyText 'No more players available'
  else
    people.forEach ([player], index) ->
      Ui.item
        avatar: App.userAvatar(player)
        content: App.userName(player)
        onTap: -> App.userInfo(player)
        prefix: ->
          Dom.div ->
            Dom.style margin: '0 16px'
            people[index][1] = Form.check {}
            
            if player in players
              people[index][1].prop 'checked', true
    
    Ui.button 'Change', ->
      newPlayers = people.filter(([_, check]) -> check.prop 'checked').map(([player]) -> player)
      Server.call 'setPlayers', newPlayers
      Page.nav ['config']
  
  Ui.button 'Cancel', ->
    Page.nav ['config']

r_config_packs = ->
  Page.setTitle 'Add packs'
  
  packs = Db.shared.get 'packs'
  otherPacks = Packs.listPacks().map((pack) -> [pack, null])
  
  if otherPacks.length is 0
    Ui.emptyText 'No more packs available'
  else
    otherPacks.forEach ([pack], index) ->
      {name, watermark} = Packs.packInfo pack
      Ui.item
        content: name
        prefix: ->
          Dom.div ->
            Dom.style margin: '0 16px'
            otherPacks[index][1] = Form.check {}
            
            if pack in packs
              otherPacks[index][1].prop 'checked', true
          
          Dom.span ->
            Dom.style
              margin: '0 8px'
              padding: '4px 8px'
              fontFamily: 'monospace'
              fontWeight: 'bold'
              border: '1px solid'
              borderRadius: '4px'
            Dom.text watermark
    
    Ui.button 'Change', ->
      newPacks = otherPacks.filter(([_, check]) -> check.prop 'checked').map(([pack]) -> pack)
      Server.call 'setPacks', newPacks
      Page.nav ['config']

  Ui.button 'Cancel', ->
    Page.nav ['config']
