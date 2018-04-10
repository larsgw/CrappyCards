exports.game = () ->
  height = Page.height()
  
  # Responsive styling
  cardHeight = (height - 69) / 2
  cardWidth = cardHeight * (5 / 7)
  cardPadding = cardWidth * 0.1
  cardFontSize = cardHeight * 0.075
  
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
  
  '.cards .group':
    display: 'flex'
    flex: '0'
    padding: "#{cardPadding * 0.25}px"
    borderRadius: "#{cardPadding * 0.5}px"
    border: '2px solid'
  '.hand.cards > div, .hand.cards .group .card:not(:last-child)':
    marginRight: "#{cardPadding}px"
  '.group .card:first-child:last-child':
    margin: "#{-(cardPadding * 0.25) - 2}px"
  
  '.cards .card':
    flexShrink: 0
    display: 'flex'
    flexDirection: 'column'
    width: "#{cardWidth}px"
    padding: "#{cardPadding}px"
    fontSize: "#{cardFontSize}px"
    border: '1px solid'
    borderRadius: "#{cardPadding * 0.5}px"
  '.card.white':
    backgroundColor: 'white'
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
    paddingTop: "#{cardPadding * 0.5}px"
    marginTop: "#{cardPadding * 0.5}px"
  
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
