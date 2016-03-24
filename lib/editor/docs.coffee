# TODO: better scrolling behaviour
{CompositeDisposable} = require 'atom'
EditorOverlay = require './editorOverlays'

module.exports =
class InlineDoc extends EditorOverlay
  constructor: (@editor, range, content) ->
    @type = 'block'
    @disposables = new CompositeDisposable
    @createView content
    @initMarker range
    @text = @getText()
    @disposables.add @editor.onDidChange (e) => @validateText e

  createView: (content) ->
    @view = document.createElement 'div'
    @view.classList.add 'ink', 'docs', 'under'
    # @view.style.pointerEvents = 'auto'
    @view.addEventListener 'mousewheel', (e) ->
      e.stopPropagation()

    @disposables.add atom.commands.add @view,
      'inline-results:clear': (e) => @remove()
    # fade and @fadeIn()
    if content? then @view.appendChild content

  initMarker: (range) ->
    @marker = @editor.markBufferRange range,
      persistent: false
    @marker.result = @
    @editor.decorateMarker @marker,
      item: @view,
      type: 'block',
      position: 'after'
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
