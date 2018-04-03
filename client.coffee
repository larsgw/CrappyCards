{decode: decodeEntities} = Entities

decode = (text) -> decodeEntities text.replace(/<\/?i>/g, '*').replace(/<br>/g, '\n')

cardCss =
  '*':
    boxSizing: 'border-box'
  
  '> *, .table': 
    position: 'absolute'
    top: 0
    left: 0
    right: 0
    bottom: 0
  
  '.table':
    display: 'flex'
    flexDirection: 'column'
  
  '.table > *':
    flex: '1 0'
    position: 'relative'
  
  '.table > .sep':
    flex: '0 0 12px'
  
  '.print':
    display: 'flex'
    justifyContent: 'space-between'
    flex: '0 0 21px'
  '.print a':
    display: 'block'
  
  '.cards':
    display: 'flex'
  '.common.cards':
    justifyContent: 'space-around'
  '.hand.cards':
    overflowX: 'scroll'
  
  '.common.cards .button':
    margin: 'auto 0'
    textAlign: 'center'
  
  '.cards .card':
    flex: '0 0'
    display: 'flex'
    flexDirection: 'column'
    border: '1px solid'
  '.card.black':
    backgroundColor: 'black'
  '.card.selected':
    backgroundColor: '#46b' # App.colors().bar
  
  '.card.black ::-webkit-scrollbar-thumb, .card.selected ::-webkit-scrollbar-thumb':
    backgroundColor: 'rgba(255, 255, 255, 0.2)'
  
  '.card p':
    flex: '1'
    minHeight: 0
    overflowY: 'auto'
  '.card.black p, .card.selected p':
    color: 'white'
  
  '.card .footer':
    borderTop: '1px solid'
    fontSize: '0.5em'
  
  '.card .watermark':
    float: 'left'
    padding: '0.25em 0.5em'
    fontFamily: 'monospace'
    fontWeight: 'bold'
    borderRadius: '0.25em'
    border: '1px solid'
  '.card.black .watermark, .card.selected .watermark':
    backgroundColor: 'white'
    borderColor: 'white'
  
  '.card .number':
    float: 'right'
    borderRadius: '50%'
    padding: '0.25em 0.55em'
    display: 'inline-block'
    fontWeight: 'bold'
    border: '1px solid'
  '.card.black .number, .card.selected .number':
    color: 'white'

exports.render = ->
  state = Db.shared.get 'state'
  
  # Routing
  
  if state is 'create'
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

  else if state is 'game'
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
  
  # Responsive styling
  cardHeight = (Page.height() - 69) / 2
  cardWidth = cardHeight * (5 / 7)
  cardPadding = cardWidth * 0.1
  cardFontSize = cardHeight * 0.075
  
  cardCss['.cards .card'].flexBasis = "#{cardWidth}px"
  cardCss['.cards .card'].fontSize = "#{cardFontSize}px"
  cardCss['.cards .card'].padding = "#{cardPadding}px"
  cardCss['.cards .card'].borderRadius = "#{cardPadding * 0.5}px"
  
  cardCss['.card .footer'].paddingTop = "#{cardPadding * 0.5}px"
  cardCss['.card .footer'].marginTop= "#{cardPadding * 0.5}px"
  
  (cardCss['.hand.cards .card'] = {}).marginRight = "#{cardPadding}px"
  
  # Rendering helpers
  renderNumber = (number) ->
    Dom.span ->
      Dom.addClass 'number'
      Dom.text number
  
  renderCardContents = (card, ordinal) -> ->
    {packs: [pack], text, draw, pick, watermark} = Packs.cardInfo card
    
    # Text
    Dom.p -> Dom.userText decode(text), {emoji: false}
    
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
    Dom.css cardCss
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
        
        if isPlayer and userState is 1
          if isCzar
            if Db.shared.get('player', user, 'selection')?
              Ui.button 'Confirm', -> Server.call 'playCzar'
          else
            {pick} = Packs.cardInfo(blackCard)
            picked = Db.shared.count('player', user, 'selection').get()
            if +picked is +pick
              Ui.button 'Confirm', -> Server.call 'playCards', user
    
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
      if phase is 0
        if isCzar
          Ui.emptyText 'Card Czar'
        else if isPlayer
          cards = Db.shared.get 'player', user, 'cards'
          cards.forEach (card) ->
            ordinal = Db.shared.get 'player', user, 'selection', card
            cardType = if ordinal? then 'selected' else 'white'
            action = if ordinal? then 'unpickCard' else 'pickCard'
            
            renderCard(cardType, renderCardContents(card, ordinal), ->
              Server.call(action, user, card))
        else
          Ui.emptyText 'Waiting for players to play cards...'
      
      # Card selecting phase (czar)
      else if phase is 1
        Db.shared.iterate 'player', (playerData) ->
          player = +playerData.key()
          
          if player isnt czar
            # TODO
#             Dom.div ->
#               Dom.addClass 'group'
            czarState = Db.shared.get 'player', czar, 'state'
            
            cardType = 'white'
            onTap = null
            
            if isCzar or czarState is 0
              selected = player is Db.shared.get 'player', czar, 'selection'
              cardType = if selected then 'selected' else 'white'
#               action = if selected then 'unpickCzar' else 'pickCzar'
#               onTap = -> Server.call action, player
              onTap = -> Server.call 'pickCzar', player
            
            playerData.iterate 'selection', (ordinal) ->
              card = ordinal.key()
              renderCard cardType, renderCardContents(card, ordinal.get()), onTap
            , (ordinal) -> +ordinal.get()
    
    Dom.div -> Dom.addClass 'sep'
    
    # Info:
    #   * License (cards, mainly)
    #   * Next round (for debugging)
    #   * Privacy (data might be collected in the feature)

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
    Dom.userText decode(text)
  
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
    selection = response.ref 'selection'
    
    if player isnt czar
      Ui.item
        avatar: App.userAvatar player
        content: ->
          selection.iterate (card) ->
            {text} = Packs.cardInfo card.key()
            Dom.p -> Dom.userText '"' + decode(text) + '"'
          , (card) -> +card.peek()
        sub: ->
          Dom.span App.userName(player) + ' (winner)'
          Dom.span ->
            Dom.style {float: 'right'}
            
            Comments.renderLike
              store: ['rounds', query, 'responses', player, 'likes']
              userId: player
              size: 16
              aboutWhat: "cards"
              noExpand: true

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
      sub: if id is czar then 'Card Czar' else if state then 'Selecting' else undefined
      onTap: -> App.userInfo(id)
      
      prefix: ->
        Dom.span ->
          Dom.style {margin: '0 16px', fontWeight}
          Dom.text points + ' pts'
      content: ->
        Dom.style {fontWeight}
        Dom.text App.userName(id)
    
  , (player) -> -player.get 'points'
  
  Dom.div -> Dom.style height: '20px'
  
  Ui.button 'View rounds history', -> Page.nav ['rounds']

exports.renderSettings = ->
  if Db.shared.get('state') is 'create'
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
