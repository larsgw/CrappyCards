# BEGIN DATA

# END DATA

exports.packInfo = (id) -> packs[id]

exports.cardInfo = (id) -> blackCards[id] or whiteCards[id]

exports.listPacks = -> Object.keys(packs).map((pack) -> +pack)

getCards = (fromPacks, type) ->
  decks = fromPacks.map((pack) -> packs[pack].cards[type])
  deck = [].concat(decks...)
  Util.shuffle(Util.unique(deck))

exports.getBlackCards = (fromPacks) -> getCards(fromPacks, 'black')
exports.getWhiteCards = (fromPacks) -> getCards(fromPacks, 'white')
