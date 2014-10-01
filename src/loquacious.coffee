# ----------------------------------------------------------------------------------

fs      = require 'fs'
esprima = require 'esprima'

# ----------------------------------------------------------------------------------

class Loquacious
  constructor: (@inputFilename) ->

  findExprs: (ast, lineNo) ->
    exprs = []
    for expr in ast.body
      if expr.loc.start.line == lineNo
        exprs.push expr
      if expr.type == 'FunctionDeclaration'
        exprs = exprs.concat @findExprs(expr.body, lineNo)
    return exprs

  explainExpr: (expr) ->
    return "lel #{expr.type}"

  getIndent: (line) ->
    matches = line.match(/^(\s*)/)
    if matches
      return matches[1]
    return ""

  parse: ->
    @inputJS = String(fs.readFileSync(@inputFilename))
    @inputLines = @inputJS.split(/\r\n|\n|\r/)
    ast = esprima.parse(@inputJS, { loc: true })
    if (ast == null) or (ast.body.length < 1)
      return false

    # debugging
    # console.log JSON.stringify(ast, null, 2)

    @output = ""

    lineNo = 0
    for line in @inputLines
      lineNo++
      exprs = @findExprs(ast, lineNo)
      indent = @getIndent(line)
      outputLine = ""
      for expr in exprs
        outputLine += indent + "// "
        outputLine += @explainExpr(expr) + "\n"
      outputLine += line + "\n"

      @output += outputLine

    return true

# ----------------------------------------------------------------------------------

syntax = ->
  console.error "Syntax: loquacious [-v] inputFilename.js outputFilename.js\n"
  console.error "        -h,--help         This help output"
  console.error "        -v,--verbose      Verbose output"
  process.exit(1)

verboseMode = false

log =
  verbose: (text) ->
    if verboseMode
      console.log text
  error: (text) ->
    console.error "ERROR: " + text

main = ->
  args = require('minimist')(process.argv.slice(2), {
    boolean: ['h', 'v']
    alias:
      help: 'h'
      verbose: 'v'
  })
  if args.help or args._.length < 2 or args._.length > 3
    syntax()

  which = null
  inputFilename = args._[0]
  outputFilename = args._[1]
  verboseMode = args.v

  loq = new Loquacious(inputFilename)
  loq.parse()
  # TODO: write to outputFile
  console.log loq.output

# ----------------------------------------------------------------------------------

module.exports =
  main: main
