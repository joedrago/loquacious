# ----------------------------------------------------------------------------------

fs      = require 'fs'
esprima = require 'esprima'

# ----------------------------------------------------------------------------------

class Loquacious
  constructor: (@inputFilename) ->

  findExprs: (list, lineNo) ->
    exprs = []
    for expr in list
      if expr.loc.start.line == lineNo
        exprs.push expr
      if expr.type == 'FunctionDeclaration'
        exprs = exprs.concat @findExprs(expr.body.body, lineNo)
      if expr.type == 'ExpressionStatement'
        exprs = exprs.concat @findExprs([expr.expression], lineNo)
      if expr.type == 'CallExpression'
        exprs = exprs.concat @findExprs(expr.arguments, lineNo)
      if expr.type == 'FunctionExpression'
        exprs = exprs.concat @findExprs(expr.params, lineNo)
        exprs = exprs.concat @findExprs([expr.body], lineNo)
      if expr.type == 'BlockStatement'
        exprs = exprs.concat @findExprs(expr.body, lineNo)
      if expr.type == 'IfStatement'
        exprs = exprs.concat @findExprs([expr.test], lineNo)
        exprs = exprs.concat @findExprs([expr.consequent], lineNo)
    return exprs

  explainExpr: (expr) ->
    switch expr.type
      when 'ExpressionStatement', 'Identifier', 'Literal', 'FunctionExpression', 'BlockStatement', 'MemberExpression', 'UnaryExpression', 'BinaryExpression', 'NewExpression'
        []
      when 'AssignmentExpression'
        ["Assign some stuff."]
      when 'CallExpression'
        ["Call a function."]
      when 'IfStatement'
        ["Check a value."]
      when 'ReturnStatement'
        ["Return a value."]
      when 'FunctionDeclaration'
        ["Declare the function #{expr.id.name}()."]
      when 'VariableDeclaration'
        if expr.declarations.length > 1
          names = []
          for decl in expr.declarations
            names.push decl.id.name
          names = names.join(", ")
          ["Declare some variables: #{names}"]
        else
          name = expr.declarations[0].id.name
          ["Declare the variable '#{name}'."]
      else ["lel #{expr.type}"]

  getIndent: (line) ->
    matches = line.match(/^(\s*)/)
    if matches
      return matches[1]
    return ""

  findComments: (list, lineNo) ->
    comments = []
    for comment in list
      if comment.loc.start.line == lineNo
        comments.push comment
    return comments

  parse: ->
    @inputJS = String(fs.readFileSync(@inputFilename))
    @inputLines = @inputJS.split(/\r\n|\n|\r/)
    ast = esprima.parse(@inputJS, { loc: true, comment: true })
    if (ast == null) or (ast.body.length < 1)
      return false

    # debugging
    # console.log JSON.stringify(ast, null, 2)

    @output = ""

    lineNo = 0
    for line in @inputLines
      lineNo++
      outputLine = ""
      indent = @getIndent(line)

      exprs = @findExprs(ast.body, lineNo)
      for expr in exprs
        explains = @explainExpr(expr)
        for explain in explains
          outputLine += indent + "// "
          outputLine += @explainExpr(expr) + "\n"

      comments = @findComments(ast.comments, lineNo)
      for comment in comments
        indentText = ''
        for i in [0...comment.loc.start.column]
          indentText += ' '
        outputLine += indentText + "// This is a pretty sweet comment.\n"
        outputLine += indentText + "// |\n"
        outputLine += indentText + "// \\/\n"

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
