# TODO: better scrolling behaviour
{CompositeDisposable} = require 'atom'
EditorOverlay = require './editorOverlays'

# ## Result API
# `Result`s are DOM elements which represent the result of some operation. They
# can be created by something like
#
# ```coffeescript
# new ink.Result(ed, range, options)
# ```
# where `ed` is the current text editor and `range` is a line range compatible array,
# e.g. `[3, 4]`. `options` is an object with the mandatory field
# - `content`: DOM-node that will be diplayed inside of the `Result`.
#
# and the optional fields
# - `error`: Default `false`. If true, adds the `error`-style to the `Result`.
# - `type`:  Default `inline`, can also be `block`. Inline-`Result`s will be
# displayed after the end of the last line contained in `range`, whereas
# block-`Result`s will be displayed below it and span the whole width of
# the current editor.

module.exports =
class Result extends EditorOverlay
  constructor: (@editor, [start, end], opts={}) ->
    @kind = 'result'
    opts.type ?= 'inline'
    {@type} = opts
    @disposables = new CompositeDisposable
    opts.fade = not Result.removeLines @editor, start, end, @kind
    @createView opts
    @initMarker [start, end]
    @text = @getText()
    @disposables.add @editor.onDidChange (e) => @validateText e

  createView: ({error, content, fade}) ->
    @view = document.createElement 'div'
    @view.classList.add 'ink', 'result'
    switch @type
      when 'inline'
        @view.classList.add 'inline'
        @view.style.top = -@editor.getLineHeightInPixels() + 'px'
      when 'block' then @view.classList.add 'under'
    if error then @view.classList.add 'error'
    # @view.style.pointerEvents = 'auto'
    @view.addEventListener 'mousewheel', (e) ->
      e.stopPropagation()
    # clicking on it will bring the current result to the top of the stack
    @view.addEventListener 'click', =>
      @view.parentNode.parentNode.appendChild @view.parentNode

    @disposables.add atom.commands.add @view,
      'inline-results:clear': (e) => @remove()
    fade and @fadeIn()
    if content? then @view.appendChild content

  initMarker: ([start, end]) ->
    @marker = @editor.markBufferRange @lineRange(start, end),
      persistent: false
    @marker.result = @
    mark = item: @view
    switch @type
      when 'inline' then mark.type = 'overlay'
      when 'block' then mark.type = 'block'; mark.position = 'after'
    @editor.decorateMarker @marker, mark
    @disposables.add @marker.onDidChange (e) => @checkMarker e

  # Commands
  @activate: ->
    @subs = new CompositeDisposable
    @subs.add atom.commands.add 'atom-text-editor:not([mini])',
      'inline-results:clear-current': (e) => @removeCurrent e
      'inline-results:clear-all': => @removeAll()
      'inline-results:toggle': => @toggleCurrent()

  @deactivate: ->
    @subs.dispose()
