exports.toObject = (array) -> array.reduce((object, value, index) ->
  object[index] = value
  object
, {})

exports.shuffle = (source) ->
  return source unless source.length >= 2
  for index in [source.length-1..1]
    randomIndex = Math.floor Math.random() * (index + 1)
    [source[index], source[randomIndex]] = [source[randomIndex], source[index]]
  source

exports.unique = (array) ->
  output = {}
  output[array[key]] = array[key] for key in [0...array.length]
  value for key, value of output

exports.values = (object) -> (value for own prop, value of object)

exports.swap = (object) ->
  result = {}
  for own prop, value of object
    result[value] = prop
  result
