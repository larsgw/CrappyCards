const fs = require('fs')
const https = require('https')
const readline = require('readline')

const cardsUrl = 'https://cdn.rawgit.com/ajanata/PretendYoureXyzzy/88ab1ac64043de78c368a892b7154ee0c6d84844/cah_cards.sql'
const tables = {}
const results = {
  packs: {},
  blackCards: {},
  whiteCards: {}
}

const createWriter = (name, params) => {
  const table = tables[name] = []
  const columns = Object.entries(params)
  
  return (line) => {
    const values = line.split('\t')
    const entry = {}
    for (const [index, param] of columns) {
      entry[param] = values[index]
    }
    table.push(entry)
  }
}

let activeWriter = null

const handleTables = () => {
  for (const set of tables.card_set) {
    results.packs[set.id] = set
    results.packs[set.id].cards = {white: [], black: []}
  }
  for (const card of tables.black_cards) {
    results.blackCards[card.id] = card
    results.blackCards[card.id].packs = []
  }
  for (const card of tables.white_cards) {
    results.whiteCards[card.id] = card
    results.whiteCards[card.id].packs = []
  }
  
  for (const {card_set_id: pack, black_card_id: card} of tables.card_set_black_card) {
    results.packs[pack].cards.black.push(+card)
    results.blackCards[card].packs.push(+pack)
  }
  for (const {card_set_id: pack, white_card_id: card} of tables.card_set_white_card) {
    results.packs[pack].cards.white.push(+card)
    results.whiteCards[card].packs.push(+pack)
  }
  
  for (const packId in results.packs) {
    const pack = results.packs[packId]
    for (const cardId of pack.cards.black) {
      const card = results.blackCards[cardId]
      if (card.packs.length === 1 && pack.watermark !== card.watermark) {
        pack.watermark = card.watermark
      }
    }
    for (const cardId of pack.cards.white) {
      const card = results.whiteCards[cardId]
      if (card.packs.length === 1 && pack.watermark !== card.watermark) {
        pack.watermark = card.watermark
      }
    }
  }
}

const saveData = (data) => {
  fs.readFile('packs.source.coffee', 'utf-8', (err, file) => {
    if (err) {
      throw err
    }
    
    let dataCoffee = ''
    for (const part in data) {
      dataCoffee += part + ' = ' + JSON.stringify(data[part]) + '\n'
    }
    
    const updated = file.replace(/^(# BEGIN DATA\n)[\s\S]*?(\n# END DATA)/gim, `$1${dataCoffee}$2`)

    fs.writeFile('packs.common.coffee', updated, 'utf-8', (err) => {
      if (err) {
        throw err
      }
    })
  })
}

https.get(cardsUrl, input => {
  const lineReader = readline.createInterface({input})
  
  lineReader.on('line', line => {
    if (line.startsWith('COPY')) {
      const [, name, params] = line.match(/^COPY (.+?) \((.+?)\)/ )
      activeWriter = createWriter(name, params.split(', '))

    } else if (line.startsWith('\\.')) {
      activeWriter = null

    } else if (activeWriter !== null) {
      activeWriter(line)
    }
  })
  
  lineReader.on('close', () => {
    handleTables()
    saveData(results)
  })
})
