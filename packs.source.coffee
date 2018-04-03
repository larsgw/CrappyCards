# BEGIN DATA

# END DATA

exports.packInfo = (id) -> packs[id]

exports.cardInfo = (id) -> blackCards[id] or whiteCards[id]

exports.listPacks = -> Object.keys(packs).map((pack) -> +pack)

# OLD: watermark, etc.
# 
# watermarkedCardInfo = (pack, cardMap) -> (card) ->
#   info = cardMap[card]
#   info.pack = pack
#   info
# 
# getCards = (fromPacks, packMap, cardMap) ->
#   # TODO unique?
#   decks = fromPacks.map((pack) -> packMap[pack].map(watermarkedCardInfo(pack, cardMap)))
#   deck = [].concat(decks...)
#   Util.shuffle(deck)
# 
# exports.getBlackCards = (fromPacks) -> getCards(fromPacks, blackCardPacks, blackCards)
# exports.getWhiteCards = (fromPacks) -> getCards(fromPacks, whiteCardPacks, whiteCards)

getCards = (fromPacks, type) ->
  decks = fromPacks.map((pack) -> packs[pack].cards[type])
  deck = [].concat(decks...)
  Util.shuffle(Util.unique(deck))

exports.getBlackCards = (fromPacks) -> getCards(fromPacks, 'black')
exports.getWhiteCards = (fromPacks) -> getCards(fromPacks, 'white')
