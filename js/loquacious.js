// Generated by CoffeeScript 1.8.0
(function() {
  var Loquacious, esprima, fs, log, main, syntax, verboseMode;

  fs = require('fs');

  esprima = require('esprima');

  Loquacious = (function() {
    function Loquacious(inputFilename) {
      this.inputFilename = inputFilename;
    }

    Loquacious.prototype.findExprs = function(list, lineNo) {
      var expr, exprs, _i, _len;
      exprs = [];
      for (_i = 0, _len = list.length; _i < _len; _i++) {
        expr = list[_i];
        if (expr.loc.start.line === lineNo) {
          exprs.push(expr);
        }
        if (expr.type === 'FunctionDeclaration') {
          exprs = exprs.concat(this.findExprs(expr.body.body, lineNo));
        }
        if (expr.type === 'ExpressionStatement') {
          exprs = exprs.concat(this.findExprs([expr.expression], lineNo));
        }
        if (expr.type === 'CallExpression') {
          exprs = exprs.concat(this.findExprs(expr["arguments"], lineNo));
        }
        if (expr.type === 'FunctionExpression') {
          exprs = exprs.concat(this.findExprs(expr.params, lineNo));
          exprs = exprs.concat(this.findExprs([expr.body], lineNo));
        }
        if (expr.type === 'BlockStatement') {
          exprs = exprs.concat(this.findExprs(expr.body, lineNo));
        }
        if (expr.type === 'IfStatement') {
          exprs = exprs.concat(this.findExprs([expr.test], lineNo));
          exprs = exprs.concat(this.findExprs([expr.consequent], lineNo));
        }
      }
      return exprs;
    };

    Loquacious.prototype.explainExpr = function(expr) {
      var decl, name, names, _i, _len, _ref;
      switch (expr.type) {
        case 'ExpressionStatement':
        case 'Identifier':
        case 'Literal':
        case 'FunctionExpression':
        case 'BlockStatement':
        case 'MemberExpression':
        case 'UnaryExpression':
        case 'BinaryExpression':
        case 'NewExpression':
          return [];
        case 'AssignmentExpression':
          return ["Assign some stuff."];
        case 'CallExpression':
          return ["Call a function."];
        case 'IfStatement':
          return ["Check a value."];
        case 'ReturnStatement':
          return ["Return a value."];
        case 'FunctionDeclaration':
          return ["Declare the function " + expr.id.name + "()."];
        case 'VariableDeclaration':
          if (expr.declarations.length > 1) {
            names = [];
            _ref = expr.declarations;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              decl = _ref[_i];
              names.push(decl.id.name);
            }
            names = names.join(", ");
            return ["Declare some variables: " + names];
          } else {
            name = expr.declarations[0].id.name;
            return ["Declare the variable '" + name + "'."];
          }
          break;
        default:
          return ["lel " + expr.type];
      }
    };

    Loquacious.prototype.getIndent = function(line) {
      var matches;
      matches = line.match(/^(\s*)/);
      if (matches) {
        return matches[1];
      }
      return "";
    };

    Loquacious.prototype.findComments = function(list, lineNo) {
      var comment, comments, _i, _len;
      comments = [];
      for (_i = 0, _len = list.length; _i < _len; _i++) {
        comment = list[_i];
        if (comment.loc.start.line === lineNo) {
          comments.push(comment);
        }
      }
      return comments;
    };

    Loquacious.prototype.parse = function() {
      var ast, comment, comments, explain, explains, expr, exprs, i, indent, indentText, line, lineNo, outputLine, _i, _j, _k, _l, _len, _len1, _len2, _len3, _m, _ref, _ref1;
      this.inputJS = String(fs.readFileSync(this.inputFilename));
      this.inputLines = this.inputJS.split(/\r\n|\n|\r/);
      ast = esprima.parse(this.inputJS, {
        loc: true,
        comment: true
      });
      if ((ast === null) || (ast.body.length < 1)) {
        return false;
      }
      this.output = "";
      lineNo = 0;
      _ref = this.inputLines;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        line = _ref[_i];
        lineNo++;
        outputLine = "";
        indent = this.getIndent(line);
        exprs = this.findExprs(ast.body, lineNo);
        for (_j = 0, _len1 = exprs.length; _j < _len1; _j++) {
          expr = exprs[_j];
          explains = this.explainExpr(expr);
          for (_k = 0, _len2 = explains.length; _k < _len2; _k++) {
            explain = explains[_k];
            outputLine += indent + "// ";
            outputLine += this.explainExpr(expr) + "\n";
          }
        }
        comments = this.findComments(ast.comments, lineNo);
        for (_l = 0, _len3 = comments.length; _l < _len3; _l++) {
          comment = comments[_l];
          indentText = '';
          for (i = _m = 0, _ref1 = comment.loc.start.column; 0 <= _ref1 ? _m < _ref1 : _m > _ref1; i = 0 <= _ref1 ? ++_m : --_m) {
            indentText += ' ';
          }
          outputLine += indentText + "// This is a pretty sweet comment.\n";
          outputLine += indentText + "// |\n";
          outputLine += indentText + "// \\/\n";
        }
        outputLine += line + "\n";
        this.output += outputLine;
      }
      return true;
    };

    return Loquacious;

  })();

  syntax = function() {
    console.error("Syntax: loquacious [-v] inputFilename.js outputFilename.js\n");
    console.error("        -h,--help         This help output");
    console.error("        -v,--verbose      Verbose output");
    return process.exit(1);
  };

  verboseMode = false;

  log = {
    verbose: function(text) {
      if (verboseMode) {
        return console.log(text);
      }
    },
    error: function(text) {
      return console.error("ERROR: " + text);
    }
  };

  main = function() {
    var args, inputFilename, loq, outputFilename, which;
    args = require('minimist')(process.argv.slice(2), {
      boolean: ['h', 'v'],
      alias: {
        help: 'h',
        verbose: 'v'
      }
    });
    if (args.help || args._.length < 2 || args._.length > 3) {
      syntax();
    }
    which = null;
    inputFilename = args._[0];
    outputFilename = args._[1];
    verboseMode = args.v;
    loq = new Loquacious(inputFilename);
    loq.parse();
    return console.log(loq.output);
  };

  module.exports = {
    main: main
  };

}).call(this);
